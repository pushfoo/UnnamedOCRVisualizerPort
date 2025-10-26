--[[ Wraps the command-line interface for Tesseract OCR.

See the following to learn more:
- https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html
- tesseract --help-extra output
- the comments below
]]

require("fmt")
local util = require("util")
local env = require("env")
local structures = require("structures")
local NiceArray = structures.NiceArray

local tsv = require("tsv")
local rect = require("rect")
local Rect = rect.Rect
local genericReaders = tsv.genericReaders

---@package tesseract
local tesseract = {}

-- Converted from the output of tesseract --help-extra
tesseract.PAGE_SEGMENTATION_MODE = {
    OSD_ONLY = 0,               --Orientation and script detection (OSD) only.
    AUTO_OSD = 1,               --Automatic page segmentation with OSD.
    AUTO_ONLY = 2,              --Automatic page segmentation, but no OSD, or OCR. (not implemented)
    AUTO = 3,                   --Fully automatic page segmentation, but no OSD. (Default)
    SINGLE_COLUMN = 4,          --Assume a single column of text of variable sizes.
    SINGLE_BLOCK_VERT_TEXT = 5, --Assume a single uniform block of vertically aligned text.
    SINGLE_BLOCK = 6,           --Assume a single uniform block of text.
    SINGLE_LINE = 7,            --Treat the image as a single text line.
    SINGLE_WORD = 8,            --Treat the image as a single word.
    CIRCLE_WORD = 9,            --Treat the image as a single word in a circle.
    SINGLE_CHAR = 10,           --Treat the image as a single character.
    SPARSE_TEXT = 11,           --Sparse text. Find as much text as possible in no particular order.
    SPARSE_TEXT_OSD = 12,       --Sparse text with OSD.
    RAW_LINE = 13,              -- Raw line. Treat the image as a single text line, bypassing hacks that are Tesseract-specific.
}


-- https://tesseract-ocr.github.io/tessdoc/#tesseract-with-lstm
tesseract.OCR_ENGINE_MODE = {
    TESSERACT_ONLY = 0,
    LSTM_ONKLY = 1,
    TESSERACT_LSTM_COMBINED = 2,
    DEFAULT = 3
}

--- Get a raw table of languages from Tesseract.
---Note this calls the exectuable. It does not do any
---deep inspection of folders beyond that in any way.
---
---@param executablePath string|Path? a specific optional tesseract executable.
function tesseract.getLanguages(executablePath)
    executablePath = executablePath or "tesseract"
    local cmd = executablePath .. " --list-langs"
    return env.run.linesTable(cmd, 1)
end


---@class TesseractRunner
--- Lang will be concatenated with + signs between it per the
--- -l flag's documentation. Tesseract is auto-probed yet can
--- be overriden. Page segmentation is a bit more complicated
--- and may need some automation smarts around it later.
tesseract.TesseractRunner = env.makeRunnerClass("tesseract", {
    lang=tesseract.getLanguages(), -- default to English or w/e's installed?
    page_segementation_mode = tesseract.PAGE_SEGMENTATION_MODE.AUTO,
})


-- Fast and simple psuedo-set.
local IS_RECT_ARG = {left = true, top=true, width=true, height=true}


---Generate bounding vertices by extracting the output rect data.
---@param dataString string a TSV string.
---@returns table<integer, table<string,Rect>>
local _processTesseractWordTSV = function(dataString)
    -- local rawData = readTSVAsTables(dataString)
    local rawData = genericReaders.tsv:readString(dataString)
    local columnOrder = rawData.columnOrder
    local rows = rawData.rows
    local words = NiceArray:new()
    for _, row in ipairs(rows) do
        local newRow = {}
        local rectArgs = NiceArray:new() --

        for _, name in ipairs(columnOrder) do
            local value = row[name]
            if IS_RECT_ARG[name] == true then
                rectArgs:insert(tonumber(value))
            elseif name == "text" then
                newRow[name] = value
            else
                newRow[name] = tonumber(value)
            end
        end
        newRow.rect = Rect:new(rectArgs)
        words:insert(newRow)
    end
    return words
end

tesseract.TESSERACT_OP_MODES = {
    TSV = "tsv", -- word bounds
    CHAR_BBOXES = "makebox" -- character bboxes
}

---Get either nil or the langs to use joined by +.
---@param langs string|table
---@returns table?
function tesseract.TesseractRunner.concatLangs(langs)
    local asTable = util.tableWrap.nonNil(langs)
    local joined = nil
    if asTable then
        joined = table.concat(asTable, "+")
    end
    return joined
end


--- Encapsulate failure and erroring when parts are missing.
---@param languages table<integer, string>|string? Defaults to preloaded languages.
---@return ... string?,string
function tesseract.TesseractRunner:getExecAndLangs(languages)
    ---@diagnostic disable
    local which
    if self.which == nil then
        error("NoExecutable: Can't run command without an exectuable?")
    else
        which = self.which
    end
    languages = languages or self.lang
    local useLanguages = tesseract.TesseractRunner.concatLangs(languages)
    ---@diagnostic enable
    return which, useLanguages
end

-- What the character-level bbox columns seem to mean.
local CHAR_BOX_HEADERS = {
    -- level is unclear since the doc is kinda bad
    "char", "left", "bottom", "right", "top", "level"
}

--- Try to get character boxes (incomplete)
---@param path string|Path The image file.
---@param imSize table<integer, number> How big it is.
---@param languages? table<integer, string>
---@return NiceArray<integer,table<string, string|Rect>>
function tesseract.TesseractRunner:getCharBoxes(path, imSize, languages)
    ---@diagnostic disable-next-line
    local which, useLanguages = self:getExecAndLangs(self.which, languages)
    local height = imSize[2]

    local cmdRaw = string.format(
        "%s %s - -l %s makeboxes", which, path, useLanguages)
    local glyphs = nil
    local rawTSV = env.run.readString(cmdRaw)
    if rawTSV == nil then
        return nil
    end
    local boxData = genericReaders.tsv:readTSVAsTables(rawTSV, CHAR_BOX_HEADERS)
    if boxData == nil then
        return nil
    end
    glyphs = NiceArray:new()
    for _, row in ipairs(boxData) do
        local charData = {char=row.char}
        -- Flip the y axis because chars are bottom-relative for historical reasons
        charData.rect = Rect:new{
            row[1], height - row[5],
            row[4], height - row[3]
        }
        glyphs:insert(charData)
    end

    return glyphs
end


-- Get final word bounding boxes for an image.
---By default, it uses all known langauges in the order
---available. You can pass a table of specific languages
---if you wish.
---
---@param path string|Path The image file to load.
---@param languages table Override the default language list.
function tesseract.TesseractRunner:getWords(path, languages)
    local which, useLanguages = self:getExecAndLangs(languages)
    print("o", which, useLanguages)
    local cmdRaw = string.format(
         "%s %s - -l %s tsv", which, util.escapePathSpaces(tostring(path)), useLanguages)

    local rawTSV = env.run.getOutputAfterNLines(cmdRaw)
    local bboxes = nil
    if rawTSV then
        bboxes = _processTesseractWordTSV(rawTSV)
    end
    return bboxes
end

return tesseract
--[[ Wraps the command-line interface for Tesseract OCR.

See the following to learn more:
- https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html
- tesseract --help-extra output
- the comments below
]]
require("util")
require("fmt")
require("rect")
require("env")
require("tsv")


-- Converted from the output of tesseract --help-extra
PAGE_SEGMENTATION_MODE = {
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
OCR_ENGINE_MODE = {
    TESSERACT_ONLY = 0,
    LSTM_ONKLY = 1,
    TESSERACT_LSTM_COMBINED = 2,
    DEFAULT = 3
}


--[[ Tesseract runner instance.

Lang will be concatenated with + signs between it per the
-l flag's documentation. Tesseract is auto-probed yet can
be overrided. Page segmentation is a bit more complicated
and may need some automation smarts around it later.
]]
TesseractRunner = {
    lang="eng", -- default to English
    page_segementation_mode = PAGE_SEGMENTATION_MODE.AUTO,
    tesseract = env.which("tesseract")
}

--[[ Class method which probes for the first tesseract in PATH.

Override the value directly via :new{tesseract=} if necessary.
]]
function TesseractRunner.getLanguages(executablePath)
    if executablePath == nil then executablePath = "tesseract" end
    local linesTable = env.run.linesTable(executablePath .. " --list-langs", 1)
    return linesTable
end


function TesseractRunner:new(o)
    o = super(self, o)
    if o.lang == nil then
        o.lang = TesseractRunner.getLanguages(o.tesseract)
    end
    print(o.tesseract)
    o.version = env.versionFor(o.tesseract)
    return o
end


-- Fast and simple psuedo-set.
local IS_RECT_ARG = {left = true, top=true, width=true, height=true}

--[[ Generate bounding vertices by extracting the output rect data.

]]
function processTesseractTSV(dataString)
    local rawData = readTSVAsTables(dataString)
    headers = rawData.headers
    rows = rawData.rows
    local processed = NiceTable:new()
    for _, row in ipairs(rows) do
        --[[ M]]
        local newRow = NiceTable:new()  -- The row object
        local rectArgs = NiceTable:new() --

        for i, name in ipairs(header) do
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
        processed:insert(newRow)
    end
    return processed
end


function TesseractRunner:recognize(path)
    local tesseract = self.tesseract
    print(self.lang)
    local languages = table.concat(self.lang, "+")
    local cmdRaw = string.format(
        "%s %s - -l %s tsv", self.tesseract, path, languages)
    local rawTSV = env.run.getAllOutput(cmdRaw)
    return processTesseractTSV(rawTSV)
end

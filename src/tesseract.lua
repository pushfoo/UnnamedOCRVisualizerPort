require("util")
require("fmt")
require("rect")
require("env")
require("tsv")


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
    RAW_LINE = 13,              --[[ Raw line. Treat the image as a single text line, bypassing hacks that are Tesseract-specific. ]]
}

-- https://tesseract-ocr.github.io/tessdoc/#tesseract-with-lstm
OCR_ENGINE_MODE = {
    TESSERACT_ONLY = 0,
    LSTM_ONKLY = 1,
    TESSERACT_LSTM_COMBINED = 2,
    DEFAULT = 3
}


-- https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html
TesseractRunner = {
    lang="eng", -- default to English
    page_segementation_mode = PAGE_SEGMENTATION_MODE.AUTO,
    tesseract = env.which("tesseract")
}


function TesseractRunner.getLanguages(executablePath)
    if executablePath == nil then executablePath = "tesseract" end
    local linesTable = env.run.linesTable(executablePath .. " --list-langs", 1)
    return linesTable
end


function TesseractRunner:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    print(o.tesseract)
    o.version = env.versionFor(o.tesseract)
    o.languages = TesseractRunner.getLanguages(o.tesseract)
    return o
end



IS_RECT_ARG = {left = true, top=true, width=true, height=true}


function processTesseractTSV(dataString)
    local rawData = readTSVAsTables(dataString)
    headers = rawData.headers
    rows = rawData.rows
    local processed = NiceTable:new()
    for _, row in ipairs(rows) do
        local newRow = NiceTable:new()

        local rarg = NiceTable:new()
        for i, name in ipairs(header) do
            local value = row[name]
            if IS_RECT_ARG[name] == true then
                rarg:insert(tonumber(value))
            elseif name == "text" then
                newRow[name] = value
            else
                newRow[name] = tonumber(value)
            end
        end
        local rect = Rect:new(rarg)
        newRow.rect = rect
        -- util.printTable(newRow)
        processed:insert(newRow)
    end
    -- util.printTable(processed)
    return processed
end


function TesseractRunner:recognize(path)
    local cmdRaw = string.format("tesseract %s - -l eng tsv", path)
    local rawTSV = env.run.getAllOutput(cmdRaw)
    return processTesseractTSV(rawTSV)
end

TESSERACT_BG_THREAD = [[

]]
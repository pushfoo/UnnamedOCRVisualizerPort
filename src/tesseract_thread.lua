local filename, lang, page_segementation_mode, which = ...

local TesseractRunner = require("runners.tesseract").TesseractRunner

local function report_state(s)
    love.thread.getChannel("bg"):push(s)
end
report_state({reporter="env", state="intializing"})
local tesseract = TesseractRunner:new{lang, page_segementation_mode, tesseract}
report_state({reporter=tesseract.tesseract, state="running"})
local data = tesseract:recognize(filename)
report_state({reporter=tesseract.tesseract, state="done", ["data"]=data})

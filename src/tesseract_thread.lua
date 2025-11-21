local filename, lang, page_segementation_mode, which = ...

local TesseractRunner = require("runners.tesseract").TesseractRunner

local function report_state(t)
    local s = {'tesseract'}
    for k, v in pairs(t) do
        s[k] = v
    end
    love.thread.getChannel("bg"):push(s)
end
report_state({reporter="env", state="intializing"})
local tesseract = TesseractRunner:new{lang, page_segementation_mode, which}
report_state({state="running"})
local data = tesseract:getWords(filename)
report_state({state="done", ["data"]=data})

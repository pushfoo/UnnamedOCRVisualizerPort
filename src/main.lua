-- TODO: Use the OOP-style API they added at some point?
require("fmt")
require("util")
require("rect")
require("colors")
require("args")
require("tesseract")
require("uilayers")


AppState = {
    baseTitle = "UnnamedOCRPreview",
}
NO_IMAGE = "(No image)"

function AppState:new(o)
    o = super(self, o)
    if o.tesseract == nil then
        o.tesseract = TesseractRunner:new{lang={"eng"}}
    end
    o.preview = TesseractPreview:new()
    o.currentTitleParts = {o.baseTitle}
    o:setStateTitle(NO_IMAGE)
    return o
end

function AppState:setStateTitle(parts)
    if parts == nil then
        parts = NO_IMAGE
    end
    local partsType = type(parts)
    if partsType == "string" then
        parts = {parts}
    elseif partsType ~= "table" then
        error("TypeError: expected a string or table, not a " .. partsType)
    end

    local allParts = NiceTable:new()
    allParts:insert(self.baseTitle)
    for i, part in ipairs(parts) do
        allParts:insert(part)
    end
    local joined = allParts:concat(" - ")
    self.titleParts = parts
    love.window.setTitle(joined)
end

function AppState:loadFile(maybeFileName)
    local preview = self.preview
    if maybeFileName == nil then
        love.window.showFileDialog("openfile", preview.loadImageCallback)
    elseif type(maybeFileName) == "string" then
        preview.loadFile(maybeFileName)
    end
end

state = nil

function love.load(args)
    local tesseract  = TesseractRunner:new{lang={"eng"}}
    state = AppState:new{tesseract=tesseract}
    local width, height, mode = love.window.getMode()
    mode.resizable = true
    love.window.setMode(width, height, mode)
    state:loadFile()
end


function love.draw()
    love.graphics.setColor(WHITE)
    state.preview.layers:draw()
end


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
    if o.runner == nil then
        print("no runner provided to app state?")
        o.runner = TesseractRunner:new{lang={"eng"}}
    end
    o.preview = TesseractPreview:new{runner=o.runner}
    o.currentTitleParts = {o.baseTitle}
    o.zoom = 1.0
    o.zoomScaleRate = 1.0
    o.baseTransform = love.math.newTransform()
    o.currentTransform = love.math.newTransform()
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

ZOOM_RATE = 0.1
state = nil

-- [[ Handle mouse wheel (y by default) ]]
function love.wheelmoved(x, y)
    local scaled = math.abs(y) * ZOOM_RATE
    local factor = 1.0
    if y < 0 then
        factor = factor - scaled
    elseif y > 0 then
        factor =  factor + scaled
    end
    state.currentTransform:scale(factor)
end



function love.load(args)
    -- local supported_formats = love.graphics.getTextureFormats({canvas=true})
    -- for i, fmt in pairs(supported_formats) do
    --     print(i, fmt)
    -- end
    local runner = TesseractRunner:new{lang={"eng"}}
    state = AppState:new{runner=runner}
    local width, height, mode = love.window.getMode()
    mode.resizable = true
    love.window.setMode(width, height, mode)
    state:loadFile()
end


function love.draw()
    love.graphics.setColor(WHITE)
    love.graphics.replaceTransform(state.currentTransform)
    state.preview.layers:draw()
end


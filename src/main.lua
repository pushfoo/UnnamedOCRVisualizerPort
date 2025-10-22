-- TODO: Use the OOP-style API they added at some point?
require("fmt")
require("util")
require("rect")
require("colors")
require("args")
require("tesseract")
require("uilayers")
require("structures")


NO_IMAGE = "(No image)"
AppState = {
    baseTitle = "UnnamedOCRPreview",
    noDocument = NO_IMAGE
}


function AppState:new(o)
    o = super(self, o)
    if o.runner == nil then
        print("no runner provided to app state?")
        o.runner = TesseractRunner:new{lang={"eng"}}
    end
    o.preview = TesseractPreview:new{runner=o.runner}
    o.currentTitleParts = Stack:new()
    o.titleCallback = nil
    o.zoom = 1.0
    o.zoomScaleRate = 1.0
    local newTransform = love.math.newTransform
    o.baseTransform = newTransform()
    o.currentTransform = newTransform()
    o:setStateTitle()
    return o
end



function AppState:setStateTitle(rawParts)
    local parts = NiceTable:new{self.baseTitle}
    if typechecks.is.NonEmptyArray(rawParts) then
        parts:extend(rawParts)
    else
        parts:insert(rawParts or self.noDocument)
    end
    local joined = parts:concat(" - ")
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
    elseif x == 0 then
        print("warning: got unexpected scale factorx x=0, y=0")
    else
        print("ignoring: sideways scroll x=", tostring(x))
    end
    state.currentTransform:scale(factor)
end


function love.load(args)
    local runner = TesseractRunner:new()

    state = AppState:new{runner=runner}
    local width, height, mode = love.window.getMode()
    mode.resizable = true
    love.window.setMode(width, height, mode)
    state:loadFile()
end


function love.draw()
    -- Reset colors and visual transform
    love.graphics.setColor(WHITE)
    love.graphics.replaceTransform(state.currentTransform)

    state.preview.layers:draw()
end

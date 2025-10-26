local structures = require("structures")
local tesseract  = require("tesseract")
local uilayers   = require("uilayers")
local typechecks = require("typechecks")
local colors     = require("colors")


local NO_IMAGE = "(No image)"
AppState = {
    baseTitle = "UnnamedOCRPreview",
    noDocument = NO_IMAGE
}


function AppState:new(o)
    o = structures.super(self, o)
    if o.runner == nil then
        print("no runner provided to app state?")
        ---@diagnostic disable-next-line
        o.runner = tesseract.TesseractRunner:new{lang={"eng"}}
    end
    o.preview = uilayers.TesseractPreview:new{runner=o.runner}
    o.currentTitleParts = structures.Stack:new()
    o.titleCallback = nil
    o.zoom = 1.0
    o.zoomScaleRate = 0.1
    local newTransform = love.math.newTransform
    o.baseTransform = newTransform()
    o.currentTransform = newTransform()
    o:setStateTitle()
    return o
end


---@param rawParts string|table<integer, string>?
function AppState:setStateTitle(rawParts)
    rawParts = rawParts or self.noDocument
    local parts = structures.NiceArray:new{self.baseTitle}
    local tRawPArts = type(rawParts)
    if tRawPArts == "string" then
        parts:insert(rawParts)
    elseif typechecks.is.NonEmptyArray(rawParts) then
        ---@cast rawParts table<integer, string>
        parts:extend(rawParts)
        error("TypeError: expected string or array of them, not " .. tRawPArts)
    end
    local joined = parts:concat(" - ")
    love.window.setTitle(joined)
end

---@param maybeFileName string|Path?
function AppState:loadFile(maybeFileName)
    local preview = self.preview
    if maybeFileName == nil then
        love.window.showFileDialog("openfile", preview.loadImageCallback)
    elseif type(maybeFileName) == "string" then
        preview.loadFile(maybeFileName)
    end
end

---@diagnostic disable-next-line
state = nil


-- [[ Handle mouse wheel (y by default) ]]
function love.wheelmoved(x, y)
    local scaled = math.abs(y) * (state.zoomScaleRate or 0.1)
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


function love.load(_)
    ---@diagnostic disable
    local runner = tesseract.TesseractRunner:new()
    state = AppState:new{runner=runner}
    ---@diagnostic enable

    local width, height, _ = love.window.getMode()
    love.window.setMode(width, height)
    state:loadFile()
end


function love.draw()
    -- Reset colors and visual transform
    love.graphics.setColor(colors.WHITE)
    love.graphics.replaceTransform(state.currentTransform)

    state.preview.layers:draw()
end

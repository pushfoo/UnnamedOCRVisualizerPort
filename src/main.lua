local monkeypatches = require("monkeypatches")

monkeypatches.applyPatches()

local argparse = require("argparse")
local structures = require("structures")
local tesseract  = require("tesseract")
local uilayers   = require("uilayers")
local typechecks = require("typechecks")
local colors     = require("colors")
local util       = require("util")

local NO_IMAGE = "(No image)"
AppState = {
    size={800,600},
    baseTitle = "UnnamedOCRPreview",
    noDocument = NO_IMAGE,
    zoom = 1.0,
    zoomScaleRate = 0.1,
    ---@diagnostic disable-next-line
    runner = tesseract.TesseractRunner:new()
}


function AppState:new(o)
    o = structures.super(self, o)
    o.preview = uilayers.TesseractPreview:new{runner=o.runner}
    o.titleCallback = nil
    local w, h, _ = love.window.getMode()
    o.uiCanvas = love.graphics.newCanvas(w, h)

    local newTransform = love.math.newTransform
    o.baseTransform = newTransform()
    o.currentTransform = newTransform()
    local toSet = nil
    if o.file then
        print("Initialized with filename: ", o.file)
        o.preview:loadImage(o.file)
        toSet = o.file
    end
    -- Calling with nil inits the titlebar
    o:setStateTitle(toSet)
    if type(o.size) == 'table' then
        o:setWindowSize(o.size)
    end
    return o
end


--- Set the window size while preserving mode.
---@param size table<integer, number>
function AppState:setWindowSize(size)
    local window = love.window
    local _, _, mode = window.getMode()
    ---@diagnostic disable-next-line
    return window.setMode(size[1], size[2], mode)
end


--- Set the window's title bar decoration
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


--- Attempt to load the file.
---@param maybeFileName string|Path?
function AppState:loadFile(maybeFileName)
    local preview = self.preview
    -- if maybeFileName == nil then
    --     love.window.showFileDialog("openfile", preview.loadImageCallback)
    if type(maybeFileName) ~= nil then
        preview.layers:loadFile(maybeFileName)
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



function love.load(args)
    local parsed = argparse.rawParseArgs(args)
    local nextItem = argparse.iteratorOverTokens(parsed)

    local loadFile = nil
    local i = 0
    while i ~= nil do

        local flagOrArg, iOrNil = nextItem()
        if iOrNil == nil or flagOrArg == nil then
            break
        end
        i = iOrNil

        if flagOrArg.flag then
            local expanded = flagOrArg.expanded
            if util.startsWith(expanded, '--window-size') then
                local size = argparse.parseSize(nextItem)
                if size then
                    print("Got ", expanded, size[1], size[2])

                end
            elseif expanded == '--version' then
                print("0.0.1 (provisionally)")
            else
                print("unknown??",  flagOrArg.value)
            end
        else
            if loadFile == nil then
                loadFile = flagOrArg
                print("loadFile=" .. loadFile)
            else
                print(string.format("WARNING: got a second value @ %i : %s",
                    i, flagOrArg
                ))
            end
        end

    end
    local runner = tesseract.TesseractRunner:new()
    state = AppState:new{runner=runner, file=loadFile}
end

function love.draw()
    -- Reset colors and visual transform
    love.graphics.setColor(colors.WHITE)
    love.graphics.replaceTransform(state.currentTransform)

    state.preview.layers:draw()
end

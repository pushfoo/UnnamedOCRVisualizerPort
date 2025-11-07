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

function parseDim(nextPair, name)
    local raw, i = nextPair()
    print("ppp", raw,i)
    local dim = tonumber(raw)
    if dim == nil then
        error(string.format("ParseError: failed to parse %s at index %i from '%s'",
        name, i, tostring(raw)))
    end
    return dim
end

function parseSize(nextPair)
    local width = parseDim(nextPair, 'width')
    local height = parseDim(nextPair, 'height')

    return {width, height}
    -- love.window.setMode(width, height)
end

function love.load(args)
    local parsed = argparse.rawParseArgs(args)
    local cur = 0

    local function nextItem()
        cur = cur + 1
        if cur <= #parsed then
            return parsed[cur],cur
        else
            return nil,nil
        end
    end

    local loadFile = nil
    local size = {
        width = 800,
        height = 600
    }
    local i = 0
    while i ~= nil do
        local flagOrArg, iOrNil = nextItem()
        i = iOrNil
        if iOrNil == nil or flagOrArg == nil then
            break
        elseif flagOrArg.flag then
            local expanded = flagOrArg.expanded
            if util.startsWith(expanded, '--window-size') then
                local size = parseSize(nextItem)
                if size then
                    print("Got ", expanded, size[1], size[2])
                    local window = love.window
                    local _, _, m = window.getMode()
                    window.setMode(size[1], size[2], m)
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
    ---@diagnostic disable
    local runner = tesseract.TesseractRunner:new()
    state = AppState:new{runner=runner}
    ---@diagnostic enable
    state:loadFile()
end

function love.draw()
    -- Reset colors and visual transform
    love.graphics.setColor(colors.WHITE)
    love.graphics.replaceTransform(state.currentTransform)

    state.preview.layers:draw()
end

--[[ uilayers. layers for preview of bboxes. ]]
local fmt = require("fmt")
local util = require("util")
local structures = require("structures")
local Class, NiceArray = structures.Class, structures.NiceArray
local typechecks = require("typechecks")
local rect = require("rect")

local colors = require("colors")
local imageconvert = require("imageconvert")
local tesseract = require("tesseract")
local graphics = love.graphics


local uilayers = {}
--[[ Convert a raw Tesseract TSV to {rect, color} data.

]]
local function _getWordPolygonsFromTesseractData(tsvData)
    local cells = NiceArray:new()
    local mapper = colors.ColorMapper:new()
    for i, item in ipairs(tsvData) do
        local conf = item.conf
        -- The non-box items are conf == -1
        if conf and conf >= 0 then
            local normConf = conf / 100
            local t = {
                rect = item.rect,
                color = mapper:map(normConf),
                conf = conf,
                level = item.level
            }
            cells:insert(t)
        end
    end
    return cells
end


uilayers.CheckersLayer = Class({
    ["colors"] = {colors.LIGHTER_GRAY, colors.DARKER_GRAY},
    checkerSize = 8
})


function uilayers.CheckersLayer:new(o)
    o = setmetatable(o or {}, self)
    o.__index = self
    o.totalSize = o.checkerSize * 3
    if o.texture == nil then
        o.texture = colors.makeCheckers(o.colors, o.checkerSize)
    end
    -- Fit to 1080p as a "good enough" initial allocation
    o.quad = graphics.newQuad(
        0, 0,
        1920 + o.totalSize, 1080 + o.totalSize,
        o.totalSize, o.totalSize
    )
    return o
end


function uilayers.CheckersLayer:fitToViewport(left, top, bottom, right)
    local totalSize = self.totalSize
    self.quad:setViewport(left, top, bottom, right, totalSize, totalSize)
end


-- TODO: finish zooming.
-- function uilayers.CheckersLayer:setZoom(zoomQuantity)

-- end


function uilayers.CheckersLayer:draw(size)
    local w = nil
    local h = nil
    if size == nil then
        w, h = graphics.getDimensions()
    elseif type(size) == "table" and #size == 2 then
        w = size[1]
        h = size[2]
    else
        error("TypeError: size=" .. type(size) .. ", neither nil nor a table of length 2")
    end
    self:fitToViewport(0,0,w,h)
    graphics.draw(self.texture, self.quad)
end


uilayers.ImageLayer = {}

function uilayers.ImageLayer:new(o)
    o = structures.super(self, o)
    self.quad = graphics.newQuad(0, 0, 0, 0, 0, 0)
    if o.image then
        self:setImage(self.image)
    end
    return o
end


uilayers.BBoxLayer = {}

function uilayers.BBoxLayer:new(o)
    o = structures.super(self, o)
    if o.runner == nil then
        o.runner = tesseract.TesseractRunner{}
    end
    o.cells = {}
    return o
end


function uilayers.BBoxLayer:renderBBoxes(filename)
    local tsvDataRaw = self.runner:getWords(filename)
    self.cells = _getWordPolygonsFromTesseractData(tsvDataRaw)
end


function uilayers.BBoxLayer:draw()
    if self.cells == nil then
        return
    end
    for _, cell in ipairs(self.cells) do
        local vertices = cell.rect.points
        graphics.setColor(cell.color)
        graphics.polygon("line", vertices)
    end
    graphics.setColor(colors.WHITE)
end


function uilayers.ImageLayer:setImage(image)
    local width, height = image:getPixelDimensions()
    self.quad:setViewport(0, 0, width, height, width, height)
    if self.image ~= image then
        self.image = image
    end
end


function uilayers.ImageLayer:loadImage(filename)
    local image = imageconvert.load_image(filename)
    if image then
        self:setImage(image)
    end
end


function uilayers.ImageLayer:getImageSize()
    local dimensions = nil
    local image = self.texture
    if image then dimensions = image:getDimensions() end
    return dimensions
end


function uilayers.ImageLayer:draw()
    if self.image then
        graphics.draw(self.image, self.quad)
    end
end


--[[ Table with indexing behavior. ]]
DocumentLayers = {
    __index = table
}


function DocumentLayers:new(o)
    o = structures.super(self, o)
    o.layers = NiceArray:new()
    o.byName = {}
    return o
end


function DocumentLayers:get(nameOrIndex)
    local keyType = type(nameOrIndex)
    local result = nil
    local index = nil
    if keyType == "number" then
        if typechecks.is.Integer(nameOrIndex) ~= true then
            error("ValueError: not an integer: " .. tostring(nameOrIndex))
        end
        index = nameOrIndex
    elseif keyType == "string" then
        index = self.byName[nameOrIndex]
    end
    local layerAndName = self.layers[index]
    if layerAndName then
        result = layerAndName.layer
    end
    return result
end


function DocumentLayers:add(name, layer)
    local byName = self.byName
    if byName[name] then
        error(string.format("KeyError: key \"%s\" already exists", name))
    end
    self.layers:insert({name=name, layer=layer})
    self.byName[name] = #(self.layers)
    return layer
end


function DocumentLayers:draw()
    for _, layerData in ipairs(self.layers) do
        local name = layerData.name
        local layer = layerData.layer
        if layer then
            layer:draw()
        end
    end
end


uilayers.TesseractPreview = {}


-- NOTE: currently *requires* an AppState reference
function uilayers.TesseractPreview:new(o)
    o = structures.super(self, o)
    local layers = DocumentLayers:new()
    o.layers = layers

    if o.runner == nil then
        o.runner = tesseract.TesseractRunner{lang={"eng"}}
    end

    o.checkers = layers:add("checkers", uilayers.CheckersLayer:new())
    o.image =    layers:add("image",    uilayers.ImageLayer:new())
    o.bbox =     layers:add("bbox",     uilayers.BBoxLayer:new{runner=o.runner})
    o.chars =    layers:add("chars",    uilayers.BBoxLayer:new{runner=o.runner})

    o.filename = nil
    o.loadImageCallback = function(files, filters, maybeError)
        local filesType = type(files)
        local file = nil

        if filesType == "string" then
            file = filesType
        elseif filesType == "table" and #files then
            file = files[1]
        end
        if file then
            o:loadImage(file)
        end
    end
    return o
end


function uilayers.TesseractPreview:loadImage(file)
    self.image:loadImage(file)
    self.bbox:renderBBoxes(file)
    local gotN = 0
    local cells = self.bbox.cells
    if typechecks.is.NonEmptyArray(cells) then
        gotN = #cells
    end
    self.filename = file
    local filenameAlone = util.lastMatch(file, "[^/]+")
    state:setStateTitle(filenameAlone)
    print(string.format("Got %i items", gotN))
end

return uilayers
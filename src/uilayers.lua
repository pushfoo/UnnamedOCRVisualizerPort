--[[ UI layers for preview of bboxes. ]]
require("fmt")
require("util")
require("structures")
require("typechecks")
require("rect")
require("colors")
require("tesseract")
require("imageconvert")


local graphics = love.graphics


--[[ Convert a raw Tesseract TSV to {rect, color} data.

]]
function getWordPolygonsFromTesseractData(tsvData)
    local cells = NiceTable:new()
    local mapper = ColorMapper:new()
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


UICheckersLayer = Class({
    colors = {LIGHTER_GRAY, DARKER_GRAY},
    checkerSize = 8
})


function UICheckersLayer:new(o)
    o = setmetatable(o or {}, self)
    o.__index = self
    o.totalSize = o.checkerSize * 2
    if o.texture == nil then
        o.texture = makeCheckers(o.colors, o.checkerSize)
    end
    -- Fit to 1080p as a "good enough" initial allocation
    o.quad = graphics.newQuad(
        0, 0,
        1920 + o.totalSize, 1080 + o.totalSize,
        o.totalSize, o.totalSize
    )
    return o
end


function UICheckersLayer:fitToViewport(left, top, bottom, right)
    local totalSize = self.totalSize
    self.quad:setViewport(left, top, bottom, right, totalSize, totalSize)
end

function UICheckersLayer:setZoom(zoomQuantity)

end


function UICheckersLayer:draw(size)
    local w = nil
    local h = nil
    if size == nil then
        w, h = graphics.getDimensions()
    else
        w, h = size
    end
    self:fitToViewport(0,0,w,h)
    graphics.draw(self.texture, self.quad)
end


UIImageLayer = {}

function UIImageLayer:new(o)
    o = super(self, o)
    self.quad = graphics.newQuad(0, 0, 0, 0, 0, 0)
    if o.image then
        self:setImage(self.image)
    end
    return o
end


UIBBoxLayer = {}

function UIBBoxLayer:new(o)
    o = super(self, o)
    if o.runner == nil then
        o.runner = TesseractRunner:new()
    end
    o.cells = {}
    return o
end


function UIBBoxLayer:renderBBoxes(filename)
    local tsvDataRaw = self.runner:getWords(filename)
    self.cells = getWordPolygonsFromTesseractData(tsvDataRaw)
end


function UIBBoxLayer:draw()
    if self.cells == nil then
        return
    end
    for _, cell in ipairs(self.cells) do
        local vertices = cell.rect.points
        graphics.setColor(cell.color)
        graphics.polygon("line", vertices)
    end
    graphics.setColor(WHITE)
end


function UIImageLayer:setImage(image)
    local width, height = image:getPixelDimensions()
    self.quad:setViewport(0, 0, width, height, width, height)
    if self.image ~= image then
        self.image = image
    end
end


function UIImageLayer:loadImage(filename)
    -- local image = util.external.load_image(filename)
    local image = load_image(filename)
    if image then
        self:setImage(image)
    end
end


function UIImageLayer:getImageSize()
    local dimensions = nil
    local image = self.texture
    if image then dimensions = image:getDimensions() end
    return dimensions
end


function UIImageLayer:draw()
    if self.image then
        graphics.draw(self.image, self.quad)
    end
end


--[[ Table with indexing behavior. ]]
DocumentLayers = {
    __index = table
}


function DocumentLayers:new(o)
    o = super(self, o)
    o.layers = NiceTable:new()
    o.byName = {}
    return o
end


function DocumentLayers:setBaseSize(width, height)
    --
end


function DocumentLayers:get(nameOrIndex)
    local keyType = type(nameOrIndex)
    local result = nil
    if keyType == "number" then
        if typechecks.is.Integer(nameOrIndex) ~= true then
            error("ValueError: not an integer: " .. tostring(nameOrIndex))
        end
        index = nameOrIndex
    elseif keyType == "string" then
        index = self.byName[nameOrIndex]
    end
    layerAndName = self.layers[index]
    if layerAndName then
        result = layerAndName.layer
    end
    return result
end


function DocumentLayers:add(name, layer)
    local byName = self.byName
    if byName[name] then
        error(string.format("KeyError: key %s already exists", quote(name)))
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


TesseractPreview = {}


-- NOTE: currently *requires* an AppState reference
function TesseractPreview:new(o)
    o = super(self, o)
    local layers = DocumentLayers:new()
    o.layers = layers
    if o.runner == nil then
        o.runner = TesseractRunner:new{lang={"eng"}}
    end
    o.checkers = layers:add("checkers", UICheckersLayer:new())
    o.image =    layers:add("image",    UIImageLayer:new())
    o.bbox =     layers:add("bbox",     UIBBoxLayer:new{runner=o.runner})
    o.chars =    layers:add("chars",    UIBBoxLayer:new{runner=o.runner})

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


function TesseractPreview:loadImage(file)
    self.image:loadImage(file)

    self.bbox:renderBBoxes(file)
    local gotN = 0
    local cells = self.bbox.cells
    if typechecks.is.NonEmptyArray(cells) then
        gotN = #cells
    end
    self.filename = file
    local filenameAlone = util.lastOfString(file, "[^/]+")
    state:setStateTitle(filenameAlone)
    print(string.format("Got %i items", gotN))
end

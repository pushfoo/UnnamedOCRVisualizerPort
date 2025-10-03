--[[ UI layers for preview of bboxes. ]]
require("fmt")
require("util")
require("rect")
require("colors")
require("tesseract")


function getScreenSize()
    local width, height, _ = love.window.getMode()
    return {width, height}
end


function renderAsPolygons(tsvData)
    local cells = {}
    local mapper = ColorMapper:new()
    for i, item in ipairs(tsvData) do
        local conf = item.conf
        if conf ~= nil then
            if conf >= 0 then
                local normConf = conf / 100
                local color = mapp
                local t = {
                    rect = item.rect,
                    color = mapper:map(normConf)
                }
                table.insert(cells, t)
            end
        end
    end
    return cells
end


BackgroundLayer = {
    colors = {LIGHTER_GRAY, DARKER_GRAY},
    checkerSize = 8
}

function BackgroundLayer:new(o)
    o = super(self, o)
    local checkerSize = o.checkerSize
    local colors = o.colors
    local totalSize = checkerSize * 2
    o.texture = makeCheckers(colors, checkerSize)
    o.quad = love.graphics.newQuad(
        -- top left of screen
        0, 0,
        -- bottom right + overshoot in case of weird stretchy?
        -- (may be an illusion, unclear)
        1920 + totalSize, 1080 + totalSize,
        -- texture size to repeat
        totalSize, totalSize
    )
    o.totalSize = totalSize
    return o
end


function BackgroundLayer:fitToViewport(left, top, bottom, right)
    local totalSize = self.totalSize
    self.quad:setViewport(left, top, bottom, right, totalSize, totalSize)
end


function BackgroundLayer:draw(size)
    if size == nil then size = getScreenSize() end
    local w = size[1]
    local h = size[2]
    self:fitToViewport(0,0,w,h)
    love.graphics.draw(self.texture, self.quad)
end


UIImageLayer = {}

function UIImageLayer:new(o)
    o = super(self, o)
    self.quad = love.graphics.newQuad(0, 0, 0, 0, 0, 0)
    if o.image ~= nil then
        self:setImage(self.image)
    end
    return o
end


UIBBoxLayer = {}

function UIBBoxLayer:new(o)
    o = super(self, o)
    if o.tesseract == nil then
        o.tesseract = TesseractRunner:new()
    end
    o.cells = {}
    return o
end


function UIBBoxLayer:renderBBoxes(filename)
    local tsvDataRaw = self.tesseract:recognize(filename)
    self.cells = renderAsPolygons(tsvDataRaw)
end


function UIBBoxLayer:draw()
    if self.cells == nil then
        return
    end
    for i, cell in ipairs(self.cells) do
        local vertices = cell.rect.points
        love.graphics.setColor(cell.color)
        love.graphics.polygon("line", vertices)
    end
    love.graphics.setColor(WHITE)
end


function UIImageLayer:setImage(image)
    local width, height = image:getPixelDimensions()
    self.quad:setViewport(0, 0, width, height, width, height)
    if self.image ~= image then
        self.image = image
    end
end

function UIImageLayer:loadImage(filename)
    local image = util.external.load_image(filename)
    if image ~= nil then
        self:setImage(image)
    end
end


function UIImageLayer:draw()
    if self.image ~= nil then
        love.graphics.draw(self.image, self.quad)
    end
end



DocumentLayers = {
    __index = table
}


function DocumentLayers:new(o)
    o = super(self, o)
    o.layers = NiceTable:new()
    o.byName = {}
    return o
end


function DocumentLayers:get(nameOrIndex)
    local keyType = type(nameOrIndex)
    local result = nil
    if keyType == "number" then
        if isInteger(nameOrIndex) ~= true then
            error("ValueError: not an integer: " .. tostring(nameOrIndex))
        end
        index = nameOrIndex
    elseif keyType == "string" then
        index = self.byName[nameOrIndex]
    end
    layerAndName = self.layers[index]
    if layerAndName ~= nil then
        result = layerAndName.layer
    end
    return result
end


function DocumentLayers:add(name, layer)
    local byName = self.byName
    if byName[name] ~= nil then
        error(string.format("KeyError: key %s already exists", quote(name)))
    end
    self.layers:insert({name=name, layer=layer})
    self.byName[name] = #(self.layers)
end


function DocumentLayers:draw()
    for i, layerData in ipairs(self.layers) do
        local name = layerData.name
        local layer = layerData.layer
        if layer ~= nil then
            layer:draw()
        end
    end
end


TesseractPreview = {}
-- NOTE: currently *requires* an AppState reference
function TesseractPreview:new(o)
    o = super(self, o)
    o.layers = DocumentLayers:new()
    if o.tesseract == nil then
        o.tesseract = TesseractRunner:new{lang={"eng"}}
    end
    local layers = o.layers
    layers:add("checkers", BackgroundLayer:new())
    layers:add("image", UIImageLayer:new())
    layers:add("bbox", UIBBoxLayer:new{tesseract=o.tesseract})
    o.filename = nil
    o.loadImageCallback = function(files, filters, maybeError)
        local filesType = type(files)
        local file = nil
        if filesType == "string" then
            file = filesType
        elseif filesType == "table" then
            file = files[1]
        end
        o:loadImage(file)

    end
    return o
end


function TesseractPreview:loadImage(file)
    local layers = self.layers
    local bbox = layers:get("bbox")
    bbox:renderBBoxes(file)
    local image = layers:get("image")
    image:loadImage(file)
    local gotN = 0
    local cells = bbox.cells
    if isNonEmptyArray(cells) then
        gotN = #cells
    end
    self.filename = file
    -- TODO: Fix this ugly trick
    state:setStateTitle(file)
    print(string.format("Got %i items", gotN))
end

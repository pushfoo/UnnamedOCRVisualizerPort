--[[ uilayers. layers for preview of bboxes. ]]
local fmt = require("fmt")
local util = require("util")
local structures = require("structures")
local typechecks = require("typechecks")

local colors = require("colors")
local imageconvert = require("imageconvert")
local tesseract = require("tesseract")

local graphics = love.graphics
local class = require "lib.middleclass"
local NiceArray = structures.NiceArray



-- Our submodule
local uilayers = {}


--[[ Convert a raw Tesseract TSV to {rect, color} data.

]]
local _getWordPolygonsFromTesseractData = function(tsvData)
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


local BaseTextureLayer = class('BaseTextureLayer')
uilayers.BaseTextureLayer = BaseTextureLayer


--- Get a new Quad for the given texture.
--- If onyl a texture is given, it sets the width to scaled pixel dimensions.
---@param texture love.Texture|love.Image
---@param x number?
---@param y number?
---@param width number?
---@param height number?
---@param refX number?
---@param refY number?
---@return love.Quad
local function _getQuadForImage(texture, x, y, width, height, refX, refY)
    if texture == nil then
        error("TypeError: expected a texture-like, not nil")
    end
    x = --[[@as number]] x or 0
    y = --[[@as number]] y or 0
    if width == nil or height == nil then
        local screenW, screenH = texture:getPixelDimensions()
        width  = --[[@as number]] width or screenW
        height = --[[@as number]] height or screenH
    end
    local quad = nil
    if refX == nil or refY == nil then
        quad = graphics.newQuad(x, y, width, height, texture)
    else
        quad = graphics.newQuad(x, y, width, height, refX, refY)
    end
    return quad
end


--- Set up a new texture layer.
--- NOTE: use BaseTextureLayer.initalize(self, ...) in subclasses
--- @param texture love.Texture|love.Image?
--- @param options table<string, any>?
function BaseTextureLayer:initialize(texture, options)
    options = options or {}
    self._quad = options.quad
    self._texture = texture -- What to draw into it
    -- Quad:getViewport doesn't get the reference values.
    -- Caches Texture:getViewport() + texture sX, sY values
    -- self._viewport = {0,0,0,0,0,0} -- Where to draw stuff
    if texture and self._quad == nil then
        self._quad = _getQuadForImage(texture)
    end
end


function BaseTextureLayer:getTexture()
    return self._texture
end


function BaseTextureLayer:setTexture(texture, options)
    options = options or {}
    local quad = options.quad or self._quad
    local forceRefresh = options.forceRefresh or false
    if forceRefresh or self._texture ~= texture then
        self._texture = texture
        if quad ~= self._quad then
            if quad == nil then
                quad = _getQuadForImage(texture)
            end
        else
            -- viewport return doesn't include the texture reference dims
            local x, y, w, h = quad:getViewport()
            local texW, texH = texture:getDimensions()
            quad:setViewport(x, y, w, h, texW, texH)
        end
    end
end


--- Set the viewport to {left, top, ...}.
---@param left number Leftmost edge of vieport rect
---@param top number Leftmost edge of viewport rect
---@param width number? The viewport width
---@param height number? The gvieport height
---@param sX number? Texture's reference coordinate values?
---@param sY number? Texture reference coordinate values?
function BaseTextureLayer:setViewport(left, top, width, height, sX, sY)
    local problem = typechecks.err.checkSizeDimensions(
        {["left"]=left},
        {["top"]=top}
    )
    if problem then
        error(problem)
    end

    if width == nil or height == nil then
        local screenW, screenH = graphics:getPixelDimensions()
        width = width or screenW
        height = height or screenH
    end
    if sX == nil or sY == nil then
        local tW, tH = self._texture:getDimensions()
        sX = --[[@as number]] sX or tW
        sY = --[[@as number]] sY or tH
    end
    -- local viewport = {left, top, width, height, sX, sY}
    self._quad:setViewport(left, top, width, height, sX, sY)
    -- self._viewport = viewport
end


function BaseTextureLayer:draw()
    local texture = self._texture
    local quad = self._quad
    if texture ~= nil and quad ~= nil then
        graphics.draw(texture, quad)
    end
end


local CheckersLayer = BaseTextureLayer:subclass('CheckersLayer')
uilayers.CheckersLayer = CheckersLayer

--- Create a checkers layer which
function CheckersLayer:initialize(colorsOrTexture)
    local T_colorsOrTexture = type(colorsOrTexture)
    local texture = colors.checkers.ALPHA
    local colors = colors.ALPHA_GRAY_COLORS

    if colorsOrTexture and T_colorsOrTexture == 'table' then
        if #colorsOrTexture ~= 2 then
            error(fmt.errors.typeError("Expected table of {fg, bg} but got %s'", {T_colorsOrTexture}))
        end
        texture = colors.makeCheckers(colorsOrTexture)
        ---@cast colorsOrTexture table<integer, table<integer, number>>
        colors = colorsOrTexture
    end
    local screenW, screenH = graphics.getPixelDimensions()
    local refW, refH = texture:getDimensions()
    local quad = graphics.newQuad(0,0,screenW, screenH, refW, refH)
    --- Important: can't BaseTextureLayer:initialize b/c:
    --- 1. it'd pass its own value as self
    --- 2. we need the object, not the class as a value
    BaseTextureLayer.initialize(self, texture, {["quad"]=quad})
    self._colors = colors
end


local ImageLayer = BaseTextureLayer:subclass('ImageLayer')
uilayers.ImageLayer = ImageLayer


--- Create an image layer.
---@param image love.Image|love.Texture?
---@param quad love.Quad?
function ImageLayer:initialize(image, quad)
    local options = {["quad"]=quad}
    BaseTextureLayer.initialize(self, image, options)
    --self:setImage(self.image)
end


--- Show an image, or set to show nothing.
---@param image love.Image|love.Texture?
function ImageLayer:setImage(image)
    if self._texture ~= image then
        self._texture = image
    end
    if image then
        self._quad = _getQuadForImage(image)
    end
end


---@param filepath string|Path
function ImageLayer:loadImage(filepath)
    local image = imageconvert.load_image(filepath)
    if image then
        self:setImage(image)
    end
end


---@return table<integer, number>?
function ImageLayer:getImageSize()
    local dimensions = nil
    local image = self._texture
    if image then
        dimensions = {image:getDimensions()}
    end
    return dimensions
end


local BBoxLayer = {}
uilayers.BBoxLayer = BBoxLayer


function BBoxLayer:new(o)
    o = structures.super(self, o)
    if o.runner == nil then
        o.runner = tesseract.TesseractRunner{}
    end
    o.cells = {}
    return o
end


--- Load bboxes for a given filename via the Tesseract runner.
---@param filename string|Path
function BBoxLayer:renderBBoxes(filename)
    local tsvDataRaw = self.runner:getWords(filename)
    self.cells = _getWordPolygonsFromTesseractData(tsvDataRaw)
end


function BBoxLayer:draw()
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


---@param name string
---@param layer any
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
        -- local name = layerData.name
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
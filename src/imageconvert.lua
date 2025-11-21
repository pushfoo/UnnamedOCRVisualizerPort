local class = require "lib.middleclass"

local fmt = require("fmt")
local paths = require("env.paths")
local Path = paths.Path
local load_external_file = paths.load_external_file

local ImageMagick = require("runners.imagemagick").ImageMagick

local imageconvert = {}

--pending: a better fix for so-called missing fields


local DEFAULT_IMAGE_MAGICK = ImageMagick:new()

---@class ImageLoader
---@overload fun():ImageLoader
ImageLoader = class('ImageLoader')


--pending: a better fix for so-called "missing" fields
---@param use_magic ImageMagick
---@param native_formats table<string, boolean>?
function ImageLoader:initialize(use_magic, native_formats)
    if use_magic == nil then
        use_magic = DEFAULT_IMAGE_MAGICK
    ---@diagnostic disable-next-line
    elseif ImageMagick:isInstanceOf(use_magic) then
        error(fmt.errors.typeError('expected an ImageMagic, not a %s', {use_magic}))
    end
    ---@cast use_magic ImageMagick
    self.use_magic = use_magic
    if native_formats == nil then
        native_formats = {jpg = true, jpeg = true, png = true, bmp = true}
    end
    self.native_formats = native_formats
end


--- Load an image from a path.
---@param path string|Path A path to load from.
---@return love.Image?
function ImageLoader:loadImage(path)
    local data = nil
    local image = nil
    local pathObject = Path:new(path)
    local extension = pathObject:getExtension()

    if self.native_formats[extension] then
        print("ImageLoader using native loading for " .. extension)
        data = load_external_file(path, "rb")
    elseif self.use_magic then
        print("ImageLoader using imagemagick shell wrapper")
        local raw = self.use_magic:readStdin(path)
        if raw then
            local pathAsPngLike = tostring(path) .. ".png"
            data = love.filesystem.newFileData(raw, pathAsPngLike)
        end
    else
        error("NoImageMagick: Cannot load non-supported image type without ImageMagick: " .. tostring(path))
    end
    if data then
        image = love.graphics.newImage(data)
    end
    return image
end


---@diagnostic disable-next-line
local DEFAULT_LOADER = ImageLoader:new()


--- Load an image, optionally using a specified ImageLoader.
---@param path string|Path Where to load from.
---@param loader ImageLoader?
---@return love.Image?
function imageconvert.load_image(path, loader)
    loader = loader or DEFAULT_LOADER
    print(string.format("Attempting to load %s...", path))
    for k, v in pairs(loader) do
        print(k, v)
    end
    local loaded = loader:loadImage(path)
    return loaded
end


return imageconvert

local class = require "lib.middleclass"

local fmt = require("fmt")
local util = require("util")
local env = require("env")
local Path, run, Runner = env.Path, env.run, env.Runner

local imageconvert = {}

--pending: a better fix for so-called missing fields


---@class ImageMagick
---@field which string|Path
---@overload fun():ImageMagick
---@diagnostic disable-next-line
local ImageMagick = Runner:subclass('ImageMagick')


if ImageMagick.new == nil then
    ---comment
    ---@param which string|Path?
    ---@param native_formats table<string, boolean>?
    ---@return ImageMagick
    function ImageMagick:new(which, native_formats)
        -- stub b/c luals is kinda broken
    ---@diagnostic disable-next-line
    end
end


---@param which string?
---@param native_formats table<string, boolean>?
function ImageMagick:initialize(which, native_formats)
    ---@diagnostic disable-next-line
    Runner.initialize(self, "magick", which)
    self.native_formats = native_formats or {}
end


imageconvert.ImageMagick = ImageMagick

local IMAGE_MAGICK_INLINE = "%s %s INLINE:PNG32:-"
local INLINE_PNG_HEADER = "data:image/png;base64,"
local N_INLINE_PNG_HEADER = #INLINE_PNG_HEADER


--- Overcome LuaJIT's lack of "b" mode in io.popen via base64 emission mode.
---@param path string|Path
---@return love.Data?
function ImageMagick:readStdin(path)
    -- Appropriate CSS data URL generation (32-bit)
    local command = IMAGE_MAGICK_INLINE:format(self.which, path)
    local raw = run.readString(command)
    local data = nil
    if raw and util.startsWith(raw, INLINE_PNG_HEADER) then
        -- throw away the "data:image/png;base64,"
        local minusHeader = raw:sub(N_INLINE_PNG_HEADER, #raw)
        data = love.data.decode("data", "base64", minusHeader)
    end
    ---@cast data love.Data?
    return data
end


--- Attempt to load a path as a Love image object.
---@param path string|Path
---@return love.Image
function ImageMagick:loadAsLoveImage(path)
    local image = nil
    local tPath = type(path)
    if tPath ~= "string" then
        if getmetatable(path) == Path then
            path = tostring(path)
        else
            fmt.errors.typeError("expected a string or a Path, not path=%s", {path})
        end
    end
    local bytes = self:readStdin(path)
    if bytes then
        local data = love.filesystem.newFileData(bytes, tostring(path))
        image = love.graphics.newImage(data)
    end
    --[[@cast image love.Image]]
    return image
end


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
        data = util.external.load_file(path, "rb")
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

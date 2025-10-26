local util = require("util")
local env = require("env")
local structure = require("structures")

local Class = structure.Class
local Path = env.Path
local run = env.run

---@package imageconvert
local imageconvert = {}

--pending: a better fix for so-called missing fields
---@diagnostic disable undefined-param
---@class ImageMagick
---@param which string
---@param native_formats table[[[string,boolean]]]
local ImageMagick = env.makeRunnerClass("magick")
---@diagnostic enable


imageconvert.ImageMagick = ImageMagick

local INLINE_PNG_HEADER = "data:image/png;base64,"
local IMAGE_MAGICK_INLINE = "%s %s INLINE:PNG32:-"

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
        local minusHeader = raw:sub(#INLINE_PNG_HEADER, #raw)
        data = love.data.decode("data", "base64", minusHeader)
    end
    ---@diagnostic disable-next-line
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
            error("TypeError: expected a string or a Path, not a " .. tPath)
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


--pending: a better fix for so-called "missing" fields
---@diagnostic disable
---@class ImageLoader
---@param native_formats table<string, boolean>?
---@param use_magic ImageMagick?
ImageLoader = Class({
    native_formats = {jpg = true, jpeg = true, png = true, bmp = true},
    use_magic = DEFAULT_IMAGE_MAGICK
})
---@diagnostic enable


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

local defaultLoader = ImageLoader:new()

--- Load an image, optionally using a specified ImageLoader.
---@param path string|Path Where to load from.
---@param loader ImageLoader?
---@return love.Image?
function imageconvert.load_image(path, loader)
    loader = loader or defaultLoader
    print(string.format("Attempting to load %s...", path))
    for k, v in pairs(loader) do
        print(k, v)
    end
    ---@diagnostic disable-next-line
    local loaded = loader:loadImage(path)
    return loaded
end

return imageconvert

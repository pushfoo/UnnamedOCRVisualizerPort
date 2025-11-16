local fmt = require("fmt")
local util = require("util")
local env = require("env")
local run = env.run
local Path = env.Path
local BaseRunner = require("runners.base_runner").BaseRunner

local imagemagick = {}

---@class ImageMagick
---@field which string|Path
---@overload fun():ImageMagick
---@diagnostic disable-next-line
local ImageMagick = BaseRunner:subclass('ImageMagick')


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
    BaseRunner.initialize(self, "magick", which)
    self.native_formats = native_formats or {}
end


imagemagick.ImageMagick = ImageMagick

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

imagemagick.ImageMagick = ImageMagick


return imagemagick
require("env")


ImageMagick = makeRunnerClass("magick")

local INLINE_PNG_HEADER = "data:image/png;base64,"
function ImageMagick:readStdin(path)
    -- Appropriate CSS data URL generation (32-bit)
    local command = string.format("%s %s INLINE:PNG32:-", self.which, path)
    local raw = env.run.readString(command)
    if util.startsWith(raw, INLINE_PNG_HEADER) ~= true then
        return nil
    end

    -- throw away the "data:image/png;base64,"
    local minusHeader = raw:sub(#INLINE_PNG_HEADER, #raw)
    local data = love.data.decode("data", "base64", minusHeader)
    return data
end


function ImageMagick:loadAsLoveImage(path)
    local bytes = self:readStdin(path)
    local image = nil
    if bytes then
        local data = love.filesystem.newFileData(bytes, tostring(path))
        image = love.graphics.newImage(data)
    end
    return image
end


function isNativeFileType(path, native_types)
    print(path, native_types)
    local extension = Path:new(path):getExtension()
    for supported in native_types do
        if supported == extension then
            return true
        end
    end
    return false
end


ImageLoader = Class({
    natively_supports = {jpg = true, jpeg = true, png = true, bmp = true},
    use_magic = ImageMagick:new()
})


function ImageLoader:loadImage(path)
    local data = nil
    local image = nil
    local pathObject = Path:new(path)
    local extension = pathObject:getExtension()

    if self.natively_supports[extension] then
        print("ImageLoader using native loading for " .. extension)
        data = util.external.load_file(path, "rb")
    elseif self.use_magic then
        print("ImageLoader using imagemagick shell wrapper")
        local raw = self.use_magic:readStdin(path)
        -- local path_minus = path:sub(1, n - extension)
        local pathAsPngLike = tostring(path) .. ".png"
        data = love.filesystem.newFileData(raw, pathAsPngLike)
    else
        error("NoImageMagick: Cannot load non-supported image type without ImageMagick: " .. tostring(path))
    end
    if data then
        image = love.graphics.newImage(data)
    end
    return image
end

local defaultLoader = ImageLoader:new()


function load_image(path, loader)
    loader = loader or defaultLoader
    print(string.format("Attempting to load %s...", path))
    for k, v in pairs(loader) do
        print(k, v)
    end
    local loaded = loader:loadImage(path)
    return loaded
end

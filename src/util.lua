require("typechecks")
require("structures")
require("fmt")


util = {

    tableWrapNonNil = function(t)
        local typeOf = type(t)
        local result = nil
        if typeOf == "table" then
            result = t
        elseif t ~= nil then
            result = {t}
        end
        return result
    end,
    graphics = {
        textureFromCanvas = function(canvas)
            local data = love.graphics.readbackTexture(canvas)
            local image = love.graphics.newImage(data)
            return image
        end
    },
    passthru = function(a) return a end,
    printTable = function(t, printer)
        p = printer or print
        local joined = fmt.table(t)
        p(joined)
    end,
    functional = {
        skipN = function(iterator, nToSkip)
            if nToSkip ~= nil then
                for _ = 1, nToSkip do
                    iterator()
                end
            end
            return iterator
        end
    },
    escapePathSpaces = function(rawPath)
        return rawPath:gsub(" ", "\\ ")
    end,
    lastOfString = function(rawString, splitPattern)
        local value = nil
        for v in string.gmatch(rawString, splitPattern) do
            value = v
        end
        return value
    end,
    external = {
        load_file = function(path, mode)
            local file = io.open(path, mode)
            local raw = file:read("*a")
            file:close()
            local data = love.filesystem.newFileData(raw, path)
            return data
        end,
        load_image = function(path)
            local data = util.external.load_file(path, "rb")
            return love.graphics.newImage(data)
        end
    }
}

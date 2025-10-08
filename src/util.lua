require("fmt")

table.extend = function(dest, t)
    for i, value in ipairs(t) do
        table.insert(dest, value)
    end
end

-- A table with support for tableName:insert, etc.
NiceTable = {
    __index = table,
}
function NiceTable:new(o)
    o = o or {}
    setmetatable(o, self)
    return o
end


--[[ Currently only used by UI layers; might get removed.

A review of current OOP systems since the last time I
tried Love2D would help a lot. It looks like there may
be some innovation since the last time I looked?
]]
function super(self, o, parent)
    if o == nil then o = {} end
    setmetatable(o, parent or self)
    self.__index = self
    return o
end


util = {
    is = {
        Integer = function(number)
            if type(number) ~= "number" then return false end
            return math.modf(number) == 0.0
        end,
        NonEmptyArray = function(t)
            return type(t) == "table" and #t > 0
        end
    },
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

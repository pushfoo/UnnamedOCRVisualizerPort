require("fmt")

-- A table with support for tableName:insert, etc.
NiceTable = {__index = table}

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

--[[ Check if this appears to be an array ]]
function isNonEmptyArray(t)
    return type(t) == "table" and #t > 0
end

util = {
    passthru = function(a) return a end,
    printTable = function(t, printer)
        p = printer or print
        local joined = fmt.table(t)
        p(joined)
    end,
    functional = {
        skipN = function(iterator, nToSkip)
            if nToSkip ~= nil then
                for i = 1, nToSkip do
                    _ = iterator()
                end
            end
            return iterator
        end
    },
    external = {
        load_file = function(path, mode)
            local file = io.open(path, mode)
            local data = love.filesystem.newFileData(file:read("*a"), path)
            file:close()
            return data
        end,
        load_image = function(path)
            local data = util.external.load_file(path, "rb")
            return love.graphics.newImage(data)
        end
    }
}

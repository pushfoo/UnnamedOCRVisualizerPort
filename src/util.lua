require("fmt")

-- A table with support for tableName:insert, etc.
NiceTable = {__index = table}

function NiceTable:new(o)
    o = o or {}
    setmetatable(o, self)
    return o
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

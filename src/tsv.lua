--[[ A good-enough CSV implementation.

IMPORTANT: NOT feature complete, see other implementations for that!
]]

require("structures")
require("util")
require("args")
require("rect")


local DelimConfig = {
    forceHeader = nil,
    eolPattern = "[^\r\n]+",
    sepPattern = "[^\t]+",
}


function DelimConfig:new(o)
    return super(self, o)
end


splitHelpers = {
    columns = function(line, sepPattern)
        columns = NiceTable:new()
        for value in line:gmatch(sepPattern) do
            columns:insert(value)
        end
        return columns
    end,
    --[[ Fetch the rows themselves.

    ]]
    rows = function(stringRaw, config)
        if config == nil then
            config = DelimConfig:new()
        end
        local sepPattern = config.sepPattern
        local eolPattern = config.eolPattern
        local rows = NiceTable:new()
        local splitColumns = splitHelpers.columns
        for line in stringRaw:gmatch(eolPattern) do
            local columns = splitColumns(line, sepPattern)
            rows:insert(columns)
        end
        return rows
    end,
    namedTables = function(stringRaw, config)
        config = DelimConfig:new{unpack(config or {})}
        local forceHeader = config.forceHeader
        local raw = splitHelpers.rows(stringRaw, config)
        local header = nil
        local iterationStart = nil
        if forceHeader == nil then
            header = raw[1]
            iterationStart = 2
        else
            header = forceHeader
            iterationStart = 1
        end
        local nHeader = #header
        local nDataRows = #raw
        local namedRows = NiceTable:new()
        local n_items = 0
        for rowIndex = iterationStart,nDataRows do
            local colData = raw[rowIndex]
            local namedTable = {}
            for i = 1,nHeader do
                local name = header[i]
                local data = colData[i]
                namedTable[name] = data
            end
            namedRows:insert(namedTable)
            n_items = n_items + 1
        end
        -- Lua tables and ipairs aren't Python dicts (ipairs only works on "Array tables")
        local structured = {
            columnOrder=header,
            rows=namedRows,
            n_items = n_items
        }

        return structured
    end
}

DelimReader = {config = DelimConfig:new()}


function DelimReader:new(o)
    o = super(self, o)
    return o
end


function DelimReader:readString(string)
    return splitHelpers.namedTables(string, self.config)
end


function DelimReader:readFile(path)
    local file = io.open(path, "r")
    local raw = nil
    if file then
        raw = file:read("*a")
        file:close()
    end
    return raw
end


genericReaders = {
    tsv = DelimReader:new(),
    csv = DelimReader:new{config=DelimConfig:new{sepPattern="[^,]+"}}
}

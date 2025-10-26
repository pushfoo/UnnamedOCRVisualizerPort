--[[ A good-enough CSV implementation.

IMPORTANT: NOT feature complete, see other implementations for that!
]]

local structures = require("structures")
local NiceArray = structures.NiceArray
local util = require("util")
require("args")


local tsv = {}

tsv.DelimConfig = {
    forceHeader = nil,
    eolPattern = "[^\r\n]+",
    sepPattern = "[^\t]+",
}


function tsv.DelimConfig:new(o)
    return structures.super(self, o)
end

local _splitHelpers = {}

function _splitHelpers.columns(line, sepPattern)
    local columns = NiceArray:new()
    for value in line:gmatch(sepPattern) do
        columns:insert(value)
    end
    return columns
end
--[[ Fetch the rows themselves.

]]
function _splitHelpers.rows(stringRaw, config)
    if config == nil then
        config = tsv.DelimConfig:new()
    end
    local sepPattern = config.sepPattern
    local eolPattern = config.eolPattern
    local rows = NiceArray:new()
    local splitColumns = _splitHelpers.columns
    for line in stringRaw:gmatch(eolPattern) do
        local columns = splitColumns(line, sepPattern)
        rows:insert(columns)
    end
    return rows
end

function _splitHelpers.namedTables(stringRaw, config)
    config = tsv.DelimConfig:new{unpack(config or {})}
    local forceHeader = config.forceHeader
    local raw = _splitHelpers.rows(stringRaw, config)
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
    local namedRows = NiceArray:new()
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

tsv.DelimReader = {config = tsv.DelimConfig:new()}


function tsv.DelimReader:new(o)
    o = structures.super(self, o)
    return o
end


function tsv.DelimReader:readString(string)
    return _splitHelpers.namedTables(string, self.config)
end


function tsv.DelimReader:readFile(path)
    local file = io.open(path, "r")
    local raw = nil
    if file then
        raw = file:read("*a")
        file:close()
    end
    return raw
end


tsv.genericReaders = {
    tsv = tsv.DelimReader:new(),
    csv = tsv.DelimReader:new{config=tsv.DelimConfig:new{sepPattern="[^,]+"}}
}
return tsv

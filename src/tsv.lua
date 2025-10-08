require("util")
require("args")
require("rect")


function splitLineTSVLine(line, sepPattern)
    sep = sep or "\t"
    -- local pattern = getNegativeMatchPattern(sep)

    columns = NiceTable:new()
    for value in line:gmatch("[^\t]+") do
        columns:insert(value)
    end
    return columns
end


function readTSVString(stringRaw, config)
    config = config or {}
    local sepPattern = config.sepPattern or "[^\t]+"
    -- This fits the known Tessearct TSV output format despite being technically  "wrong"
    local eolPattern = config.eolPattern or "[^\r\n]+"

    rows = NiceTable:new()
    for line in stringRaw:gmatch(eolPattern) do
        columns = splitLineTSVLine(line, sepPattern)
        rows:insert(columns)
    end
    return rows
end


function readTSVAsTables(stringRaw, forceHeader)
    local raw = readTSVString(stringRaw)
    local header = nil
    local iterationStart = nil
    if forceHeader == nil then
        header = raw[1]
        iterationStart = 2
    else
        header = forceHeader
        iterationStart = 1
    end
    local nHeader = table.getn(header)
    local nDataRows = table.getn(raw)
    local namedRows = NiceTable:new()
    local n_items = 0
    for rowIndex = 2,nDataRows do
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

function readMakeBox()

end


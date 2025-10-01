require("util")
require("args")
require("rect")

function splitLineTSVLine(line)
    columns = NiceTable:new()
    for value in line:gmatch("[^\t]+") do
        columns:insert(value)
    end
    return columns
end


function readTSVString(stringRaw)
    rows = NiceTable:new()
    for line in stringRaw:gmatch("[^\r\n]+") do
        columns = splitLineTSVLine(line)
        rows:insert(columns)
    end
    return rows
end


function readTSVAsTables(stringRaw)
    local raw = readTSVString(stringRaw)

    header = raw[1]
    local nHeader = table.getn(header)
    local nDataRows = table.getn(raw)
    local namedRows = {}
    local n_items = 0
    for rowIndex = 2,nDataRows do
        local colData = raw[rowIndex]
        local namedTable = {}
        table.insert(namedRows, namedTable)
        for i = 1,nHeader do
            local name = tostring(header[i])
            local data = colData[i]
            namedTable[name] = data
        end
        table.insert(namedRows, namedTable)
        n_items = n_items + 1
    end
    -- Lua tables and ipairs aren't Python dicts (ipairs only works on "Array tables")
    local TSVData = {
        headers=headers,
        rows=namedRows,
        n_items = n_items
    }
    return TSVData
end

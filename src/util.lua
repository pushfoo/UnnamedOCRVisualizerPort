require("typechecks")
require("structures")
require("fmt")


function tableWrapString(tableOrString)
    local tType = type(tableOrString)
    if tType == "string" then
        return {tableOrString}
    elseif tType == "table" then
        return tableOrString
    else
        error("TypeError: expected a string or table, not a " .. tType)
    end
end

local trim = function(s)
    return s
        :gsub("^%s*", "")
        :gsub("%s*$", "")
end
local trimEmptyToNil =  function(raw)
    local clean = trim(raw)
    if string.len(clean) > 0 then
        return clean
    else
        return nil
    end
end


util = {
    ["trim"] = trim,
    ["trimEmptyToNil"] = trimEmptyToNil,
    tableWrapNonNil = function(t)
        local typeOf = type(t)
        if typeOf == "table" then
            return t
        elseif t ~= nil then
            return {t}
        else
            return nil
        end
    end,
    --[[ Mnemonic sugar around Lua's weirdly-named string.sub function.

    @param s: The string to get the first char of.
    ]]
    firstChar = function(s)
        local n = string.len(s or "")
        if n == 0 then
            return nil
        else
            return s:sub(1, 1)
        end
    end,
    startsWith = function(target, value)
        local len = string.len
        nGoal = len(value)
        if len(target) < nGoal then
            return false
        end
        return target:sub(1, nGoal) == value
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
        printer = printer or print
        local joined = fmt.table(t)
        printer(joined)
    end,
    functional = {
        skipN = function(iterator, nToSkip)
            if nToSkip ~= nil then
                for _ = 1, nToSkip do
                    iterator()
                end
            end
            return iterator
        end,
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

util.tableWrap = {}
function util.tableWrap.unwrap(t, useIndex)
    local typeOfT = type(t)
    if typeOfT == "table" then
        return t[useIndex or 1]
    else
        return t
    end
end
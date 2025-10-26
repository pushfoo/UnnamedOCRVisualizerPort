local fmt = require("fmt")

local util = {}
util.tableWrap = {}


--- Wrap any bare string in a table, or return a table as-is.
---@param tableOrString string|table
---@return table
function util.tableWrap.string(tableOrString)
    local tType = type(tableOrString)
    if tType == "string" then
        return {tableOrString}
    elseif tType == "table" then
        return tableOrString
    else
        error("TypeError: expected a string or table, not a " .. tType)
    end
end

--- Wrap a non-nil value in a table, or return nil.
---@param t any?
---@return table|any?
function util.tableWrap.nonNil(t)
    local typeOf = type(t)
    if typeOf == "table" then
        return t
    elseif t ~= nil then
        return {t}
    else
        return nil
    end
end


local LTRIM = "^%s+"
local RTRIM = "%s+$"

--- Remove the whitespace from the start and end of the string.
---@param s string s The string to strip whitespace from.
---@return string,number
function util.trim(s)
    local value, sub = s:gsub(LTRIM, "")
    local value2, sub2 = value:gsub(RTRIM, "")
    return value2, sub + sub2
end

util.ltrim = function(s) return s:gsub(LTRIM, "") end
util.rtrim = function(s) return s:gsub(RTRIM, "") end


local trim = util.trim
--- Trim empty strings to nil.
---@param raw string?
---@return ...?
function util.trimEmptyToNil(raw)
    if raw then
        local clean, n = trim(raw)
        if clean and #clean > 0 then
            return clean, n
        end
    end
    return nil
end


--- Mnemonic sugar around Lua's weirdly-named string.sub function.
---@param s string? The string to get the first char of.
---@return string?
function util.firstChar(s)
    if s then
        local n = string.len(s or "")
        if n == 0 then
            return nil
        else
            return s:sub(1, 1)
        end
    end
end

--- Check if a target string starts with a given value.
-- This is not pattern-based but exact equivalence checking.
---@param target string The target to check.
---@param value string value The value to check for at the start of the target.
---@returned boolean Whether the value is at the start of the target.
function util.startsWith(target, value)
    local len = string.len
    local nGoal = len(value)
    if len(target) < nGoal then
        return false
    end
    local atStart = target:sub(1, nGoal)

    return atStart == value
end

--[[ Monkeypatch to make typechecks work before 12.0 is out ]]
if love.graphics.readbackTexture == nil then
    --- Get an ImageData object.
    ---@param canvas love.Canvas
    ---@return love.ImageData
    love.graphics.readbackTexture = function(canvas)
        ---@diagnostic disable-next-line
        return canvas:getTexture()
    end
end


util.graphics = {
    --- Get a texture from a canvas
    ---@param canvas love.Canvas
    ---@return love.Texture
    textureFromCanvas = function(canvas)
        local data = love.graphics.readbackTexture(canvas)
        local image = love.graphics.newImage(data)
        return image
    end
}

--- Print a table, optionally using a specific function to print.
---@param t table
---@param printer function
function util.printTable(t, printer)
    printer = printer or print
    local joined = fmt.table(t)
    return printer(joined)
end

local function fmtSkipError(errorType, value)
    return string.format("%s: nToSkip must be an integer >= 1, not %s", errorType, tostring(value))
end


util.functional = {}

--- Return the passed value(s) as-is.
---@param a any
---@return table<any>
function util.functional.passthru(a) return a end

--- Skip the specified first number of items from the iterator.
---@param iterator function An iterator function
---@param nToSkip number nToSkip The first n values to skip.
---@return function iterator The same iterator function
function util.functional.skipN(iterator, nToSkip)
    if type(nToSkip) ~= "number" then
        error(fmtSkipError("TypeError", nToSkip))
    end
    local _, f = math.modf(nToSkip)
    if nToSkip < 0 or f > 0 then
        error(fmtSkipError("ValueError", nToSkip))
    end
    for _ = 1, nToSkip do
        iterator()
    end

    return iterator
end


--- Escape spaces.
---NOTE: Brittle!
---@param rawPath string a raw string path.
---@return string,number
function util.escapePathSpaces(rawPath)
    return rawPath:gsub(" ", "\\ ")
end


--- Get the last match for a pattern in a string.
---@param rawString string rawString The string to match
---@param matchPattern string The pattern to match.
---@return string? if no matches or a the last match.
function util.lastMatch(rawString, matchPattern)
    local value = nil
    for v in string.gmatch(rawString, matchPattern) do
        value = v
    end

    return value
end

util.external = {}

--- Get a FileData object for an external file via the io module.
---@param path string|Path A path to read from.
---@param mode string The mode to open in ("r" or "rb")
---@return love.FileData? The file data for the given file.
function util.external.load_file(path, mode)
    -- Using tostring here converts our custom Path type.
    local file = io.open(tostring(path), mode)
    local data = nil
    if file then
        local raw = file:read("*a")
        file:close()
        data = love.filesystem.newFileData(raw, tostring(path))
    end

    return data
end


return util
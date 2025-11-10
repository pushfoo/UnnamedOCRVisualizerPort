--[[ Utility helpers.

IMPORTANT: forbidden from importing typechecks!
]]
local util = {}
util.tableWrap = {}
util.table = {}


---Copy from source to a passed or new dest table, then return dest.
---@generic T
---@param source table<integer, T>
---@param dest table<integer, T>?
---@return table<integer, T>
function util.table.copyArray(source, dest)
    dest = dest or {}
    local T_source
    if T_source ~= 'table' then
        error('TypeError: expected type(source)=="table" but got a ' .. T_source)
    end
    for _, value in ipairs(source) do
        table.insert(dest, value)
    end
    return dest
end

--- Wrap any bare string in a table, or return a table as-is.
---@param tableOrString string|table
---@return table<integer, any>
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

-- Whitespace at the left
local LTRIM = "^%s+"
-- Whitespace at theithe right
local RTRIM = "%s+$"

--- Remove the whitespace from the start and end of the string.
---@param s string s The string to strip whitespace from.
---@return string,number
function util.trim(s)
    local value, sub = s:gsub(LTRIM, "")
    local value2, sub2 = value:gsub(RTRIM, "")
    return value2, sub + sub2
end

---Trim all whitespace on the lefthand side and return trim + n trimmed?
---@param s string A string to trim at the left.
---@return string,integer
util.ltrim = function(s)
    return s:gsub(LTRIM, "")
end
---Trim all whitespace at the righthand side and return trim + n trimmed?
---@param s string
---@return string,integer
util.rtrim = function(s) return s:gsub(RTRIM, "") end

local trim = util.trim

--- Trim empty strings to nil.
---@param raw string?
---@return string?,integer?
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

local _len = string.len

--- Check if a target string starts with a given value.
-- This is not pattern-based but exact equivalence checking.
---@param target string The target to check.
---@param value string The value to check for at the start of the target.
---@return boolean - Whether the value is at the start of the target.
function util.startsWith(target, value)
    local nGoal = _len(value)
    if _len(target) < nGoal then
        return false
    end
    local atStart = target:sub(1, nGoal)

    return atStart == value
end

--- Check if a target string ends with a given value.
-- This is not pattern-based but exact equivalence checking.
---@param target string The target to check.
---@param value string The value to check for at the end of the target.
---@return boolean - Whether the value is at the start of the target.
function util.endsWidth(target, value)
    local n_goal = _len(value)
    local n_target = _len(target)
    if n_target < n_goal then
        return false
    end
    local atEnd = target:sub(n_target - n_goal, n_target)
    return atEnd == value
end


--[[ Monkeypatch to make typechecks work before 12.0 is out ]]
if love and love.graphics then
    if love.graphics.readbackTexture == nil then
        --- Get an ImageData object.
        ---@param canvas love.Canvas
        ---@return love.ImageData
        love.graphics.readbackTexture = function(canvas)
            ---@diagnostic disable-next-line
            return canvas:getTexture()
        end
    end
end


util.graphics = {}

--- Get a texture from a canvas
---@param canvas love.Canvas
---@return love.Texture
function util.graphics.textureFromCanvas(canvas)
    local data = love.graphics.readbackTexture(canvas)
    local image = love.graphics.newImage(data)
    return image
end

---Local error helper b/c fmt import forbidden.
---@param errorType string
---@param value any
---@return string
local function fmtSkipError(errorType, value)
    return string.format("%s: nToSkip must be an integer >= 1, not %s", errorType, tostring(value))
end


util.functional = {}

--- Return the passed value(s) as-is.
---@generic A
---@param a A
---@return A
function util.functional.passthru(a) return a end

--- Skip the specified first number of items from the iterator.
---@param iterator function An iterator function
---@param nToSkip number nToSkip The first n values to skip.
---@return function iterator The same iterator function
function util.functional.skipN(iterator, nToSkip)
    T_nToSkip = type(nToSkip)
    if T_nToSkip ~= "number" then
        --- remember, no fmt imports!
        error(fmtSkipError("TypeError", T_nToSkip))
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


---Shorthand akin to  `EXPR ? trueVal : falseVal` in other languages.
---Passing nil for either is intended to permit tern(expr, maybeNil, fallback)
---@param condition any
---@param returnWhenTrue any?
---@param returnWhenFalse any?
function util.functional.tern(condition, returnWhenTrue, returnWhenFalse)
    if condition then
        return returnWhenTrue
    else
        return returnWhenFalse
    end
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
---@return string? - no matches or a the last match.
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
---@return love.FileData? - file data for the given file.
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
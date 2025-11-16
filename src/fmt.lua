--[[ Shared formatting helpers.

IMPORTANT: forbidden from importing from typechecks

- quote
- flag helpers (short and long)
- table printing
- error formatting
- storage for error format prefabs

]]
local _util = require("util")
local _endsWith = _util.endsWith
local _firstChar = _util.firstChar
local fmt = {}

--- Quote-wrap any item (naively passes to tostring() first).
---@param anything any a value to quotewrap
---@param quote string? optional quote character (defaults to `"`)
---@return string
function fmt.quote(anything, quote)
    quote = quote or "\""
    if type(anything) ~= "string" then
        anything = tostring(anything)
    end
    return string.format("%s%s%s", quote, anything, quote)
end

    -- [[ Format CLI flags. ]]
fmt.flags = {}


--- Format a name to a short flag by taking the first character.
--- IMPORTANT: Assumes the following:
--- - We don't need to case-shift values.
--- - The first char will be valid.
---@param name string The name of the variable.
---@return string - The `-n` for `name_width_underscores`.
function fmt.flags.short(name)
    return "-" .. string.sub(name, 1, 1)
end

--- Format a name to a long flag.
---@param name string A value name for the flag.
---@param autoLower? boolean Whether to autolowercase.
---@return string? - A string of the form `--name-with-dashes`.
function fmt.flags.long(name, autoLower)
    local substituted = name:gsub("[_%w]+", "-")
    if substituted then
        if autoLower or false then
             substituted = substituted:lower()
        end
        return "--" .. substituted
    end
    return nil
end

--- Format a table as a string.
---@param t table<any, any>
---@param indent? string
---@return string
function fmt.table(t, indent)
    if t == nil then return "nil" end
    if indent == nil then indent = "" end
    local parts = {}
    for k, v in ipairs(t) do
        local kString = tostring(k)
        local vString = nil
        if type(v) == "table" then
            vString = fmt.table(v, indent .. "    ")
        else
            vString = tostring(v)
        end
        local formatted = string.format("    %s=%s", kString, vString)
        table.insert(parts, formatted)
    end
    local joined = "{\n" .. table.concat(parts, ",\n") .. "\n}"
    return joined
end

--- Print a table, optionally using a specific function to print.
---@param t table
---@param printer function
function fmt.printTable(t, printer)
    printer = printer or print
    local joined = fmt.table(t)
    return printer(joined)
end

--- Format an error message
---@param errorName string IndexError, etc.
---@param template string A string.format template.
---@param args table<string, any> A table of args to unpack.
---@return string
function fmt.error(errorName, template, args)
    return errorName .. ": " .. string.format(template, unpack(args))
end

--- Return a wrapped fmt.error wrapper which takes a table.
---@param errorName string
---@param template string
---@return function
function fmt.getErrorTemplater(errorName, template)
    local templater = function(args)
        return fmt.error(errorName, template, args)
    end
    return templater
end

--[[ Static table to hold shared error formatters (see below)]]


fmt.errors = {}
fmt.CACHE_NAMED_ERROR_FUNCS = true

local _lowerizedCache = {}
fmt.names = {}


--- Converted ClassNameCase to camelCase.
---@param classCase string A possibly capitalized name.
---@param skipCache boolean? whether to skip caching the result.
---@return string
function fmt.names.getAsCamelCase(classCase, skipCache)
    skipCache = skipCache or true
    local loweredName = _lowerizedCache[classCase]
    if loweredName == nil then
        local lowerFirst = _firstChar(classCase):lower()
        local rest = classCase:sub(1, #classCase)
        loweredName = lowerFirst .. rest
        _lowerizedCache[classCase] = loweredName
    end
    return loweredName
end

--- Return an error string if the named value has a problem, or nil if okay.
---@param name string an argument name.
---@param value any a value which should be a string but might not be.
---@return string?
local function _checkStringArg(name, value)
    local problem = nil
    if type(value) ~= 'string' then
        problem = string.format('TypeError: expected a string but got %s=%s', name, tostring(value))
    elseif #value == 0 then
        problem = string.format('ValueError: expected a non-empty string, but got ""')
    end
    return problem
end


---@param toCheck string The string to check for a suffix.
---@param suffix string The suffix to check for.
---@return string
function fmt.ensureSuffix(toCheck, suffix)
    local problem = nil
    local withSuffix = nil
    problem = (
        _checkStringArg("toCheck", toCheck)
        or _checkStringArg("suffix", suffix)
    )
    if problem then
        error(problem)
    elseif _endsWith(toCheck, suffix) then
        withSuffix = toCheck
    else
        withSuffix = toCheck .. suffix
    end

    return withSuffix
end

---@param name string
---@param useCache boolean?
---@returns function<string, table<integer, any>>
local function getNamed(name, useCache)
    local T_name = type(name)
    if T_name ~= 'string' then
        error(string.format("TypeError: name must be a string, but got a %s", T_name))
    end
    useCache = useCache or fmt.CACHE_NAMED_ERROR_FUNCS
    -- Store the ref cuz we'll use it below.
    local lowered = nil
    if useCache then
        local maybeNoSuffix = fmt.names.getAsCamelCase(name)
        lowered = fmt.ensureSuffix(maybeNoSuffix, "Error")
        if lowered == "getNamed" then
            error(string.format("ValueError: \"%s\" is a reserved name.", lowered))
        end
        local maybeCached = fmt.errors[lowered]
        if maybeCached and maybeCached.__call then
            return maybeCached
        end
    end

    local func = function(template, args)
        return fmt.error(name, template, args)
    end

    -- re-use our earlier lowered first character name to set the cache
    if useCache then
        ---@cast lowered string
        fmt.errors[lowered] = func
    end

    return func
end

fmt.errors.getNamed = getNamed


--- Generate error formatter functions on fmt.errors
---@param ... string Names for errors, e.g. "Value" or "IndexError" ("Error" suffix optional)
local function buildOutErrorNames(...)
    for i, name in ipairs(arg) do
        if type(name) ~= "string" then
            error(string.format('TypeError: expected string names, but element [%i]==%s', i, name))
        elseif name == "" then
            error(string.format('ValueError: cannot have empty string name at element [%i]="%s"', i, name))
        elseif name == "GetNamed" or name == "getNamed" then
            error(string.format('ValueError: '))
        end
        -- Force the error formatter to be stored.
        local _ = getNamed(name, true)
    end
end


buildOutErrorNames(
    'Type',
    'Value',
    'Index',
    'WrongSize',
    'NoExecutable',
    'NotImplemented'
)


return fmt
local fmt = require("fmt")
local typechecks = {is = {}, err = {}}

--- True if it's got a .__call metamethod.
---@param maybeCallable any
---@return boolean
function typechecks.is.callable(maybeCallable)
    return maybeCallable and type(maybeCallable.__call) == "function"
end


--- True if it's an integer number.
---@param number any
---@return boolean
function typechecks.is.Integer(number)
    if type(number) ~= "number" then return false end
    return math.modf(number) == 0.0
end

---Checks if the passed table is a table with the given metatable.
---
---@param table any
---@param metatable table
---@return boolean
function typechecks.is.tableWithMeta(table, metatable)
   return type(table) == 'table' and getmetatable(table) == metatable
end


typechecks.MAX_INTROSPECTION_DEPTH = 10
--- Try to naively guess callability? DOES NOT ACCOUNT FOR LOOPY BAD STRUCTURES!
---@param maybeFunctionLike any
---@param recursionDepth integer?
---@return boolean
function typechecks.is.Callable(maybeFunctionLike, recursionDepth)
    if maybeFunctionLike == nil then
        return false
    elseif type(maybeFunctionLike) == 'function' then
        return true
    end
    recursionDepth = recursionDepth or 0
    local MAX_DEPTH = typechecks.MAX_INTROSPECTION_DEPTH
    if recursionDepth > MAX_DEPTH then
        error(string.format("DangerousRecursion: exceeded MAX_INTROSPECTION_DEPTH=%i on %s", MAX_DEPTH, tostring(maybeFunctionLike)))
    end
    return typechecks.is.Callable(maybeFunctionLike.__call, recursionDepth + 1)
end


-- function typeCheckTable(name, maybe_t, fmtstringNameType)
--     local t = type(maybe_t)
--     if t ~= "table" then
--         if fmtstringNameType then
--             return string.format("TypeError: " .. fmtstringNameType, name, t)
--         else
--             return table_type_error({name, t})
--         end
--     else
--         return nil
--     end
-- end
--
--- True if it's an Array table.
---@param t any
---@return boolean
function typechecks.is.Array(t)
    return type(t) == "table" and #t ~= nil
end

--- True if it's a non-empty Array.
---@param t any
---@return boolean
function typechecks.is.NonEmptyArray(t)
    return type(t) == "table" and #t > 0
end

--- True if it's a string with #s > 0.
---@param s any A potential string.
---@return boolean
function typechecks.is.NonEmptyString(s)
    return type(s) == 'string' and #s > 0
end

---Return nil or an error string if the dimension is not a number > 0.
---@param name string
---@param dim any
---@return string?
local function invalidSizeAxis(name, dim)
    local problemFn = nil
    local e = fmt.errors
    if type(dim) ~= "number" then
        problemFn = e.typeError
    elseif dim <= 0 then
        problemFn = e.valueError
    end
    if problemFn then
        return problemFn("%s must be a number > 0, but got %s=%s", {name, name, tostring(dim)})
    end
end

typechecks.err.invalidSizeAxis = invalidSizeAxis

---Get nil or an error string fo the size dimensions given.
---```lua
---local err = checkSizeDimensions(
--- {left=-2.0},  -- this value will get the error
--- {top=-3.0}
---)
---```
---@param ... table<string, any>
---@return string?
local function invalidSizeDimensions(...)
    local problem = nil
    for i, v in ipairs(arg) do
        local name, value = v[1], v[2]
        problem = invalidSizeAxis(name, value)
        if problem then
            return problem
        end
    end
end
typechecks.err.invalidSizeDimensions = invalidSizeDimensions

function typechecks.err.nonStringOrEmptyString(str)
    local e = fmt.errors
    local T_str = type(str)
    local problem
    if T_str ~= 'string' then
        problem = e.typeError
    else
        problem = e.valueError
    end
    if problem then return problem("expected string %s ~= '', but got a %s", {str, T_str}) end
end
typechecks.err.TEMPLATE_NOT_ARRAY_OF_LENGTH = "expected array #%s == %i, but got a %s"
local TEMPLATE_NOT_ARRAY_OF_LENGTH = typechecks.err.TEMPLATE_NOT_ARRAY_OF_LENGTH

typechecks.err.TEMPLATE_NOT_NON_EMPTY_STRING = "%s=%s (a %s) when it must be non-empty string"
local TEMPLATE_NOT_NON_EMPTY_STRING = typechecks.err.TEMPLATE_NOT_NON_EMPTY_STRING

---comment
---@param name any
---@param maybeString any
---@return string?
function typechecks.err.notNonEmptyString(name, maybeString)
    local problemName = nil
    local problem = nil
    local T_maybeString = type(maybeString)
    if type(maybeString) ~= "string" then
        problemName = "TypeError"
    elseif string.len(maybeString) then
        problemName = "ValueError"
    end
    if problemName then
        problem = string.format(TEMPLATE_NOT_NON_EMPTY_STRING, name, tostring(maybeString), T_maybeString)
    end
    return problem
end


---Return nil or an error string explaining how it's not an array of size n.
---@param name string
---@param arr any
---@param n integer
---@return string?
function typechecks.err.notArrayOfLength(name, arr, n, template)

    local e = fmt.errors
    local T_arr = type(arr)
    local problem = nil
    if T_arr ~= "table" then
        problem = e.typeError
    elseif #arr ~= n then
        problem = e.valueError
    end
    if problem then
        return problem(
            TEMPLATE_NOT_ARRAY_OF_LENGTH,
            {name, n, T_arr}
        )
    end
end

return typechecks
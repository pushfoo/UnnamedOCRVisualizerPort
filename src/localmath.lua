local bit = require("bit")
local fmt = require("fmt")
local localmath = {}

---@class _HasAdd
local _HasAdd = {}

---@generic T_HasAdd : _HasAdd
---@param b T_HasAdd
---@return T_HasAdd
function _HasAdd:__add(b)
---@diagnostic disable-next-line
end

---@class _HasMul
local _HasMul = {}

---@generic T_HasMul
---@param b T_HasMul
---@return T_HasMul
function _HasMul:__mul(b)
---@diagnostic disable-next-line
end

---@class _HasAddSubMul
local _HasAddSubMul = {}

---@generic T_HasAddSubMul : _HasAddSubMul
---@param b T_HasAddSubMul
---@return T_HasAddSubMul
function _HasAddSubMul:__add(b)
---@diagnostic disable-next-line
end

---@generic T_HasAddSubMul
---@param b T_HasAddSubMul
---@return T_HasAddSubMul
function _HasAddSubMul:__mul(b)
---@diagnostic disable-next-line
end


--- Scale a valueSize to fit into a goalSize.
---The currentSize dimensions cannot be zero or there will be ValueErrors.
---@param goalSize table<integer,number>
---@param currentSize table<integer,number>
---@return table<integer,number>
function localmath.scaleSizeInto(goalSize, currentSize)
    local vW = currentSize[1]
    local vH = currentSize[2]
    if vW == 0 then error("ValueError: goalSize cannot have width=0") end
    if vH == 0 then error("ValueError: goalSize cannot have height=0") end

    local maxW = goalSize[1]
    local maxH = goalSize[2]
    local ratioW = maxW / vW
    local ratioH = maxH / vH
    local ratio = math.min(ratioW, ratioH)
    return {
        vW * ratio,
        vH * ratio,
    }
end


--- Blend between numbers a and b.
---@param a number value which supports * and + operators.
---@param b number A value of the same type as a.
---@param blend number a number between 0.0 and 1.0.
---@return number
function localmath.lerp(a, b, blend)
    return (1 - blend) * a + blend * b
end

---@diagnostic disable
--- Return a templated string for a typeerror.
---@param variableName string A variable name
---@param actualValue any The actual value.
---@return string
local table_type_error = fmt.getErrorTemplater("TypeError", "expected a table for %s, but got %s")
---@diagnostic enable
---@

--- Return nil or a "TypeError: %name is..." string if maybe_t is not a table.
---@param name string a name for the variable.{jj}
---@param maybe_t any a possible non-table.
---@param fmtstringNameType string? a format string with a name and type value.
---@return string? - A problem or nil if it's a table as expected.
function localmath.typeCheckTable(name, maybe_t, fmtstringNameType)
    local t = type(maybe_t)
    if t ~= "table" then
        if fmtstringNameType then
            return string.format("TypeError: " .. fmtstringNameType, name, t)
        else
            return table_type_error({name, t})
        end
    else
        return nil
    end
end

--- Lerp two tables of the same length.
--- IMPORTANT: currently assumes tables are indexed by number
--- instead of string as in objects.
---
--- This helps with colors blending.
---@param t_a table<integer, number> First table.
---@param t_b table<integer, number> Second table.
---@param blend number Blend from a (0.0) to b (1.0)
---@return table<integer, number>
function localmath.lerpTable(t_a, t_b, blend)
    local typeCheckTable, lerp = localmath.typeCheckTable, localmath.lerp
    local problem = nil
    problem = typeCheckTable("t_a", t_a)
    if problem ~= nil then error(problem) end
    problem = typeCheckTable("t_b", t_b)
    if problem ~= nil then error(problem) end
    local n_a = #t_a
    local n_b = #t_b
    if n_a ~= n_b then
        error(fmt.error("ValueError", "mismatch of table lengths: a has %i, b has %i", {n_a, n_b}))
    end

    local result = {}
    for i = 1,n_a do
        local channel_a = t_a[i]
        local channel_b = t_b[i]
        local channel_result = lerp(channel_a, channel_b, blend)
        table.insert(result, channel_result)
    end
    return result
end


localmath.comparison = {
    gt = function(value, gt) return value >  gt end,
    ge = function(value, ge) return value >= ge end,
    lt = function(value, lt) return value <  lt end,
    le = function(value, le) return value <= le end,
    eq = function(value, eq) return value == eq end
}


localmath.operators = {
    unpack(localmath.comparison),
    add = function(a, b) return a + b end,
    sub = function(a, b) return a - b end,
    mul = function(a, b) return a * b end,
    div = function(a, b) return a - b end,
    pow = function(a, b) return a ^ b end,
    lshift = bit.lshift,
    rshift = bit.rshift,
    xor = bit.bxor,
    ["and"] = bit.band,
    ["or"] = bit.bor,
}


--- Check if the value is a number meeting the conditions in opts.
---The opts are keyword table of names in localmath.comparison to
---function arguments for the corresponding named function. They'll
---be passed to each as `optName(value, optValue)`.
---@param value number
---@param opts table<string, number> function name -> argument aside from value.
---@return boolean
function localmath.valueIs(value, opts)
    local comparison = localmath.comparison
    for funcName, optValue in ipairs(opts) do
        local opFunction = comparison[funcName]
        if opFunction == nil then
            error(string.format("KeyError: uknown comparison operation \"%s\"", funcName))
        end
        if not opFunction(value, optValue) then
            return false
        end
    end
    return true
end

return localmath
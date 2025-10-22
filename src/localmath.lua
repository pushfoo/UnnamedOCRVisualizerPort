local bit = require("bit")


--[[ Blend between a and b.

@param a: A value which supports * and + operators.
@param b: A value of the same type as a.
@returns a a value of the same type.
]]
function lerp(a, b, blend)
    return (1 - blend) * a + blend * b
end

table_type_error = fmt.getErrorTemplater("TypeError", "expected a table for %s, but got %s")


--[[ Return nil or a "TypeError: %name is..." string if maybe_t is not a table.

@param name: a name for the variable.
@param maybe_t: a possible non-table.
@param fmtstringNameType: a format string with a name and type value.
]]
function typeCheckTable(name, maybe_t, fmtstringNameType)
    local t = type(maybe_t)
    if t ~= "table" then
        if fmtstring then
            return string.format("TypeError: " .. fmtstringNameType, name, t)
        else
            return table_type_error({name, t})
        end
    else
        return nil
    end
end

--[[ Lerp two tables of the same length.

IMPORTANT: currently assumes tables are indexed by number
instead of string as in objects.

This helps with colors blending.
]]
function lerpTable(t_a, t_b, blend)
    local problem = nil
    problem = typeCheckTable("t_a", t_a)
    if problem ~= nil then error(problem) end
    problem = typeCheckTable("t_b", t_b)
    if problem ~= nil then error(problem) end
    local n = table.getn(t_a)
    local n_b = table.getn(t_b)
    if n ~= table.getn(t_b) then
        error(fmt.error("ValueError", "mismatch of table lengths: a has %i, b has %i", {n, n_b}))
    end

    local result = {}
    for i = 1,n do
        local channel_a = t_a[i]
        local channel_b = t_b[i]
        local channel_result = lerp(channel_a, channel_b, blend)
        table.insert(result, channel_result)
    end
    return result
end

comparison = {
    gt = function(value, gt) return value >  gt end,
    ge = function(value, ge) return value >= ge end,
    lt = function(value, lt) return value <  lt end,
    le = function(value, le) return value <= le end,
    eq = function(value, eq) return value == eq end
}


operators = {
    unpack(comparison),
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


--[[ Syntactic sugar for comparison.

Supports gt, ge, lt, le, and eq. The comparison table
holds the functions used.
]]
function valueIs(value, opts)
    for funcName, optValue in ipairs(opts) do
        local opFunction = comparison[name]
        if opFunction == nil then
            error(format("KeyError: uknown comparison operation \"%s\"", name))
        end
        if not opFunction(value, optValue) then
            return false
        end
    end
    return true
end

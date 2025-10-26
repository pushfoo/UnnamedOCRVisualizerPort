local typechecks = {is = {}}

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

return typechecks
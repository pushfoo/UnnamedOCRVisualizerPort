--[[ Class and data structure primitives.

* super() helper function
* NewTable
* structures.Stack
]]
require("typechecks")

local structures = {}

--- Temp OOP helper.
---A review of current OOP systems since the last time I
---tried Love2D would help a lot. It looks like there may
---be some innovation since the last time I looked?
---@generic T_T
---@param self type<T_T>
---@param o table?
---@param parent table?
---@return T_T
function structures.super(self, o, parent)
    if o == nil then o = {} end
    setmetatable(o, parent or self)
    ---@diagnostic disable-next-line
    self.__index = self
    return o
end


--- Too-clever class-like objects (TODO: replace ASAP)
---@class Class
structures.Class = setmetatable({
        metaOnly = function(t, mt)
            t = t or {}
            mt = mt or {__index = table}
            t = setmetatable(t, mt)
            t.__index = t
            return t
        end,
        createSubtype = function(core, parent)

        end
    }, {
        -- Are we a function? Close enough.
        __call = function(self, t, mt)
            local created = structures.Class.metaOnly(t, mt)
            if created.new == nil then
                function created:new(o)
                    return setmetatable(o or {}, self)
                end
            end
            return created
        end
    }
)
local Class = structures.Class

-- A table with support for tableName:insert, etc.
---@generic T
---@class NiceArray<T> : table<integer, T>
structures.NiceArray = Class()

-- begin "trust me bro"
if structures.NiceArray.new == nil then
    ---@generic T
    ---@param o table<integer, T>|NiceArray<T>?
    ---@return NiceArray<T>
    function structures.NiceArray:new(o)
    ---@diagnostic disable-next-line
    end
end

if structures.NiceArray.insert == nil then
    ---@generic T
    ---@param self NiceArray<T>
    ---@param t T
    function structures.NiceArray:insert(t) end
end

if structures.NiceArray.concat == nil then
    ---@generic T
    ---@param self NiceArray<T>
    ---@param t T
    ---@return string
    function structures.NiceArray:concat(t)
    ---@diagnostic disable-next-line
    end
end
-- end "trust me bro"


--- Is length zero?
---@return boolean
function structures.NiceArray:isEmpty()
    return #self == 0
end


--- Extend from another array.
---@generic T
---@param self NiceArray<integer,T>
---@param array table<integer, T>|NiceArray<integer,T>
function structures.NiceArray:extend(array)
    if array ~= nil then
        for _, value in ipairs(array) do
            table.insert(self, value)
        end
    end
end


---@generic T
---@class Stack<integer,T> : NiceArray<integer,T>
structures.Stack = Class({}, {__index = structures.NiceArray})

-- begin: "trust me bro"
if structures.Stack.new == nil then
    ---@generic T
    ---@param o table<integer,T>|NiceArray<integer,T>?
    ---@return Stack<T>
    function structures.Stack:new(o)
    ---@diagnostic disable-next-line
    end
end
-- end: "trust me bro"

---@generic T
---@param self Stack<T>
---@return T?
function structures.Stack:peek()
    local n = #self
    local peeked = nil
    if n > 0 then
        peeked = self[n]
    end
    return peeked
end

---@generic T
---@param self Stack<T>
---@param item T
---@return nil
function structures.Stack:push(item)
    table.insert(self, item)
end

---@generic T
---@param self Stack<T>
---@return T?
function structures.Stack:pop()
    if #self == 0 then
        error("structures.StackUnderflow: can't pop from empty stack!")
    end
    local n = self:getn()
    local popped = self[n]
    self[n] = nil
    return popped
end


return structures
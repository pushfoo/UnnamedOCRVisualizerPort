--[[ Class and data structure primitives.

* super() helper function
* NewTable
* structures.Stack
]]
local class = require "lib.middleclass"

local structures = {}

--- Q: is this better for struct-likes with defaults?
---
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


--- Smaller and simpler than middleclass or similar.
function structures.struct(self, overrides)
    local interior = {}
    if overrides then
        for k, v in pairs(overrides) do interior[k] = v end
    end
    self.__index = self
    return setmetatable(interior, self)
end

local function _metaOnly(t, mt)
    t = t or {}
    mt = mt or {__index = table}
    t.__index = t
    return setmetatable(t, mt)
end

local _mt = {}
function _mt:__call(t, mt)
    local created = _metaOnly(t, mt)
    if created.new == nil then
        function created:new(o)
            return setmetatable(o or {}, self)
        end
    end
    return created
end

--- Too-clever class-like objects (legacy)
---@class _Class
local _Class = setmetatable({metaOnly = _metaOnly}, _mt)


-- A table with support for tableName:insert, etc.
---@generic T
---@class NiceArray<T> : table<integer, T>
NiceArray = _Class()


-- begin "trust me bro"
if NiceArray.new == nil then
    ---@generic T
    ---@param o table<integer, T>|NiceArray<T>?
    ---@return NiceArray<T>
    function NiceArray:new(o)
    ---@diagnostic disable-next-line
    end
end


if NiceArray.insert == nil then
    ---@generic T
    ---@param self NiceArray<T>
    ---@param t T
    function NiceArray:insert(t) end
end


if NiceArray.concat == nil then
    ---@generic T
    ---@param self NiceArray<T>
    ---@param t T
    ---@return string
    function NiceArray:concat(t)
    ---@diagnostic disable-next-line
    end
end
-- end "trust me bro"


--- Is length zero?
---@return boolean
function NiceArray:isEmpty()
    return #self == 0
end


--- Extend from another array.
---@generic T
---@param self NiceArray<integer,T>
---@param array table<integer, T>|NiceArray<integer,T>
function NiceArray:extend(array)
    if array ~= nil then
        for _, value in ipairs(array) do
            table.insert(self, value)
        end
    end
end

structures.NiceArray = NiceArray


local Collection = class('Collection')
structures.Collection = Collection

function Collection:initialize(items)
    local _items = {}
    if items then
        if type(items) ~= 'table' then
            error("TypeError: passed items must be arrays.")
        end
        for _, value in ipairs(items) do
            table.insert(_items, value)
        end
    end
    self._items = _items
end

function Collection:insert(value)
    error("AbstractMethod: Collection:insert is abstract, please override it to insert value=" .. tostring(value))
end

function Collection:getn()
    return #(self._items)
end

function Collection:isEmpty()
    local n = #(self._items)
    return n == 0
end

function Collection:toPlainTable()
    error("AbstractMethod: Collection:toPlainTable() is abstract, please override it to convert to a plain table.")
end


-- Skip copying the inner table and get a table:concat(sep) directly.
---@param sep string a separator value.
---@return string
function Collection:concat(sep)
   return table.concat(self._items, sep)
end



local Set = Collection:subclass('Set')

structures.Set = Set

function Set:initialize(collection)
    Collection:initialize(collection)
end

function Set:has(item)
    return self._items[item] == true
end


function Set:insert(item)
    local items = self._items
    if not items[item] then
        items[item] = true
        return true
    end
    return false
end

function Set:remove(item)
    local items = self._items
    if self:has(item) then
        items[item] = false
        return true
    end
    return false
end

function Set:toPlainTable()
    local t = {}
    for item, _ in pairs(self._items) do
        t:insert(item)
    end
    return t
end

local Queue = Collection:subclass('Queue')
structures.Queue = Queue


function Queue:insert(item)
    table.insert(self._items, item)
end

function Queue:append(item)
    self._items:insert(item)
end

function Queue:peekNext()
    return self._items[1]
end


function Queue:getNext()
    local _items = self._items
    return table.remove(_items, 1)
end



local BasePool = class('Pool')

function BasePool:initialize()
    self._idle = Queue:new()
    self._busy = Set:new()
    self._pool = Set:new()
end

-- Override this for specific resource types.
-- IMPORTANT: This ONLY creates the value!
function BasePool:_createNew()
    error("AbstractMethod: BasePool:_createNew() is abstract, please implement it.")
end

function BasePool:getNext()
    local nextItem = self._idle:getNext()
    if nextItem == nil then
        nextItem = self:_createNew()
        self._pool:insert(nextItem)
        self._busy:insert(nextItem)
    end
    return nextItem
end

function BasePool:putBack(item)
    local pool = self._pool
    if not pool:has(item) then
        error("KeyError: item , but got item=" .. tostring(item))
    end
    return (
        self._busy:remove(item)
        and self._idle:insert(item)
    )
end


local IdPool = BasePool:subclass('IntPool')

function IdPool:_createNew()
    return #(self._pool) + 1
end


---@generic T
---@class Stack<integer,T> : NiceArray<integer,T>
local Stack = Collection:subclass('Stack')
structures.Stack = Stack

-- -- begin: "trust me bro"
-- if structures.Stack.new == nil then
--     ---@generic T
--     ---@param o table<integer,T>|NiceArray<integer,T>?
--     ---@return Stack<T>
--     function structures.Stack:new(o)
--     ---@diagnostic disable-next-line
--     end
-- end
-- -- end: "trust me bro"

---@generic T
---@param self Stack<T>
---@return T?
function Stack:peek()
    ---@diagnostic disable-next-line
    local items = self._items
    local n = #items
    if n > 0 then
        return items[n]
    end
end

---@generic T
---@param self Stack<T>
---@param item T
---@return nil
function Stack:push(item)
    ---@diagnostic disable-next-line
    table.insert(self._items, item)
end

---@generic T
---@param self Stack<T>
---@return T?
function Stack:pop()
    ---@diagnostic disable-next-line
    local items = self._items
    local n = #items
    if n < 1 then
        error("structures.StackUnderflow: can't pop from empty stack!")
    end
    return table.remove(items, n)
end


return structures
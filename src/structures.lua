--[[ Class and data structure primitives.

* super() helper function
* NewTable
* structures.Stack
]]
local class = require "lib.middleclass"

local structures = {}
local ERR_TEMPLATES = {}
structures.ERR_TEMPLATES = ERR_TEMPLATES

local pretty = {}
structures.pretty = pretty

---Try to ez pretty prent a single item (handles tables poorly)
---@param v any value
---@return string
local function _prettyItem(v)
    if v == nil then
        return 'nil'
    end
    local T_v = type(v)
    if T_v == 'string' then
        return "'" .. v .. "'"
    end
    return tostring(v)
end
pretty.item = _prettyItem

---An array table of {k,v} format.
---@param pair table
---@return string
local function _prettyPair(pair)
    local kP = _prettyItem(pair[1])
    local _v = pair[2]
    local vP = nil
    if type(_v) == 'table' then
        vP = tostring(vP)
    else
        vP = _prettyItem(vP)
    end
    local f = string.format("{%s=%s}", kP, vP)
    return f
end
pretty.pair = _prettyPair

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


local Collection = class('Collection')
structures.Collection = Collection


---comment
---@generic K
---@generic V
---@param items table<K,V>?
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

---Add the item to the collection.
---@AbstractMethod
---@generic V
---@param value V
function Collection:insert(value)
    error("AbstractMethod: Collection:insert is abstract, please override it to insert value=" .. tostring(value))
end

---Wraps internal indexed storage.
---@return integer
function Collection:getn()
    return #(self._items)
end

---Whether the the number of items is zero.
---@return boolean
function Collection:isEmpty()
    local n = #(self._items)
    return n == 0
end

---@AbstractMethod
---@generic K
---@generic V
---@return table<integer, table<K,V>>
function Collection:toPlainTable()
    error("AbstractMethod: Collection:toPlainTable() is abstract, please override it to convert to a plain table.")
end


-- Skip copying the inner table and get a table:concat(sep) directly.
---@param sep string? a separator value.
---@return string
function Collection:concat(sep)
   return table.concat(self._items, sep)
end


---A bidirectional K <-> V map.
local BiMap = Collection:subclass('BiMap')
ERR_TEMPLATES.BIMAP_MEMBER_CONFLICT = 'ConflictError: BiMap has a member named %s'



function BiMap:initialize(elements)
    Collection.initialize(self)
    local keyToIndex = {}
    local valueToIndex = {}
    local insertionOrder = self._items

    self.keyToIndex = keyToIndex
    self.valueToIndex = valueToIndex
    local function _dupeFmt(what, k, v, oldK, oldV)
        return string.format(
            "DuplicateError: %s in (%s=%s) already exists (%s=%s)",
            what, k, v, oldK, oldV
        )
    end
    self.nPairs = 0
    local function _addTo(k, v)
        if k == nil and v == nil then
            return
        end
        if BiMap[k] ~= nil then
            error(string.format(
                ERR_TEMPLATES.BIMAP_MEMBER_CONFLICT, tostring(k))
            )
        end
        local oldKeyIndex = keyToIndex[v]
        local oldValueIndex = keyToIndex[k]
        if oldKeyIndex ~= nil then
            local oldK = insertionOrder[oldKeyIndex]
            error(_dupeFmt('value', k, v, oldK, v))
        elseif oldValueIndex then
            local oldV = insertionOrder[oldValueIndex]
            error(_dupeFmt('key', k, v, k, oldV))
        end
        local asPair = {k, v}
        table.insert(insertionOrder, asPair)
        local n = self.nPairs + 1

        keyToIndex[k] = n
        valueToIndex[v] = n
        self.nPairs = n

        return true
    end

    self._addTo = _addTo
    if elements then
        for k, v in pairs(elements) do
            _addTo(k, v)
        end
    end
end


function BiMap:concat(sep)
    sep = sep or ", "
    local preprocessed = {}
    for pair in self._items do
        local k = pair[1]
        local v = pair[2]
        table.insert(preprocessed, string.format("{%s, %v}", k, v))
    end
    return table.concat(preprocessed, sep)
end


ERR_TEMPLATES.BIMAP_ARG_FORMAT = '%s: must be {k, v} with #t == 2'
local function _pairerr(errType)
    return string.format(ERR_TEMPLATES.BIMAP_ARG_FORMAT, errType)
end


---Insert a {k, v} pair into the bimap (MUST have #t == 2).
---The restriction is due to ambiguity in how lua handles
---indices for values.For example, this is 1-length table:
---```lua
---{[1]='#t==1'} -- Equivalent to {'#t==1'}
---```
---@param kVTable any
function BiMap:insert(kVTable)
    local k, v = nil, nil
    if type(kVTable) ~= 'table' then
        error(_pairerr('TypeError'))
    elseif #kVTable ~= 2 then
        print("bmap", table.concat(kVTable, ", "))
        error(_pairerr('ValueError'))
    end
    self._addTo(kVTable[1], kVTable[2])
end

function BiMap:__index(key)
    return self:getValueForKey(key)
end

---Internal helper.
---@param index integer
---@generic K
---@generic V
---@return K?
---@return V?
function BiMap:_getPairForIndex(index)
    local k, v = nil, nil
    local pair = nil
    if index ~= nil then
        pair = self._items[index]
    end
    if pair then
        k = pair[1]
        v = pair[2]
    end
    return k, v
end

---comment
---@param keyOrValue any
---@generic K
---@generic V
---@return K?,V?
function BiMap:getPairFor(keyOrValue)
    local index = (
        self.keyToIndex[keyOrValue]
        or self.valueToIndex[keyOrValue]
    )
    return self:_getPairForIndex(index)
end

---@generic K
---@generic V
---@param value V?
---@return K,V|nil,nil
function BiMap:getPairForValue(value)
    local index = self.valueToIndex[value]
    return self:_getPairForIndex(index)
end

---comment
---@generic K
---@generic V
---@param key K
---@return K?,V?
function BiMap:getPairForKey(key)
    local index = self.keyToIndex[key]
    return self:_getPairForIndex(index)
end

---comment
---@generic V
---@param key any
---@return V?
function BiMap:getValueForKey(key)
    local index = self.keyToIndex[key]
    local _, value = self:_getPairForIndex(index)
    return value
end


function BiMap:getKeyForValue(value)
    local index = self.valueToIndex[value]
    local key, _ = self:_getPairForIndex(index)
    return key
end


function BiMap:has(keyOrValue)
    if self.keyToIndex[keyOrValue] ~= nil then
        return true
    elseif self.nameToIndex[keyOrValue] ~= nil then
        return true
    end
    return false
end


function BiMap:_removeByIndex(index)
    local pair = table.remove(self._items, index)
    local k, v = nil, nil
    if pair then
        k = pair[1]
        self.keyToIndex[k] = nil
        v = pair[2]
        self.valueToIndex[v] = nil
    end
    return k,v
end


function BiMap:removePair(k, v)
    local keyToIndex = self.keyToIndex
    local valueToIndex = self.valueToIndex
    local byKey = keyToIndex[k]
    local byValue = valueToIndex[v]
    if byKey ~= nil and byKey == byValue then
        return self:_removeByIndex(byKey)
    else
        return nil,nil
    end
end



function BiMap:removePairForKey(k)
    local index = self.keyToIndex[k]
    return self:_removeByIndex(index)
end


function BiMap:removePairForValue(v)
    local index = self.valueToIndex[v]
    return self._removeByIndex(index)
end


function BiMap:__pairs()
    local t = self._items
    local n = #t
    local i = 0
    return ipairs(self._items)
    --     i = i + 1

    --     if i <= n then
    --         local pair = t[i]
    --         local k = pair[1]
    --         local v = pair[2]
    --         if k ~= nil and ~k ~= v then
    --             return k, v
    --         end
    --     end
    -- end
    -- return it
end

structures.BiMap = BiMap




--- Too-clever class-like objects (legacy)
---@class _Class
local _Class = setmetatable({metaOnly = _metaOnly}, _mt)


-- A table with support for tableName:insert, etc.
---@generic T
---@class NiceArray<T> : table<integer, T>
local NiceArray = _Class()
structures.NiceArray = NiceArray

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




local Set = Collection:subclass('Set')

structures.Set = Set

function Set:initialize(collection)
    Collection:initialize(collection)
end

function Set:has(item)
    local items = self._items
    for k, v in pairs(items) do
        print("-h", item, "?", k , v)
    end
    local haveItem = items[item]
    print("setask", item, haveItem)
    return haveItem ~= nil
end


function Set:insert(item)
    local items = self._items
    if items[item] ~= true then
        items[item] = true
        return true
    end
    return false
end

function Set:remove(item)
    local items = self._items
    if self:has(item) then
        items[item] = nil
        return true
    end
    return false
end

function Set:toPlainTable()
    local t = {}
    for item, _ in pairs(self._items) do
        table.insert(t, item)
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
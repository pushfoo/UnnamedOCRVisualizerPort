--[[ Class and data structure primitives.

* super() helper function
* NewTable
* Stack
]]
require("typechecks")

--[[ Temp OOP helper.

A review of current OOP systems since the last time I
tried Love2D would help a lot. It looks like there may
be some innovation since the last time I looked?
]]
function super(self, o, parent)
    if o == nil then o = {} end
    setmetatable(o, parent or self)
    self.__index = self
    return o
end



Class = setmetatable({
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
            local created = Class.metaOnly(t, mt)
            function created:new(o)
                return setmetatable(o or {}, self)
            end
            return created
        end
    }
)


-- A table with support for tableName:insert, etc.
NiceTable = Class()

function NiceTable:isEmpty()
    return self:getn() == 0
end

function NiceTable:extend(array)
    if array == nil then
        return
    end
    for i, value in ipairs(array) do
        self:insert(value)
    end
end

Stack = Class({}, {__index = NiceTable})


-- function Stack:new(o)
--     return setmetatable(o or {}, self)
--     o = super(self, o)
--     return o
-- end

-- function Stack:getn()
--     return table.getn(self)
-- end

function Stack:peek()
    local n = self:getn()
    local peeked = nil
    if n > 0 then
        peeked = self[n]
    end
    return peeked
end

-- function Stack:isEmpty()
--     return self:getn() == 0
-- end

-- function Stack:isFull()
--     local maxsize = self.maxsize
--     local n = self:getn()
--     if maxsize then
--         return n >= maxsize
--     else
--         return false
--     end
-- end


function Stack:push(item)
    -- if self:isFull() then
    --     local maxsize = self.maxsize
    --     error(string.format("StackOverflow: stack already at maxsize=%i", maxsize))
    -- end
    local contents = self._contents
    contents:insert(item)
end


function Stack:pop()
    if self:isEmpty() then
        error("StackUnderflow: can't pop from empty stack!")
    end
    local popped = self[self:getn()]
    contents[n] = nil
    return popped
end


Set = Class()

function Set:new(o)
    return setmetatable(o or {}, self)
end

function Set:has(item)
    return self[item] == true
end

function Set:add(item)
    if self:has(item) == false then
        self[item] = true
    end
end

function Set:remove(item)
    if self[item] ~= nil then
        self[item] = nil
    end
end


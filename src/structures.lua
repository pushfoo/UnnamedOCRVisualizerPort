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


--[[ Create a class-like object.

This is just bordering on too-clever.
]]
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
            if created.new == nil then
                function created:new(o)
                    return setmetatable(o or {}, self)
                end
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
    for _, value in ipairs(array) do
        self:insert(value)
    end
end


Stack = Class({}, {__index = NiceTable})


function Stack:peek()
    local n = self:getn()
    local peeked = nil
    if n > 0 then
        peeked = self[n]
    end
    return peeked
end


function Stack:push(item)
    self:insert(item)
end


function Stack:pop()
    if self:isEmpty() then
        error("StackUnderflow: can't pop from empty stack!")
    end
    local n = self:getn()
    local popped = self[n]
    self[n] = nil
    return popped
end

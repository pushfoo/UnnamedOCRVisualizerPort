local BiMap = require("structures").BiMap


local enum = {}

local _current = nil
local _defaults = {}
local _bimaps = {}
local _typesets = {}
local _names = {}


function enum.begin(name)
    if _current then
        error("EnumError: already started an enum named " .. name)
    end
    _current = {
        default = nil,
        name = name
    }
end


---@generic E
---@param first E
---@return E
function enum.default(first)
    if _current == nil then
        error("No current enum?")
    end
    local d = _current.default
    if d ~= nil then
        error(string.format("Already have a default %s, but got %s", d, first))
    end
    _current.default = first
    return first
end


local Enum = {}

local function _fmtMsg(enumName, problemType, value, typeSet)
    local names = {}
    for typeName, _ in pairs(typeSet) do
        table.insert(names, typeName)
    end
    local typestring = table.concat(names, ", ")
    local msg = string.format(
        "%s: value=%s is not a member of %s, must be one of %s",
        problemType, value, enumName, typestring
    )
    return msg
end

---@generic E
---@return E?
function Enum:getDefault()
    return _defaults[self]
end


---@generic E
---@param value E?
---@return E?,string?
function Enum:getValidated(value)
    if value == nil then
        return _defaults[self]
    end
    local typeSet = _typesets[self]
    local bimap = _bimaps[self]
    local problem = nil
    if typeSet[value] == nil then
        problem = "TypeError"
    elseif not (bimap:hasValue(value)) then
        problem = "ValueError"
    end
    if problem then
        local msg = _fmtMsg(_names[self], problem, value, typeSet)
        return nil,msg
    end
    return value
end

function enum.close(enumTable)
    if type(enumTable) ~= 'table' then
        error('TypeError: closing an enum acts on the table, not the name')
    end
    if _current == nil then
        error("No Enum in progress?")
    end
    _defaults[enumTable] = _current.default
    local b = BiMap:new()
    local typeSet = {}
    for k ,v in pairs(enumTable) do
        if k == nil then
            error('TypeError: k=nil')
        elseif v == nil then
            error('TypeError: v=nil')
        end
        typeSet[type(v)] = true
        b:insert({k, v})
    end
    _bimaps[enumTable] = b
    _typesets[enumTable] = typeSet
    local mt =  {__index = Enum, __newindex= function (self, k, v)
        local name = _names[self]
        error(string.format(
            "ImmutableError: cannot set %s=%s on enum %s as it is ImmutableError.",
            name, k, v))
    end
    }
    setmetatable(enumTable, mt)
    _current = nil
    return enumTable
end

enum.Enum = Enum

return enum
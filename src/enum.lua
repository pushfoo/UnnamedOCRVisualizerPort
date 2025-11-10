local structures = require("structures")
local BiMap, Set = structures.BiMap, structures.Set

local class = require("lib.middleclass")


local enum = {}

-- Externally stored to avoid scaring Lua LS (it is not very reliable)
local _defaults = {}
local _bimaps   = {}
local _typesets = {}
local _names    = {}


--- A wrapper for defaults.
---@generic V
---@alias V V
---@class Default<V>
---@field value V
local Default = class('Default')
enum.Default = Default

function Default:initialize(value)
    self.value = value
end


---@param maybeDefault Default<V>|V
---@return V
function Default.unwrap(maybeDefault)
    if maybeDefault == nil then
        error("TypeError: cannot unwrap a nil")
    end
    if type(maybeDefault) ~= 'table' then
        return maybeDefault
    else
        return maybeDefault.value
    end
end


function Default:__tostring()
    return string.format("Instance of Default (wraps %s)", tostring(self.value))
end


---@class Enum
local Enum = {}
enum.Enum = Enum


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

--- Get any default value for this specific enum
---@generic E
---@return E?
function Enum:getDefault()
    return _defaults[self]
end


--- Get a value or nil + an error string.
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


--- A "block" table which accepts assignement of tables.
---@class EnumBlock
local EnumBlock = {}
local _ENUM_NAME_TEMPLATE = "%s: enum names must be a non-empty string, not %s"


function EnumBlock:new(o)
     o = o or {}
     if o.__index == nil then
        o.__index = self
     end
     return setmetatable(o, EnumBlock)
end

---comment
---@param packageTable table<string, any>
---@return EnumBlock
function enum.createBlockOnPackage(packageTable)
    if packageTable.enums ~= nil then
        local T_packageTable = type(packageTable)
        if T_packageTable ~= 'table' then
            error(string.format("TypeError: expected package table, but got a %s (%s)",
                T_packageTable, tostring(packageTable)
            ))
        else
            error("ValueError: already has an enums value?")
        end
    end

    local enums = EnumBlock:new{parent=packageTable}
    packageTable.enums = enums
    return enums
end


function enum.finalizeEnum(enumTable)
    local T_enumTable = type(enumTable)
    if T_enumTable ~= "table" then problem = "TypeError" end
    if problem then error(string.format("%s: enumTable must be a table, but got v=%s", problem, T_enumTable)) end

    local bimap = BiMap:new()
    local typeSet = Set:new()
    local default = nil
    local default_name = nil

    -- _defaults[enumTable] = _current.default
    for enum_k, enum_v in pairs(enumTable) do
        if enum_k == nil then
            error('TypeError: k=nil')
        elseif enum_v == nil then
            error('TypeError: v=nil')
        end
        local useValue = Default.unwrap(enum_v)
        -- print("dec", enum_k, enum_v, useValue)
        if type(enum_v) == 'table' then
            if default ~= nil then
                error(string.format(
                    "ConflictError: cannot set default as %s = %s (already have a default %s = %s)",
                    enum_k, tostring(enum_v), default_name, tostring(default)
                ))
            end
            default_name = enum_k
            default = useValue
        end
        if useValue == nil then
            error(string.format("TypeError: Unexpected %s=nil", enum_k))
        end
        typeSet:insert(type(useValue))
        bimap:insert({enum_k, useValue})
    end
    if default_name ~= nil then
        enumTable[default_name] = default
    end

    local mt = {
        __index = Enum,
        __newindex= function (self, index_k, index_v)
            local reportingName = _names[self]
            local descriptiveName = nil
            if reportingName == nil then
                descriptiveName = "Anonymous Enum"
            else
                descriptiveName = "Enum " .. reportingName
            end

            error(string.format(
                "ImmutableError: %s cannot set %s=%s on as it is immutable.",
                descriptiveName, index_k, tostring(index_v))
            )
        end
    }

    setmetatable(enumTable, mt)
    _bimaps[enumTable] = bimap
    _typesets[enumTable] = typeSet
    if default_name then
        _defaults[enumTable] = default
    end

    return enumTable
end

---Convert a table to an enum on assignment.
---@param k any
---@param v any
function EnumBlock:__newindex(k, v)
    local problem = nil
    if     type(k) ~= "string" then problem = "TypeError"
    elseif k == ""             then problem = "ValueError" end
    if problem then
        error(string.format(_ENUM_NAME_TEMPLATE, problem, tostring(v)))
    end

    local enumTable
    if _typesets[enumTable] == nil then
        enumTable = enum.finalizeEnum(v)
    else
        enumTable = v
    end
    _names[enumTable] = k

    rawset(self, k, enumTable)
end


return enum
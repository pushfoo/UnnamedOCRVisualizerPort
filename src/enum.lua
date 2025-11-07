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

---Calculate a write target and error for the given maybe-table + name.
---@generic V
---@param maybePackageTable table<string, any>?
---@param writtenItemName string?
---@return table<string,any>?,string?
function _getDestination(maybePackageTable, writtenItemName)
    local dest = nil
    local err = nil

    if maybePackageTable ~= nil then
        if writtenItemName == nil then
            err = "TypeError: name mandatory when package name provided!"
        else
            local T_destination = type(maybePackageTable)
            if T_destination ~= 'table' then
                local nameStub = ""
                if writtenItemName ~= nil then
                    nameStub = " for " .. writtenItemName
                    err = string.format(maybePackageTable,
                        "TypeError: expected package table %s, but got %s",
                        nameStub, T_destination
                    )
                end
            else
                dest = maybePackageTable
            end
        end
    end
    return dest,err
end


function enum.close(enumTable, maybeDestinationModule)
    if type(enumTable) ~= 'table' then
        error('TypeError: closing an enum acts on the table, not the name')
    end
    if _current == nil then
        error("No Enum in progress?")
    end

    local reportingName = _current.name
    if _current.name == nil then
        reportingName = "anonymous Enum"
    else
        reportingName = "Enum" .. reportingName
    end
    local dest,err = _getDestination(
        maybeDestinationModule, reportingName)
    if err then error(err) end

    _names[enumTable] = _current.name
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
    local mt = {
        __index = Enum,
        __newindex= function (self, k, v)
            error(string.format(
                "ImmutableError: cannot set %s=%s on as it is ImmutableError.",
                reportingName, k, v))
        end
    }
    setmetatable(enumTable, mt)
    if dest then
        dest[_current.name] = enumTable
    end
    _current = nil
    return enumTable
end


return enum
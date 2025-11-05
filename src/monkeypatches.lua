---[[ Monkeypatch nice features into the global space.
---
--- ]]
local monkeypatches = {}

-- Original functions
---@constant
local originals = --[[@as table<string, any>]] {}
monkeypatches.originals = originals



---Get an error reason for lua name or nil.
---@param name any
---@return string?
function monkeypatches.checkLuaName(name)
    if type(name) ~= 'string' then
       return string.format("TypeError: name=%s, but expected a string", name)
    end
    local bad = string.find(name, "[^_%a%d]")
    if bad then
        return string.format("ValueError: name[%i]=\'%s\'", bad, name:sub(bad, bad))
    end
end




local looksLike = {}

function looksLike.callable(f)
    if f == nil then
        return false
    end
    return type(f) == 'function' or f.__call ~= nil
end

function looksLike.attrsFailToMatch(item, nameToStringOrPredicate)
    local looksCallable = looksLike.callable
    local T_nameToStringOrPredicate
    if T_nameToStringOrPredicate ~= "table" then
        error("TypeError: expected table, not nameToStringOrPredicate=" .. T_nameToStringOrPredicate)
    end
    for name, typeNameOrPredicate in pairs(nameToStringOrPredicate) do
        local value = item[name]
        local T_typeNameOrPredicate = type(typeNameOrPredicate)
        if T_typeNameOrPredicate == "string" then
            local T_actualType = type(value)
            ---@cast typeNameOrPredicate string
            if T_actualType ~= typeNameOrPredicate then
                local asString = tostring(value)
                local mtAsString = tostring(getmetatable(value))
                return string.format(
                    "expected %s to be a %s, but got %s (type %s, metatable %s)",
                    name, T_typeNameOrPredicate, asString, T_actualType, mtAsString
                )
            end
        elseif looksCallable(typeNameOrPredicate) then
            if typeNameOrPredicate(value) == false then
                return string.format(
                    "attr %s=%s does not match predicate %s",
                    name, tostring(value), tostring(typeNameOrPredicate)
                )
            end
        else
            error(string.format(
                "TypeError: attrsFailToMatch got invalid value in pair ['%s']=%s (neither string nor callable predicate)",
                name, T_typeNameOrPredicate
            ))
        end
    end
    return nil
end


function looksLike.lacksFunctions(item, names)
    if item == nil then return false end
    for _, name in ipairs(names) do
        local value = item[name]
        if not looksLike.callable(value) then
            return string.format("name '%s' (i=%i) is not a callable")
        end
    end
    return nil
end

-- Each instance checks & patches when monkeypatches.applyPatches is called.
---@class AutoPatcher
local AutoPatcher = {from='unknown', parent=nil}

function AutoPatcher:check()
    error("NotImplementedError: override this?")
end

function AutoPatcher:patch()
    error("NotImplementedError: override this?")
end

function AutoPatcher:new(name, added, parent)
    local o = {
        name=name,
        added=added,
        parent=parent
    }
    o = setmetatable(o, AutoPatcher)
    if parent then
        self.parent = parent
    end
    return o
end


local PatchList = {__index = table}
function PatchList:new(o)
    o = o or {}
    self.__index = self
    return setmetatable(o, self)
end

monkeypatches.PatchList = PatchList

function PatchList:createChild(name, added)
    local child = PatchList:new({
        name = name,
        added = added,
        parent = self
    })
    table.insert(self, child)
    return child
end


function PatchList:newPatcher(name, added)
    local patcher = AutoPatcher:new(name, added, self)
    table.insert(self, patcher)
    return patcher
end

local rootPatchList = PatchList:new()
monkeypatches.rootPatchList = rootPatchList

local lua_5_2_iteration = rootPatchList:createChild('iteration', 'Lua 5.2')


--- Permits defining table:__ipairs metamethods.
local Patch_ipairs = lua_5_2_iteration:newPatcher('ipairs', 'Lua 5.2')

function Patch_ipairs.patch()
    originals.ipairs = ipairs
    local _ipairs = ipairs
    function ipairs(iterable)
        if iterable and iterable.__ipairs then
            return iterable.__ipairs()
        end
        return _ipairs(iterable)
    end
end

function Patch_ipairs.check()
    local _mt = {}
    function _mt:__ipairs()
        self.index = 0
        return function()
            self.index = self.index + 1
            if self.index <= 1 then
                return self.index, self.index
            end
        end
    end
    local ipairsTry = setmetatable({}, _mt)
    for _, _ in ipairs(ipairsTry) do
        return false
    end
    return true
end


--- Permits custom.__pairs() metamethod for pairs()
local Patch_pairs = lua_5_2_iteration:newPatcher('pairs', 'Lua 5.2')

function Patch_pairs.patch()
    originals.pairs = pairs
    local _ipairs = ipairs
    function ipairs(iterable)
        if iterable and iterable.__ipairs then
            return iterable.__ipairs()
        end
        return _ipairs(iterable)
    end
end


function Patch_pairs.check()
    local _mt = {}
    function _mt:__pairs()
        self.index = 0
        return function()
            self.index = self.index + 1
            if self.index <= 1 then
                return self.index, self.index
            end
        end
    end
    local ipairsTry = setmetatable({}, _mt)
    for _, _ in pairs(ipairsTry) do
        return false
    end
    return true
end


function monkeypatches.applyPatches(nameToPatcher)
    local toPatch = nameToPatcher or rootPatchList
    for i, patcherOrList in ipairs(toPatch) do
        local name = patcherOrList.name
        local mt = getmetatable(patcherOrList)
        if mt == PatchList then
            monkeypatches.applyPatches(patcherOrList)
        elseif patcherOrList.check() then
            local patcher = patcherOrList
            print(string.format(
                "Attemping patch for name='%s' from='%s'...", name, patcher.added
            ))
            patcher.patch()
            if patcher.check() == false then
                error(string.format("PatchError: '%s' failed to take.", name))
            end
            if originals[name] then
                print(string.format(
                "   Done! (backup in monkeypatches.originals['%s'])", name
                ))
            else
                error("PatchError: patcher failed to back up original value.")
            end
        end
    end
end

return monkeypatches

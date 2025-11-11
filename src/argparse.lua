local util = require("util")
local firstChar = util.firstChar
local startsWith = util.startsWith
local NiceArray = require("structures").NiceArray


local argparse = {}


---True if type(s) == 'string' of length > 2.
---IMPORTANT: Treats valid negative numbers as flags, i.e. -1.
---@param str any
---@param permitNumber boolean?
---@return boolean
local function isFlag(str, permitNumber)
    if permitNumber == nil then permitNumber = false end
    local T_str = type(str)
    if T_str ~= 'string' then
        error(string.format('TypeError: expected a string, but got str=%s (a %s)', str, T_str))
    elseif string.len(str) < 2 then
        return false
    end
    return (not permitNumber and firstChar(str) == '-')
end
argparse.isFlag = isFlag


---Extract -sf or similar into split flags.
---
---The flags above would be expanded into three
---separate flags: --long-flags, -s, and -f. The
---tables have the following values:
---1. flag : 'long' | 'short'
---2. value : strips left '-'
---3. expanded: string as if it were a stand-alone flag
---@param s string
---@return NiceArray<table<string,string>>
local function splitFlagsInToken(s)
    local long = startsWith(s, '--')
    local flags = NiceArray:new()
    if long then
        flags:insert({
            flag = 'long',
            value = s:sub(2, #s),
            expanded = s
        })
    else
        for i = 2,#s do
            local oneChar = s:sub(i,i)
            flags:insert({
                flag = 'short',
                value = oneChar,
                expanded  = '-' .. oneChar
            })
        end
    end
    return flags
end
argparse.splitFlagInToken = splitFlagsInToken


---Get an in-order series of flag and argument objects.
---IMPORTANT: Assumes no negative integers will be passed.
---@param source table<integer,string>
---@return NiceArray<table<string,string>|string>
local function expandFlagTokens(source)
    local items = NiceArray:new()
    for i, v in ipairs(source) do
        if isFlag(v) then
            local group = splitFlagsInToken(v)
            for _, flag in ipairs(group) do
                items:insert(flag)
            end
        else
            items:insert(v)
        end
    end
    return items
end
argparse.expandFlagTokens = expandFlagTokens


---Get a simplified iterator-like function over tokens.
---The function returns either:
---* token,integer when tokens are available
---* nil,nil when they are exhausted
---@param parsed table<integer,string|table<string,string>>
---@return function
local function iteratorOverTokens(parsed)
    local cur = 0
    local function nextItem()
        cur = cur + 1
        if cur <= #parsed then
            return parsed[cur],cur
        else
            return nil,nil
        end
    end
    return nextItem
end
argparse.iteratorOverTokens = iteratorOverTokens


---Parse a single number from the iterator function.
---IMPORTANT: May handle negatives, but flag parsing does not yet.
---@param nextPair function
---@param name string?
---@return number?,string?
local function parseNumber(nextPair, name)
    local raw, i = nextPair()
    local err = nil
    local dim = tonumber(raw)
    if dim == nil then
        local nameExpanded = " "
        if name then
            nameExpanded = name .. " "
        end
        err = string.format(
            "ParseError: failed to parse %sat index=%s from '%s'",
            nameExpanded , tostring(i), tostring(raw)
        )
    end
    return dim,err
end
argparse.parseNumber = parseNumber


---Parse the next two tokens as numbers.
---@param nextPair function
---@param name string?
---@return table<integer, number>?,string?
local function parseSize(nextPair, name)
    name = name or 'size'
    -- TODO: use pcall or xpcall for this
    local width,errW = parseNumber(nextPair, name .. '.width')
    if errW then
        return nil,errW
    end
    local height,errH = parseNumber(nextPair, name .. '.height')
    if errH then
        return nil,errH
    end
    return {width, height},nil
end
argparse.parseSize = parseSize



return argparse

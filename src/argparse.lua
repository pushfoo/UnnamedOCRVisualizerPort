local class = require "lib.middleclass"
local env = require "env"
local fmt = require("fmt")
local util = require("util")
local firstChar = util.firstChar

local errors = fmt.errors

local argparse = {}

love.filesystem.setSymlinksEnabled(true)


local function isFlag(s)
    if string.len(s) < 2 then
        return false
    end
    return (firstChar(s) == '-')
end

argparse.isFlag = isFlag

---comment
---@param s string
---@return NiceArray<<T>>
local function splitFlags(s)
    local long = util.startsWith(s, '--')
    local flags = NiceArray:new()
    if long then
        print("longflag", s)
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
argparse.splitFlags = splitFlags

local function rawParseArgs(source)
    local items = NiceArray:new()
    for i, v in ipairs(source) do
        if isFlag(v) then
            local group = splitFlags(v)
            for _, flag in ipairs(group) do
                items:insert(flag)
            end
        else
            items:insert(v)
        end
    end
    return items
end
argparse.rawParseArgs = rawParseArgs


return argparse



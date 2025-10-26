local env = require("env")
local fmt = require("fmt")
local util = require("util")

local argparse = {}

love.filesystem.setSymlinksEnabled(true)

argparse.file = function(path)
    local info = love.filesystem.getInfo(path, {type="file"})
    if info ~= nil then
        return info
    else
        return nil
    end
end


argparse.State = {}

function argparse.State:new(o)
    print("parse state?")
    o = o or {}
    if o.args == nil then
        o.args = {}
    end
    setmetatable(o, self)
    self.__index = self
    if o.args == nil then
        error(fmt.errors.required_value({fmt.quote("args")}))
    end
    o.n_args = #(o.args)
    o.current = o.current or 1
    o.parsed = {
        flags = {},
        arguments = {}
    }
    return o
end


function argparse.State:consume(n)
    local afterN = o.current + n
    if afterN > o.n_args then
        error(fmt.errors.index_error({n, o.current, o.n_args}))
    end
    o.current = afterN
end


argparse.error = fmt.getErrorTemplater("ParseError", "cannot parse %s from \"%s\"")


function getFlagType(argvEntry)
    if argvEntry == nil then
        return nil
    else
        local length = string.len(argvEntry)
        if length > 0 then
            local first = string.sub(argvEntry, 1, 1)
            if first ~= "-" then
                return nil
            elseif length == 2 then
                return "short"
            else
                return "long"
            end
        end
    end
end


local ARGS = {
    path = {
        help="The path to read",
        -- parser=parseFilePath
    }
}

local FLAGS = {
}

return argparse
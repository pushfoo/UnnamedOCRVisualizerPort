local fmt = require("fmt")
local errors = fmt.errors

local argparse = {}

love.filesystem.setSymlinksEnabled(true)

---Compat shim aroung the env.Path type.
---@param path string|Path
---@return table<string, any>?
argparse.file = function(path)
    return love.filesystem.getInfo(tostring(path), {type="file"})
end


argparse.State = {}

function argparse.State:new(o)
    o = o or {}
    if o.args == nil then
        o.args = {}
    end
    setmetatable(o, self)
    self.__index = self
    if o.args == nil then
        error(errors.valueError("args are required, but got nil"))
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
        error(errors.ValueError("too many entries (expected %i, but got %i): %s", {n, o.current, table.concat(o.args, ", ")}))
    end
    o.current = afterN
end


-- arssparse.error = fmt.getErrorTemplater("ParseError", "cannot parse %s from \"%s\"")


function argparse.getFlagType(argvEntry)
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
local class = require "lib.middleclass"
local env = require "env"
local fmt = require("fmt")
local util = require("util")
local firstChar = util.firstChar

local errors = fmt.errors

local argparse = {}

love.filesystem.setSymlinksEnabled(true)


function argparse.getFlagType(argvEntry)
    if argvEntry == nil then
        return nil
    else
        local length = #argvEntry
        if length > 0 then
            local first = firstChar(argvEntry)
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
local ArgParser = class('ArgState')


function ArgParser:initialize(...)
    self.flags = {}
    self.arguments = {}
end

function ArgParser:parseArgs()

end


function argparse.State:consume(n)
    local afterN = o.current + n
    if afterN > o.n_args then
        error(errors.ValueError("too many entries (expected %i, but got %i): %s", {n, o.current, table.concat(o.args, ", ")}))
    end
    o.current = afterN
end


-- arssparse.error = fmt.getErrorTemplater("ParseError", "cannot parse %s from \"%s\"")





local ARGS = {
    path = {
        help="The path to read",
        -- parser=parseFilePath
    }
}

local FLAGS = {
}

return argparse
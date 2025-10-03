--[[ Helpers for environment probing and execution.

This mostly helps with running Tesseract at the moment.
]]
require("util")

env = {
    which = function(cmdname)
        local handle = io.popen("which " .. cmdname)
        local result = handle:read()
        return result
    end,
    versionFor = function(cmdname)
        local handle = io.popen(cmdname .. " --version")
        local it = string.gmatch(handle:read(), "[%d.]+")
        return it()
    end,
    run = {
        --[[ Get an iterator, optionally skipping the first skipN lines. ]]
        linesIterator = function(cmd, skipN)
            local handle = io.popen(cmd)
            local linesIt = util.functional.skipN(handle:lines(), skipN)
            return linesIt
        end,
        linesTable = function(cmd, skipN)
            local lines = NiceTable:new()
            for line in env.run.linesIterator(cmd, skipN) do
                lines:insert(line)
            end
            return lines
        end,
        getAllOutput = function(cmd, skipN)
            -- TODO: optimize if inefficiency is killing perf (unlikely for now)
            local t = NiceTable:new(env.run.linesTable(cmd, skipN))
            return t:concat("\n")
        end
    }
}

--- Helpers for environment probing and execution.

local fmt = require("fmt")
local util = require("util")
local NiceArray = require("structures").NiceArray


local env = {}


---Compat shim aroung the env.Path type.
---@param path string|Path
---@return table<string, any>?
function env.file(path)
    return love.filesystem.getInfo(tostring(path), {type="file"})
end


local trimEmptyToNil = util.trimEmptyToNil


function env.whoami()
    local username = nil
    local handle = io.popen("whoami")
    if handle then
        local raw = handle:read()
        username = trimEmptyToNil(raw)
    end
    return username
end


local DEFAULT_VERSION_PATTERNS = {
    whole = "[%d.]+",
    digit = "[%d]+"
}

local Version = {__index = table}


-- Primitives for running things in the environment.
env.run = {}


--- Get a version number for command.
---@param cmdName string
---@param versionPatterns table<"digit"|"whole",string>?
---@return table<integer,integer>?
function env.run.versionFor(cmdName, versionPatterns, versionFlag)
    versionFlag = versionFlag or "--version"
    versionPatterns = versionPatterns or DEFAULT_VERSION_PATTERNS

    local fullCommand = string.format("%s %s", cmdName, versionFlag)
    local handle = io.popen(fullCommand)
    if handle == nil then
        return
    end

    local toProcess = trimEmptyToNil(handle:read())
    if toProcess == nil then
        return
    end
    local rawVersion = string.gmatch(toProcess, versionPatterns.whole)()
    if rawVersion == nil then
        return
    end

    local version = nil
    for d in string.gmatch(rawVersion, versionPatterns.digit) do
        version = version or {}
        table.insert(version, tonumber(d))
    end
    return version
end


--- Run an io.popen with cmd.
---@param cmd string the commmand to run.
---@return string?
function env.run.readString(cmd)
    local handle = io.popen(cmd)
    local stringRaw = nil
    if handle then
        stringRaw = handle:read()
    end
    return stringRaw
end

--- Get the path for a command.
---@param cmdName string
---@return string?
function env.run.which(cmdName)
    local string = env.run.readString("which " .. cmdName)
    if string then
        return trimEmptyToNil(string)
    end
end

--- Get the apparent username.
---@return string?
function env.run.whoami()
    local string = env.run.readString("whoami")
    if string then
        return trimEmptyToNil(string)
    end
end


--- Work-around for Lua's io.open not having a true bytes read mode.
--- In theory, it allows reading bytes, but the implementation for LuaJIT
--- does not support it.
---@param cmd string
---@return love.Data?
function env.run.readBytes(cmd)
    -- TODO: Windows support :(
    local b64 = cmd .. " | base64"

    local bytes = nil
    local handle = io.popen(b64, "r")
    if handle then
        local data = handle:read()
        if data then
            bytes = love.data.decode("data", "base64", data)
        end
    end
    -- It's gonna be bytes or nil b/c we force it above.
    ---@cast bytes love.Data?
    return bytes
end


--- Get an iterator, optionally skipping the first skipN lines.
---@param cmd string
---@param skipN integer?
function env.run.linesIterator(cmd, skipN)
    local linesIt = nil
    local handle = io.popen(cmd)
    if handle then
        linesIt = handle:lines()
        if skipN then
            linesIt = util.functional.skipN(linesIt, skipN)
        end
    end
    return linesIt
end


--- Get a table of lines as an array, optionally with a skipN.
---@param cmd string
---@param skipN integer?
---@return table<integer, string>?
function env.run.linesTable(cmd, skipN)
    local lines = NiceArray:new()
    local iterated = false
    for line in env.run.linesIterator(cmd, skipN) do
        iterated = true
        lines:insert(line)
    end
    if iterated then
        return lines
    else
        return nil
    end
end


--- Get output after n lines.
---@param cmd string
---@param skipN integer?
---@return string?
function env.run.getOutputAfterNLines(cmd, skipN)
    -- TODO: optimize if inefficiency is killing perf (unlikely for now)
    local t = env.run.linesTable(cmd, skipN)
    if t then
        ---@diagnostic disable-next-line
        return t:concat("\n")
    else
        return nil
    end
end



--[[ Backport stub for 11.5 / some IDEs to stop complaining. ]]
if love and love.window and love.window.showFileDialog == nil then
    --- stub for Linux for now
    ---@param action string
    ---@param callback function
    love.window.showFileDialog = function(action, callback)
        if action ~= "openfile" then
            fmt.errors.notImplementedError("Only openfile is supported, not %a", {action})
        end
        local filename = env.run.readString("zenity --file-selection")
        return callback(filename)
    end
end

return env
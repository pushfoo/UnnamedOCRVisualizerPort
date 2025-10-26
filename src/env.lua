--- Helpers for environment probing and execution.

local util = require("util")
local structures = require("structures")
local Class, NiceArray = structures.Class, structures.NiceArray

local env = {}


if love.system.getOS() == "Windows" then
    env.DEFAULT_SEP = "\\"
else
    env.DEFAULT_SEP = "/"
end

-- Design goal: try to avoid too dependening on NiceArray / etc.
-- * This helps with decoupling this into a library for others
-- * Since we can't really subclass string, it may help perf?

--- A pathlib.Path-like path class.
--- IMPORTANT: Does not yet handle Windows drive letters!
---@class Path
local Path = {
    __index = table,
    sep = env.DEFAULT_SEP
}

env.Path = Path

--- Split a raw string into a table.
---@param raw string
---@return table?
function Path.split(raw)
    local t = nil
    local match = raw:gmatch("[^/]+")
    if match then
        t = {}
        for part in match do table.insert(t, part) end
    end
    return t
end


--- Convert to string.
---@return string
function Path:__tostring()
    local n = #self
    local parts = {}
    for i = 1,n do
        table.insert(parts, self[i])
    end
    return table.concat(parts, self.sep)
end


--- Gets a Path instance, defaulting to current directory for nil.
---@param o Path|string|table? A path as a Path, string, table, or nil.
---@return Path
function Path:new(o)
    o = o or "."
    local typeO = type(o)
    if typeO == "string" then
        if o == "." then
            o = env.pwd()
        elseif o == ".." then
            -- Pwd + strip last folder if any
            o = env.pwd()
            if o ~= "/" then
                o =
                    --[[@cast o string]]
                    o:gsub("[^/]+/?$", "")
            end
        end
        o = Path.split(o)
    elseif getmetatable(o) == env.Path then
        return o
    elseif typeO ~= "table" then
        error("TypeError: expected nil, string, or table but got " .. typeO)
    end
    ---@diagnostic disable-next-line
    self.__index = self
    ---@cast o table
    o = setmetatable(o, Path)
    ---@cast o Path
    return o
end


--- Wraps love.getUserDirectory() in an object-oriented style.
---@return Path
function Path.getUserDirectory()
    local userDirRaw = love.filesystem.getUserDirectory()
    return Path:new(userDirRaw)
end



--- Enable Python-style path shorthand:

---@usage
--- local Path = require("env").Path
--- local HERE = Path:new(".")
--- local IMAGE_PATH = HERE / "image.png"
--- @param otherString string The rest of the path to add.
function Path:__div(otherString)
    local t = NiceArray:new()
    t:extend(self)
    t:insert(otherString)
    return Path:new{unpack(t)}
end

--- Get the name of the directory or file, including any extension.
---@return string
function Path:getName()
    return self[#self]
end

--- Get the extension, minus any initiall dotfile value in the name.
---@usage local BASH_RC = Path:getUserDirectory() / ".bashrc"
---@return string
function Path:getExtension()
    local name = self:getName()
    local startIndex = 1
    if util.firstChar(name) == "." then
        startIndex = 2
    end

    local partsToSplit = name:sub(startIndex, #name)
    local extParts = {}
    local afterFirst = partsToSplit:gmatch("[^.]+")
    afterFirst()
    for part in afterFirst do
        table.insert(extParts, part)
    end
    local extension = table.concat(extParts, ".")

    return extension
end


--- Check if this is a dotfile
---@return boolean
function Path:isDotFile()
    return util.firstChar(self:getName()) == "."
end

--- Get the name minus any extensions.
---@return string
function Path:getStem()
    local name = self:getName()
    local startIndex = 1
    local stemParts = NiceArray:new()
    if util.firstChar(name) == "." then
        startIndex = 2
        stemParts:insert(".")
    end

    local partsToSplit = name:sub(startIndex)
    local first = partsToSplit:gmatch("[^.]+")()
    stemParts:insert(first)
    return --[[@as string]] stemParts:concat("")
end


--- Get the parent directory or nil if root of file system.
---@return Path?
function Path:getParent()
    local n = #self
    if n < 2 then
        return nil
    end
    local parts = {}
    for i in 1, n - 1 do
        table.insert(parts, self[i])
    end
    return Path:new{unpack(parts)}
end

--- Join the path with a separator, defaulting to the system slash separator.
---@param sep string? Override the system slash separator.
---@return string
function Path:concat(sep)
    if type(sep) ~= string then
        error("TypeError: expected a string for sep, but got sep=" .. tostring(sep))
    end
    -- print("sep", string.format("\"%s\"", sep))
    sep = sep or self.sep
    return sep .. table.concat(self, sep)
end

local trimEmptyToNil = util.trimEmptyToNil

--- Get the apparent username.
---@return string?
function env.whoami()
    local username = nil
    local handle = io.popen("whoami")
    if handle then
        local raw = handle:read()
        username = trimEmptyToNil(raw)
    end
    return username
end

--- Get the current working directory.
---@return Path?
function env.pwd()
    local raw = nil
    local trimmed = nil
    local handle = io.popen("pwd")
    if handle then
        raw = handle:read()
    end
    if raw then
        trimmed = trimEmptyToNil(raw)
    end
    if trimmed then
        return Path:new(trimmed)
    end
end

-- TODO: consider making this like iterdir?
--- List items in a directory (defaults to working dir).
--- @param directory string|Path?
--- @return table<integer, Path>?
function env.ls(directory)
    directory = Path:new(directory or ".")
    local t
    local handle = io.popen("ls " .. directory)
    if handle then
        t = NiceArray:new()
        for entry in handle:lines() do
            t:insert(directory / entry)
        end
    end
    return t
end


local DEFAULT_VERSION_PATTERNS = {
    whole = "[%d.]+",
    digit = "[%d]+"
}


--- Get the path for a command.
---@param cmdname string
---@return string?
function env.which(cmdname)
    local raw = nil
    local handle = io.popen("which " .. cmdname)
    if handle then
        raw = handle:read()
    end
    return trimEmptyToNil(raw)
end


--- Get a version number for command.
---@param cmdName string
---@param versionPatterns table<"digit"|"whole",string>?
---@return table<integer,integer>?
function env.versionFor(cmdName, versionPatterns, versionFlag)
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

-- Runnable things.
env.run = {}

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


--- Work-around for Lua's io.open not having a true bytes read mode.
--- In theory, it allows reading bytes, but the implementation for LuaJIT
--- does not support it.
---@param cmd string
---@return love.Data?
function env.run.readBytes(cmd --[[@as string]])
    -- TODO: Windows support :(
    local b64 = tostring(cmd) .. " | base64"
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


-- Helper for cli application runners.
local defaultCommands = {}
function env.makeRunnerClass(
    commandName,
    defaults,
    metatable
)
    if defaultCommands[commandName] then
        error(string.format("NameConflict: Already declared a class for '%s'", commandName))
    end

    defaults = defaults or {}
    if defaults.which == nil then
       defaults.which = env.which(commandName)
    end
    if defaults.version == nil then
        defaults.version = env.versionFor(commandName)
    end

    local command = Class(defaults, metatable)
    defaultCommands[commandName] = command

    return command
end


--[[ Backport stub for 11.5 / some IDEs to stop complaining. ]]
if love.window.showFileDialog == nil then
    --- stub for Linux for now
    ---@param action string
    ---@param callback function
    love.window.showFileDialog = function(action, callback)
        if action ~= "openfile" then
            error("ValueError: this is a partial stub. Only openfile is supported, not " .. action)
        end
        local filename = env.run.readString(string.format("zenity --file-selection"))
        return callback(filename)
    end
end

return env
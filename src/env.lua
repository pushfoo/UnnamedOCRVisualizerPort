--[[ Helpers for environment probing and execution.

This mostly helps with running Tesseract at the moment.
]]
require("structures")
require("util")

env = {}

DEFAULT_SEP = "/"

--[[ A Path utility type inspired by pathlib.Path in Python.

> [!IMPORTANT]
> This does not currently handle Windows drive letters!

Static methods include .split() for splitting folder names.
]]
Path = {
    __index = table,
    sep = DEFAULT_SEP
}


Path.__tostring = function(self)
    local n = self:getn()
    local parts = {}
    for i = 1,n do
        table.insert(parts, self[i])
    end
    return table.concat(parts, self.sep)
end

Path.split = function(raw)
    local t = {}
    local match = raw:gmatch("[^/]+")
    for part in match do table.insert(t, part) end
    return t
end


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
                o = o:gsub("[^/]+/?$", "")
            end
        end
        o = Path.split(o)
    elseif getmetatable(o) == Path then
        return o
    elseif typeO ~= "table" then
        error("TypeError: expected nil, string, or table but got " .. typeO)
    end
    self.__index = self
    return setmetatable(o, Path)
end

-- function Path:getn()
--     return table.getn(self)
-- end


--[[ Enable Python-style path shorthand:

```lua
local HERE = Path:new(".")
local imagePath = HERE / "image.png"
```

This does no validation on the path.

@param otherString the rest of the path.
]]
function Path:__div(otherString)
    local t = NiceTable:new()
    t:extend(self)
    t:insert(otherString)
    return Path:new{unpack(t)}
end


function Path:getName()
    return self[#self]
end


function Path:getExtension()
    local name = self:getName()
    local startIndex = 1
    if util.firstChar(name) == "." then
        startIndex = 2
    end

    local partsToSplit = name:sub(startIndex, #name)
    local extParts = NiceTable:new()
    local afterFirst = util.functional.skipN(partsToSplit:gmatch("[^.]+"), 1)
    for part in afterFirst do
        extParts:insert(part)
    end
    local extension = extParts:concat(".")

    return extension
end


function Path:isDotFile()
    return util.firstChar(self) == "."
end


function Path:getStem()
    local name = self:getName()
    local startIndex = 1
    local stemParts = NiceTable:new()
    if util.firstChar(name) == "." then
        startIndex = 2
        stemParts:insert(".")
    end

    local partsToSplit = name.sub(startIndex)
    local first = partsToSplit:gmatch("[^.]+")()
    stemParts:insert(first)
    return stemParts:concat("")
end


function Path:getParent()
    local n = self:getn()
    if n < 2 then
        return nil
    end
    local parts = NiceTable:new()
    for i in 1, n - 1 do
        parts:insert(self[i])
    end
    return Path:new{unpack(parts)}
end


function Path:concat(sep)
    -- print("sep", string.format("\"%s\"", sep))
    sep = sep or self.sep
    return sep .. table.concat(self, sep)
end


local trimEmptyToNil = util.trimEmptyToNil
env = {
    pwd = function()
        local trimmed = nil
        local handle = io.popen("pwd")
        if handle then
            local raw = handle:read()
            trimmed = trimEmptyToNil(raw)
        end
        return trimmed
    end,
    ls = function(directory)
        directory = directory or "."
        local t = NiceTable:new()
        local handle = io.popen("ls " .. directory)
        if handle then
            for entry in handle:lines() do t:insert(entry) end
        end
        return t
    end,
    which = function(cmdname)
        local raw = nil
        local handle = io.popen("which " .. cmdname)
        if handle then
            raw = handle:read()
        end
        return trimEmptyToNil(raw)
    end,
    versionFor = function(cmdname, versionPattern)
        versionPattern = versionPattern or "[%d.]+"
        local version = nil
        local handle = io.popen(cmdname .. " --version")
        if handle then
            local toProcess = trimEmptyToNil(handle:read())
            if toProcess then
                local it = string.gmatch(toProcess, versionPattern)
                version = it()
            end
        end
        return version
    end,
    run = {
        readString = function(cmd)
            local handle = io.popen(cmd)
            local stringRaw = nil
            if handle then
                stringRaw = handle:read()
            end
            return stringRaw
        end,
        --[[ Work-around for Lua's io.open not having a true bytes read mode.

        In theory, it allows reading bytes, but the implementation for LuaJIT
        does not support it.
        ]]
        readBytes = function(cmd)
            local b64 = cmd .. " | base64"
            -- print("cmd with base64", b64)
            local bytes = nil
            local handle = io.popen(b64, "r")
            if handle then
                local data = handle:read()
                if data then
                    bytes = love.data.decode("data", "base64", data)
                end
                -- print("bytes", bytes, tostring(bytes:getSize()), "bytes read")
            end
            return bytes
        end,
        --[[ Get an iterator, optionally skipping the first skipN lines. ]]
        linesIterator = function(cmd, skipN)
            local linesIt = nil
            local handle = io.popen(cmd)
            if handle then
                linesIt = util.functional.skipN(handle:lines(), skipN)
            end
            return linesIt
        end,
        linesTable = function(cmd, skipN)
            local lines = NiceTable:new()
            for line in env.run.linesIterator(cmd, skipN) do
                lines:insert(line)
            end
            return lines
        end,
        getOutputAfterNLines = function(cmd, skipN)
            -- TODO: optimize if inefficiency is killing perf (unlikely for now)
            local t = env.run.linesTable(cmd, skipN)
            return t:concat("\n")
        end
    }
}

-- Helper for cli application runners.
local defaultCommands = {}
function makeRunnerClass(
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

--[[ Backport stub for 11.5 / some IDEs to stop complaining.

]]
if love.window.showFileDialog == nil then
    -- stub for Linux for now
    love.window.showFileDialog = function(action, callback)
        if action ~= "openfile" then
            error("ValueError: this is a partial stub. Only openfile is supported, not " .. action)
        end
        local filename = env.run.readString(string.format("zenity --file-selection"))
        return callback(filename)
    end
end
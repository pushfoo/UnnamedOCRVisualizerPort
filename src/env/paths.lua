local _enum = require("enum")
local util = require("util")

local copyArray = util.table.copyArray
local trimEmptyToNil = util.trimEmptyToNil
local firstChar = util.firstChar
local NiceArray = require("structures").NiceArray


local paths = {
    WIN32_SLASH = "\\",
    UNIX_SLASH = "/"
}
local enums = _enum.createBlockOnPackage(paths)


local _os = nil
if love and love.system and love.system.getOS then
    _os = love.system.getOS()
else
    local ffi = require("ffi")
    if ffi then
        _os = ffi.os
    end
end


if _os == "Windows" then
    paths.PLATFORM_SEP = paths.WIN32_SLASH
else
    paths.PLATFORM_SEP = paths.UNIX_SLASH
end


local _sepToNonSepBlock = {}
local function _getNonSep(slash)
    local item = _sepToNonSepBlock[slash]
    if item == nil then
        item = string.format("[^%s]+", slash)
        _sepToNonSepBlock[slash] = item
    end
    return item
end


local _sepToLastEltChopper = {}


---Cached function which generates path separator for a given slash.
---@param slash any
---@return string|unknown
local function _getLastEltChopper(slash)
    local item = _sepToLastEltChopper[slash]
    if item == nil then
        item = string.format("[^%s]%s?$", slash, slash)
        _sepToLastEltChopper[slash] = item
    end
    return item
end


-- Design goal: try to avoid too dependening on NiceArray / etc.
-- * This helps with decoupling this into a library for others
-- * Since we can't really subclass string, it may help perf?

--- A pathlib.Path-like path class.
--- IMPORTANT: Does not yet handle Windows drive letters!
---@class Path
local Path = {
    __index = table,
    sep = paths.DEFAULT_SEP
}
paths.Path = Path


--- Split a raw string into a table.
---@param raw string
---@param sep string?
---@return table?
local function _split(raw, sep)
    local pattern = _getNonSep(sep or paths.PLATFORM_SEP)
    local t = nil
    local match = raw:gmatch(pattern)
    if match then
        t = {}
        for part in match do
             table.insert(t, part)
        end
    end
    return t
end

local function _readTrimmed(cmd)
    local handle = io.popen(cmd)
    local result = nil
    if handle then
        local raw = handle:read()
        if raw then
            result = trimEmptyToNil(raw)
        end
    end
    return result
end


local function _pwd()
    _readTrimmed("pwd")
end


---Internal helper for splitting paths.
---@param pathStr string
---@return string?
---@return string?
local function _getParent(pathStr, sep)
    local result = nil
    local err = nil
    if _os == "Windows" then
        err = "NotImplemented: Full windows support not yet built"
    elseif pathStr == '/' then
        result = pathStr
    else
        local chopPattern = _getLastEltChopper(sep or paths.PLATFORM_SEP)
        result = pathStr:gsub(chopPattern, "")
    end
    return result,err
end


---@enum (key) PathsDots
local PathDots = {
    WORKING_DIR = ".",
    PARENT_DIR = ".."
}
---@diagnostic disable-next-line
enums.PathDots = PathDots


---Resolve . and .. into a path.
---@param pathDots string
---@param sep string?
---@return string|nil
---@return string|nil
local function _resolveDots(pathDots, sep)
    local result = nil
    local err = nil
    local pwd = _pwd()
    if pwd == nil then
        err = "NoWorkingDir: could not resolve working dir for %s"
    else
        if pathDots == PathDots.WORKING_DIR then
            result = pwd
        elseif pathDots == PathDots.PARENT_DIR then
            result = _getParent(pwd, sep)
            if result == nil then
                err = "NoParentDir: could not resolve parent dir for %s"
            end
        end
    end
    if err then
        err = string.format(err, tostring(pathDots))
    end
    return result,err
end


---Attempt to split a string path to a table of parts.
---@param str string
---@param sep string?
---@return table?
---@return string?
local function _resolveStringPath(str, sep)
    local result = nil
    local err = nil
    if str == PathDots.WORKING_DIR or str == PathDots.PARENT_DIR then
        local new,_err = _resolveDots(str)
        if _err then
           err = _err
        elseif new == nil then
            err = string.format("NoWorkingDir: could not resolve a working directory from '%s'", str)
            result = new
        else
            result = _split(new, sep)
        end
    else
        result = _split(str, sep)
    end
    print("r", str, result)
    return result,err
end


--- Get a FileData object for an external file via LuaJIT's io built-in.
---@param path string|Path A path to read from.
---@param mode string The mode to open in ("r" or "rb")
---@return love.FileData? - file data for the given file.
function paths.load_external_file(path, mode)
    -- Using tostring here converts our custom Path type.
    local file = io.open(tostring(path), mode)
    local data = nil
    if file then
        local raw = file:read("*a")
        file:close()
        data = love.filesystem.newFileData(raw, tostring(path))
    end

    return data
end


--- Gets a Path instance, defaulting to current directory for nil.
---@param o Path|string|table? A path as a Path, string, table, or nil.
---@return Path
function Path:new(o)
    o = o or "."
    local T_o = type(o)
    local asTable = nil
    local needsCopy = true
    local _mt = nil
    if T_o == 'table' then
        _mt = getmetatable(o)
        if _mt == Path then
            ---@cast o Path
            return o
        elseif _mt ~= NiceArray  and _mt ~= table then
            error("TypeError: got a table, but it has a non-NiceArray, non-table metatable?")
        end
    elseif T_o == 'string' then
        local maybeTable, maybeErr = _resolveStringPath(o)
        if maybeErr then
            error(maybeErr)
        else
            asTable = maybeTable
            needsCopy = false
        end
    else
        error("TypeError: expected nil, string, or table but got " .. T_o)
    end
    if needsCopy then
        ---@cast asTable table<integer, string>
        asTable = copyArray(asTable)
    end
    ---@diagnostic disable-next-line
    self.__index = self
    ---@diagnostic disable-next-line
    return setmetatable(asTable, Path)
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
    if firstChar(name) == "." then
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
    return firstChar(self:getName()) == "."
end

--- Get the name minus any extensions.
---@return string
function Path:getStem()
    local name = self:getName()
    local startIndex = 1
    local stemParts = NiceArray:new()
    if firstChar(name) == "." then
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


return paths
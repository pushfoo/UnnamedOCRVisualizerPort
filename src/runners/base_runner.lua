local fmt = require("fmt")
local env = require("env")
local class = require("lib.middleclass")
local popKey = require("util").table.popKey

local base_runner = {optsTables = {}}

local function getOptsTableErr(optsTable, expect)
    local _expect_mt = expect.hasDirectMetatable
    local _T_expect_mt = type(_expect_mt)
    local err = nil
    if _expect_mt and type(_expect_mt) ~= table then
            error(string.format(
                "TypeError: non-table option hasDirectMetatable=%s (a %s) provided.",
                tostring(_expect_mt), type(_T_expect_mt)))
    end
    T_optsTable = T_optsTable or type(optsTable)
    if T_optsTable ~= 'table' then
        err = string.format(
            "TypeError: expected a table, not a %s", T_optsTable
        )
    elseif expect.hasDirectMetatable then
        local _mt = getmetatable(optsTable)
        if _mt ~= _expect_mt then
            err = string.format(
                "TypeError: expected metatable %s, but got %s instead.",
                tostring(_expect_mt), tostring(_mt)
            )
        end
    end
    return err
end

base_runner.optsTables.getOptsTableErr = getOptsTableErr

function base_runner.optsTables.popVersion(optsTable)
    local err = getOptsTableErr(optsTable)
    if err then error(err) end
    return popKey(optsTable, 'version')
end

---@class Runner
---@overload fun():Runner
---@field command string
---@field path Path
---@field version string|table<integer, integer>?
local BaseRunner = class('Runner')

---A generic OOP shell over a CLI command.
---@param command string A command name.
---@param path string|Path? A specific path for it.
---@param version string|table<integer,number>? The version number
function BaseRunner:initialize(command, path, version)
    local e = fmt.errors
    if type(command) ~= "string" then
        error(e.typeError("command name must be a string"))
    end
    self.command = command
    if path == nil then
        path = env.run.which(command)
    end
    if path == nil then
        error(e.noExecutableError("could not find a valid path for \"%s\"", {command}))
    end
    self.which = path
    if version == nil then
        version = env.run.versionFor(command)
    end
    self.version = version
end
base_runner.BaseRunner = BaseRunner

return base_runner

---[[ Provide an ESpeak runner on supporting operating systems.
---
---This'll need further work to flesh out and add support for
---inline speech sythnesis mark-up. *In theory* it may allow
---for low-cost, low-resource TTS of recognized text. Quality
---may be very lacking.
---
---IMPORTANT: piping bytes does not work well for this!
---
---Setting up a temp dir or cache dir may be better than
---trying to depend on unreliable binary piping. Chains of
---pipes run with io.open should be considered unreliable.
---
---]]
local BaseRunner = require("runners.base_runner").BaseRunner
local _enum = require("enum")
local util = require("util")
local popNilOrNonEmptyString = util.table.popNilOrNonEmptyString
local NiceArray = require("structures").NiceArray
local valueIs = require("localmath").valueIs
local espeak = {}
local enums = _enum.createBlockOnPackage(espeak)


---@class ESpeak
---@field which string|Path
---@overload fun():ESpeak
---@diagnostic disable-next-line
local ESpeakRunner = BaseRunner:subclass('ESpeakRunner')

function ESpeakRunner:initialize(optsTable)
    local version = nil
    local which = nil
    if type(optsTable) == 'table' then
        version = popNilOrNonEmptyString(optsTable, 'version')
        which   = popNilOrNonEmptyString(optsTable, 'which')
    end
    ---@diagnostic disable-next-line
    BaseRunner.initialize(self, 'espeak', which, version)
end


local function notNilOrSpeedNumber(maybeSpeed)
    local problem = nil
    if maybeSpeed ~= nil and type(maybeSpeed) ~= 'number' then
        problem = 'TypeError'
    elseif not valueIs(maybeSpeed, {ge=0, le=200}) then
        problem = 'ValueError'
    end
    if problem then
        return string.format("%s: speed must be between 0 and 200, but got %s", problem, tostring(maybeSpeed))
    end
end

---Say the given text, optionally at a given speed.
---@param text string
---@param speed number? Defaults to 160 on espeak's side.
---@return boolean - true if it ran successfully
function ESpeakRunner:say(text, speed)
    if type(text) ~= 'string' then
        error('TypeError: expected string for text, but got ' .. type(text))
    end
    local problem = nil
    if speed then
        problem = notNilOrSpeedNumber(speed)
        if problem then error(problem) end
    end
    -- encoding, err = _enum.Enum.getValidated(self, encoding or InputEncoding.UTF8)
    -- if(err) then error(err) end
    local cmd = NiceArray:new()
    cmd:insert(self.which)
    cmd:insert("--stdin")
    local joined = cmd:concat(" ")
    local handle = io.popen(joined, "w")
    if handle then
        handle:write(text)
        handle:close()
    else
        error("ESpeakRunnerError: failed to run")
    end
    return true
end


espeak.ESpeakRunner = ESpeakRunner

return espeak

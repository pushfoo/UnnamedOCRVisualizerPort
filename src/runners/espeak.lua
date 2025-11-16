local BaseRunner = require("runners.base_runner").BaseRunner
local _enum = require("enum")

local espeak = {}
enums = _enum.createBlockOnPackage(espeak)


---@class ImageMagick
---@field which string|Path
---@overload fun():ImageMagick
---@diagnostic disable-next-line
local ESpeakRunner = BaseRunner:subclass('ESpeakRunner')

function ESpeakRunner:initialize(which, optsTable)
    local version = optsTable.version
    if version then
        local T_version = type(version)
        if not (T_version == 'table' or T_version == 'string') then
            error("TypeError")
        end
        optsTable.version = nil
    end
    BaseRunner.initialize(self, 'espeak', which, version)
end

return espeak
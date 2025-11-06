--[[ Color-based conversion, textures, and mapping.

]]

local fmt_errors = require("fmt").errors
local util = require("util")
local class = require("lib.middleclass")
local localmath = require("localmath")
local typechecks = require("typechecks")
local structures = require("structures")
local BiMap, enum = structures.BiMap, structures.enum
local tern = util.functional.tern
local lerpTable = localmath.lerpTable
local colors = {}

--- Convert a luminance value to a normalized RGBA colors.
---If no alpha value is specied, it will default to 1.0.
---@param value number A normalized brightness float.
---@param alpha number? An opacity value (1.0 if unspecified)
function colors.fromLuminance(value, alpha)
    alpha = alpha or 1.0 -- Important: 0.0 is truthy in Lua
    return {value, value, value, alpha}
end
local fromLuminance = colors.fromLuminance

-- Some vaguely useful monochorome constants (needs perceptual re-spacing)
colors.BLACK        = fromLuminance(0.0)
colors.DARKER_GRAY  = fromLuminance(0.4)
colors.GRAY         = fromLuminance(0.5)
colors.LIGHTER_GRAY = fromLuminance(0.6)
colors.WHITE        = fromLuminance(1.0)

-- Commonly used values for color mapping
colors.RED    = {1.0, 0.0, 0.0, 1.0}
colors.YELLOW = {1.0, 1.0, 0.0, 1.0}
colors.GREEN  = {0.0, 1.0, 0.0, 1.0}


-- For the "missing" texture
colors.MAGENTA = {1.0, 0.0, 1.0, 1.0}


local E = {
    current = nil
}

function ENUM_BEGIN(name)
    if ENUM_current then
        error("EnumError: already started an enum named " .. name)
    end
    ENUM_current = {
        default = nil,
        name = name
    }
end

---@generic E
---@param first E
---@return E
function ENUM_Default(first)
    local current = ENUM_current
    if current == nil then
        error("No current enum?")
    end
    local d = current.default
    if d ~= nil then
        error(string.format("Already have a default %s, but got %s", d, first))
    end
    current.default = first
    return first
end


local Enum = {}
local _defaults = {}
local _bimaps = {}
local _typesets = {}
local _names = {}


local function _fmtMsg(enumName, problemType, value, typeSet)
    local names = {}
    for typeName, _ in pairs(typeSet) do
        table.insert(names, typeName)
    end
    local typestring = table.concat(names, ", ")
    local msg = string.format(
        "%s: value=%s is not a member of %s, must be one of %s",
        problemType, value, enumName, typestring
    )
    return msg
end


function Enum:getDefault()
   return _defaults[self]
end

---@generic E
---@param value E?
---@return E?,string?
function Enum:getValidated(value)
    if value == nil then
        return _defaults[self]
    end
    local typeSet = _typesets[self]
    local bimap = _bimaps[self]
    local problem = nil
    if typeSet[value] == nil then
        problem = "TypeError"
    elseif not (bimap:hasValue(value)) then
        problem = "ValueError"
    end
    if problem then
        local msg = _fmtMsg(_names[self], problem, value, typeSet)
        return nil,msg
    end
    return value
end

function ENUM_END(enumTable)
    local done = ENUM_current
    if done == nil then
        error("No Enum in progress?")
    end
    _defaults[enumTable] = done.default
    local b = structures.BiMap:new()
    local typeSet = {}
    for k ,v in pairs(enumTable) do
        typeSet[type(v)] = true
        b:addPair(k, v)
    end
    _bimaps[enumTable] = b
    _typesets[enumTable] = typeSet
    local mt =  {__index = Enum, __newindex= function (self, k, v)
        local name = _names[self]
        error(string.format("ImmutableError: cannot set %s=%s on enum %s as it is ImmutableError.",
            name, k, v))
    end
    }

    setmetatable(enumTable, mt)
    ENUM_current = nil
    return enumTable
end

-- Sets up state for ENUM_Default below.
ENUM_BEGIN('ChannelType')

-- Channel data signals to tell color conversion what to do.
---@enum (key) ChannelType
local ChannelType = {
    BYTE = 'byte',
    NORM = ENUM_Default('norm')
}

ENUM_END(ChannelType)


colors.ChannelType = ChannelType



--- Ensure a value is a normalized RGBA colors.
--- Behavior depends on the value type passed:
--- - numbers are treated as gray values with alpha 1.0
--- - tables depends on length:
---    - Length 3 is treated as alpha 1.0
---    - Length 4 is returned as-is
--- All of the values produce an error.
---@param colorRaw table<integer, number>|number
---@param fromType ChannelType?
---@return table<integer, number>
function colors.asNorm(colorRaw, fromType)
    local ft, err = Enum.getValidated(ChannelType,fromType)
    if err then error(err) end
    -- if problem then
    --     error(string.format("%s: fromType=%s (not one of 'norm' or 'bytes')", problem, fromType))
    -- end
    -- fromType = ChannelType:getValueForName(fromType)
    local T_colorRaw = type(colorRaw)
    local converted = nil

    if T_colorRaw == "number" then
        converted = fromLuminance(colorRaw)
    elseif T_colorRaw == "table" then
        local n_colorRaw = #colorRaw
        if n_colorRaw == 3 then
            converted = {unpack(colorRaw), 1.0}
        elseif n_colorRaw == 4 then
            converted = colorRaw
        else
            error(fmt_errors.valueError("expected #colorRaw == 3 or 4, but got #colorRaw=%i", {#colorRaw}))
        end
        local maxChannel = 255
        local scaleBy = 255.0
        -- TODO: The OOP library (middleclass) and VS Code hate each other
        -- ; -; y tho? y? Please, don't make me use Teal or other compile-my-compiler-in-yet-another-compiler-ity?
        if ft == ChannelType.NORM then
            maxChannel = 1.0
            scaleBy = 1.0
        end
        for i = 1,n_colorRaw do
            local dim = converted[i]
            if dim < 0.0 or dim > maxChannel then
                error(fmt_errors.valueError("colorRaw[%i]==%d with %s (must be 0 <= dim <= %d)", {i, dim, fromType, maxChannel}))
            end
            converted[i] = dim / scaleBy
        end
    else
        error(fmt_errors.typeError("colorRaw expects number or table, but got %s", {tostring(colorRaw)}))
    end
    return converted
end

local asNorm = colors.asNorm


--- Create a checkers-like image
--- Total return texture size will be twice the checkerSize.
---@param fgAndBg table<integer, table<integer,number>> A table of `{foreground, background}`.
---@param checkerSize integer? An integer number for the checker size.
---@param filterMode "nearest"|"linear"? Sharp or blurry textures.
---@return love.Texture
function colors.makeCheckers(fgAndBg, checkerSize, filterMode)
    checkerSize = checkerSize or 8
    local e = typechecks.err
    local problem = (
        e.invalidSizeAxis("checkerSize", checkerSize)
        or e.notArrayOfLength("fgAndBg", fgAndBg, 2)
    )
    if problem then error(problem) end

    local totalSize = checkerSize * 2
    local fg = asNorm(fgAndBg[1])
    local bg = asNorm(fgAndBg[2])

    local graphics = love.graphics
    local checkerCanvas = graphics.newCanvas(totalSize, totalSize)
    graphics.setCanvas(checkerCanvas)
    graphics.clear{unpack(bg)}
    graphics.setColor{unpack(fg)}
    graphics.rectangle("fill", 0,0, checkerSize, checkerSize, 0, 0)
    graphics.rectangle("fill", checkerSize, checkerSize, totalSize, totalSize, 0, 0)
    graphics.setCanvas()

    local checkerImage = util.graphics.textureFromCanvas(checkerCanvas)
    checkerImage:setWrap("repeat", "repeat")
    checkerImage:setFilter(filterMode or "nearest")

    return checkerImage
end

colors.NOT_FOUND_COLORS = {colors.MAGENTA, colors.BLACK}
colors.ALPHA_GRAY_COLORS = {colors.LIGHTER_GRAY, colors.DARKER_GRAY}
colors.checkers = {
    NOT_FOUND = colors.makeCheckers(colors.NOT_FOUND_COLORS),
    ALPHA = colors.makeCheckers(colors.ALPHA_GRAY_COLORS)
}


--- Map a normalized float value to a color gradient.
--- This is like the "gradient map" operation in PhotoShop and
--- other image editors. The ColorMapper type further down is
--- an OOP wrapper around the same thing.
---@param normValue number A normalized value to map into table space.
---@param colorTable table<integer, table<integer, number>> A table of color data.
---@return table<integer, number>
function colors.mapNormFloatToColor(normValue, colorTable)
    if normValue < 0 then
        return colors.GRAY
    end
    local mapping = colorTable or colors.DEFAULT_CONF_COLORS
    local n = #mapping

    if normValue >= 1.0 then
        return mapping[n]
    end

    local index, towardNext = math.modf(1 + normValue * (n - 1))
    local baseColor = mapping[index]
    if towardNext == 0.0 then
        return baseColor
    end
    local endColor = mapping[math.min(n, index + 1)]

    local result = lerpTable(baseColor, endColor, towardNext)
    return result
end
colors.DEFAULT_CONF_COLORS = {
    colors.RED,
    colors.YELLOW,
    colors.GREEN
}

--[[ Has a :map(floatNum) returning an RGBA array table.

This is how we show confidence on screen.
]]
local ColorMapper = class('ColorMapper')

function ColorMapper:initalize(range)
    if range then
        self.colors = range
    else
        self.colors = {unpack(range.DEFAULT_CONF_COLORS)}
    end
end


--- Map along the inner table's first color (0.0) to the last (1.0).
---@param normFloat number Normalized range value.
---@return table<integer, number>
function ColorMapper:map(normFloat)
    return colors.mapNormFloatToColor(normFloat, self.colors)
end

colors.ColorMapper = ColorMapper

return colors
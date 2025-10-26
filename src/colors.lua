--[[ Color-based conversion, textures, and mapping.

]]
local fmt = require("fmt")
local util = require("util")
local Class = require("structures").Class
local localmath = require("localmath")

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

colors.BLACK        = fromLuminance(0.0)
colors.DARKER_GRAY  = fromLuminance(0.4)
colors.GRAY         = fromLuminance(0.5)
colors.LIGHTER_GRAY = fromLuminance(0.6)
colors.WHITE        = fromLuminance(1.0)

-- For the "missing" texture
colors.MAGENTA = {1.0, 0.0, 1.0, 1.0}

--- Ensure a value is a normalized RGBA colors.
--- Behavior depends on the value type passed:
--- - numbers are treated as gray values with alpha 1.0
--- - tables depends on length:
---    - Length 3 is treated as alpha 1.0
---    - Length 4 is returned as-is
--- All of the values produce an error.
---@param v table<integer, number>|number
---@return table<integer, number>
function colors.asNorm(v)
    local src = type(v)
    if src == "number" then
        return fromLuminance(v)
    elseif src == "table" then
        local vN = #v
        if vN == 3 then
            return {unpack(v), 1.0}
        elseif vN == 4 then
            return v
        else
            error("ValueError: expected table to be length 3 or 4")
        end
    else
        error("TypeError: expected number or table, not " .. src)
    end
end
local asNorm = colors.asNorm

--- Create a checkers-like image
--- Total return texture size will be twice the checkerSize.
---@param fgAndBg table<integer, table<integer,number>> A table of `{foreground, background}`.
---@param checkerSize integer? An integer number for the checker size.
---@return love.Texture
function colors.makeCheckers(fgAndBg, checkerSize)
    checkerSize = checkerSize or 8
    local T_checkerSize = type(checkerSize)
    if #fgAndBg ~= 2 then
        error(fmt.errors.wrong_size({"settings.colors == 2", #fgAndBg}))
    elseif T_checkerSize ~= "number" then
        error(fmt.error("TypeError", "checkerSize must be a number, not a %s", {checkerSize}))
    elseif checkerSize == nil then
        checkerSize = 8
    end
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
    checkerImage:setFilter("linear")
    return checkerImage
end


colors.checkers = {NOT_FOUND = colors.makeCheckers({colors.MAGENTA, colors.BLACK})}

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
    {1.0, 0.0, 0.0, 1.0}, -- Red
    {1.0, 1.0, 0.0, 1.0}, -- Yellow
    {0.0, 1.0, 0.0, 1.0}  -- Green
}

--[[ Has a :map(floatNum) returning an RGBA array table.

This is how we show confidence on screen.
]]

local ColorMapper = Class({colors={unpack(colors.DEFAULT_CONF_COLORS)}})

--- Map along the inner table's first color (0.0) to the last (1.0).
---@param normFloat number Normalized range value.
---@return table<integer, number>
function ColorMapper:map(normFloat)
    return colors.mapNormFloatToColor(normFloat, self.colors)
end

colors.ColorMapper = ColorMapper

return colors
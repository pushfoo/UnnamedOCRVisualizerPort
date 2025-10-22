--[[ Color-based conversion, textures, and mapping.

]]
require("util")
require("structures")
require("localmath")

--[[ Convert a luminance value to a normalized RGBA color.

If no alpha value is specied, it will default to 1.0.

@param value: A normalized brightness float.
@param alpha: An opacity value (1.0 if unspecified)
]]
function fromLuminance(value, alpha)
    alpha = alpha or 1.0 -- Important: 0.0 is truthy in Lua
    return {value, value, value, alpha}
end


BLACK        = fromLuminance(0.0)
DARKER_GRAY  = fromLuminance(0.4)
GRAY         = fromLuminance(0.5)
LIGHTER_GRAY = fromLuminance(0.6)
WHITE        = fromLuminance(1.0)

-- For the "missing" texture
MAGENTA = {1.0, 0.0, 1.0, 1.0}

--[[ Ensure a value is a normalized RGBA color.

Behavior depends on the value type passed:

- numbers are treated as gray values with alpha 1.0
- tables depends on length:
   - Length 3 is treated as alpha 1.0
   - Length 4 is returned as-is
All of the values produce an error.

@param v: A value to make an RGBA normalized color.
]]
function asNormColor(v)
    local src = type(v)
    if src == "number" then
        return fromLuminance(v)
    elseif src == "table" then
        local vN = table.getn(v)
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


--[[ Create a checkers-like image

Total return texture size will be twice the checkerSize.

@param colors: A table of foreground and background as any of:
    - a normalized luminance float
    - an RGBA norm array table
@param checkerSize: An integer number for the checker size.
]]
function makeCheckers(colors, checkerSize)
    if #colors ~= 2 then
        error(fmt.errors.wrong_size({"settings.colors == 2", #colors}))
    elseif checkerSize ~= nil and type(checkerSize) ~= "number" then
        error(fmt.error("TypeError", "checkerSize must be a number, not a %s", {type(checkerSize)}))
    elseif checkerSize == nil then
        checkerSize = 8
    end
    totalSize = checkerSize * 2
    local fg = asNormColor(colors[1])
    local bg = asNormColor(colors[2])

    local graphics = love.graphics
    checkerCanvas = graphics.newCanvas(totalSize, totalSize)
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


NOT_FOUND = makeCheckers({MAGENTA, BLACK})

--[[ Map a normalized float value to a color gradient.

This is like the "gradient map" operation in PhotoShop and
other image editors. The ColorMapper type further down is
an OOP wrapper around the same thing.
]]
function mapNormFloatToColor(normValue, colorTable)
    if normValue < 0 then
        return GRAY
    end
    local mapping = colorTable or DEFAULT_CONF_COLORS
    local n = table.getn(mapping)
    local n_minus = n - 1

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


DEFAULT_CONF_COLORS = {
    {1.0, 0.0, 0.0, 1.0}, -- Red
    {1.0, 1.0, 0.0, 1.0}, -- Yellow
    {0.0, 1.0, 0.0, 1.0}  -- Green
}

--[[ Has a :map(floatNum) returning an RGBA array table.

This is how we show confidence on screen.
]]

ColorMapper = Class({colors={unpack(DEFAULT_CONF_COLORS)}})


function ColorMapper:map(normFloat)
    return mapNormFloatToColor(normFloat, self.colors)
end

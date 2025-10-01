require("localmath")

function fromLuminance(value, alpha)
    if alpha == nil then alpha = 1.0 end
    return {value, value, value, alpha}
end

GRAY = fromLuminance(0.5)
WHITE = fromLuminance(1.0)

function mapNormalizedToColor(normValue, useMapping)
    if normValue < 0 then
        return GRAY
    end
    local mapping = useMapping or DEFAULT_CONF_COLORS
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

ColorMapper = {}

function ColorMapper:new(o)
    -- Good-enough quick-copyhttp://lua-users.org/wiki/CopyTable
    o = o or {colors={unpack(DEFAULT_CONF_COLORS)}}
    colors = o.colors
    if colors == nil then
        error(fmt.errors.required_value("colors"))
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

function ColorMapper:map(normFloat)
    return mapNormalizedToColor(normFloat, self.colors)
end


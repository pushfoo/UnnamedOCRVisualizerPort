require("localmath")
require("fmt")


--[[ Helpers to make rectangle bounds from various points.

Inspired by Python Arcade. All functions return an LTWH-ordered
set of coordinates.
]]
makeRectPoints = {
    ltwh = function (left, top, width, height)
        local right = left + width
        local bottom = top + height
        return {
            left,  top,
            right, top,
            right, bottom,
            left,  bottom
        }
    end,
    ltrb = function(left, top, right, bottom)
        return {
            left,  top,
            right, top,
            right, bottom,
            left,  bottom
        }
    end,
    xywh = function (center_x, center_y, width, height)
        local half_width = width / 2
        local half_height = height / 2
        local left   = center_x - half_width
        local right  = center_x + half_width
        local top    = center_y - half_height
        local bottom = center_y + half_height
        return {
            left,  top,
            right, top,
            right, bottom,
            left,  bottom
        }
    end
}


Rect = {}
function Rect:new(ltwh)
    local problem = typeCheckTable("ltwh", ltwh)
    -- print("table", ltwh)
    if problem then
        error(problem)
    end
    local left, top, width, height = unpack(ltwh)
    -- print(left, top, width, height)
    local instance = {
        left = left,
        top = top,
        width = width,
        height = height
    }

    self.__index = self
    instance.points = makeRectPoints.ltwh(left, top, width, height)
    return setmetatable(instance, self)
end


function fmtRectError(name, wrong)
    return format("%s: expected a point of length 2 or another Rect, but got %s", name, wrong)
end


function Rect:contains(other)
    local otherType = type(other)
    if otherType ~= "table" or not isVoLength then
        error(fmtRectError("TypeError", otherType))
    end
    local oLength = table.getn(other)
    if oLength == 2 then
        local x, y = other
        return valueIs(x, {ge=self.left, le=self.right}) and valueIs(y, {ge=self.top, le=self.bottom})
    end

    local otherMetatable = getmetatable(other, t)
    local useCoords = nil
    if otherMetatable == Rect then
        useCoords = {other.left, other.top, other.right, other.bottom}
    elseif oLength == 4 then
        useCoords = other
    else
        error(fmtRectError("TypeError", otherType))
    end

    local oLeft, oTop, oRight, oBottom = useCoords
    return (
        self.left <= oLeft
        and oRight <= self.right
        and self.top <= oTop
        and oBottom <= self.bottom
    )
end


rect = {}
rect.makeRectPoints = makeRectPoints

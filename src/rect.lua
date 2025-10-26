require("fmt")
local localmath = require("localmath")
local typeCheckTable = localmath.typeCheckTable
local valueIs = localmath.valueIs


local rect = {}

--[[ Helpers to make rectangle bounds from various points.

Inspired by Python Arcade. All functions return an LTWH-ordered
set of coordinates.
]]
rect.makePoints = {}


--- Convert {l, t, r, b} to inline {x, y, ...} coords.
---@param left number
---@param top number
---@param width number
---@param height number
---@return table<integer,number>
function rect.makePoints.ltwh(left, top, width, height)
    local right = left + width
    local bottom = top + height
    return {
        left,  top,
        right, top,
        right, bottom,
        left,  bottom
    }
end


--- Convert {l, t, r, b} to inline {x, y, ...} coords.
---@param left number
---@param top number
---@param right number
---@param bottom number
---@return table<integer,number>
function rect.makePoints.ltrb(left, top, right, bottom)
    return {
        left,  top,
        right, top,
        right, bottom,
        left,  bottom
    }
end


--- Convert {cx, cy, w, h} to inline {x, y, ...} coords.
---@param center_x number
---@param center_y number
---@param width number
---@param height number
---@return table<integer,number>
function rect.makePoints.xywh(center_x, center_y, width, height)
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


---@class Rect
local Rect = {}
rect.Rect = Rect

-- Create a new Rect.
---@param ltwh table<integer,number>|Rect|?
---@return Rect
function Rect:new(ltwh)
    local problem = typeCheckTable("ltwh", ltwh)
    if problem then
        error(problem)
    elseif getmetatable(ltwh) == Rect then
        ---@cast ltwh Rect
        return ltwh
    end
    ---@cast ltwh table<integer, number>
    local left, top, width, height = unpack(ltwh)
    -- print(left, top, width, height)
    local instance = {
        left = left,
        top = top,
        width = width,
        height = height
    }

    self.__index = self
    instance.points = rect.makePoints.ltwh(left, top, width, height)
    return setmetatable(instance, self)
end


---@param name string
---@param wrong string
---@return string
local function fmtRectError(name, wrong)
    return string.format("%s: expected a point of length 2 or another Rect, but got %s", name, wrong)
end


--- True if the rect contains a point or other rect.
---IMPORTANT: This uses inclusive bounds on all sides.
---@param other Rect|table<integer,number>
---@return boolean
function Rect:contains(other)
    local otherType = type(other)
    if otherType ~= "table" then
        error(fmtRectError("TypeError", otherType))
    end
    local oLength = #other
    if oLength == 2 then
        local x = other[1]
        local y = other[2]
        ---@diagnostic disable
        local betweenLeftRight = {ge=self.left, le=self.right}
        local betweenTopBottom = {ge=self.top, le=self.bottom}
        ---@diagnostic enable
        return valueIs(x, betweenLeftRight) and valueIs(y, betweenTopBottom)
    end

    local otherMetatable = getmetatable(other)
    local useCoords = nil
    if otherMetatable == Rect then
        ---@diagnostic disable-next-line
        useCoords = {other.left, other.top, other.right, other.bottom}
    elseif oLength == 4 then
        useCoords = other
    else
        error(fmtRectError("TypeError", otherType))
    end

    local oLeft = useCoords[1]
    local oTop = useCoords[2]
    local oRight = useCoords[3]
    local oBottom = useCoords[4]
    return (
        ---@diagnostic disable
        self.left <= oLeft
        and oRight <= self.right
        and self.top <= oTop
        and oBottom <= self.bottom
        ---@diagnostic enable
    )
end


return rect
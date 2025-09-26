-- TODO: Use the OOP-style API they added at some point?

-- Stub arg parsing
function love.load(args)
    local n_args = table.getn(args)
    local max_index = n_args - 1
    local message = {}
    local args_list = nil
    if n_args > 0 then
        for k, v in pairs(args) do
            message[k] = tostring(v)
        end
        args_list = table.concat(message, ", ")
    else
        args_list = "[ No args ? ]" 
    end
    print("Got args: " .. args_list)
end


--[[ Make a table of rectangular points using a top-left origin.

This is the Love2D convention for coordinates (see
their wiki page https://love2d.org/wiki/love.graphics).

  +---------------------> X axis
  |
  |         |-- w --|
  | (x,  y) +-------+ ---
  |         |       |  |
  |         |       |  h
  |         |       |  |
  |         +-------+ ---
  v
 Y axis
]]
function makeRectPoints(x, y, w, h)
    local lower_y = y + h
    local right_x = x + w
    local points = {
        x, y,
        right_x, y,
        right_x, lower_y,
        x, lower_y
    }
    return points
end


-- Temporarily stubs bboxes with a regular grid
function makeCells(cellSize)
    -- Last value is a flags table (see https://love2d.org/wiki/love.window.getMode)
    windowWidth, windowHeight, _ = love.window.getMode()
    
    local cells = {}
    local half_cell = cellSize / 2
    for y = half_cell * 3, windowHeight - half_cell, cellSize * 1.5 do
        --[[ Neuroscience tip: we'll use red and green for our axes b/c:
             1. Blue is very hard for the eye to perceive when "pure" 
             2. Color mixing in naive RGB space is awful
        ]]
        local red = (y + cellSize) / windowHeight
        for x = half_cell, windowWidth - half_cell, cellSize * 2 do
            local rectBounds = makeRectPoints(x, y, cellSize, cellSize)
            local green = (x + cellSize) / windowWidth
            local cell = {
                color = {red, green, 255},
                points = rectBounds
            }
            table.insert(cells, cell)
        end
    end
    return cells
end


local cells = makeCells(20)
local message = "Just stubbing some rectangles for now."

function love.draw()
    local windowWidth, _, _ = love.window.getMode()


    
    love.graphics.print(
        message,
        windowWidth / 2 - 105, 0)
    for i, cell in pairs(cells) do
        local r, g, b = cell.color
        local vertices = cell.points
        love.graphics.setColor(r, g, b)
        love.graphics.polygon("line", vertices) 
    end
end


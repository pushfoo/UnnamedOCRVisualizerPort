-- TODO: Use the OOP-style API they added at some point?
-- require("tsv")
require("fmt")
require("rect")
require("colors")
require("argparsing")

-- Return a value as-is
function passthru(s)
    return s
end


function doTableShow(t, whichPrint)
    p = whichPrint or print
    local joined = fmt.table(t)
    p(joined)
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
function makeCells(cellSize)
    -- Last value is a flags table (see https://love2d.org/wiki/love.window.getMode)
    windowWidth, windowHeight, _ = love.window.getMode()
    local mapper = ColorMapper:new()
    local cells = {}
    local half_cell = cellSize / 2
    for y = half_cell * 3, windowHeight - half_cell, cellSize * 1.5 do
        --[[ Neuroscience tip: we'll use red and green for our axes b/c:
             1. Blue is very hard for the eye to perceive when "pure" 
             2. Color mixing in naive RGB space is awful
        ]]
        -- local red = (y + cellSize) / windowHeight
        for x = half_cell, windowWidth - half_cell, cellSize * 2 do
            local rectBounds = Rect:new{x, y, cellSize, cellSize}
            local green = (x + cellSize) / windowWidth
            local c = mapper:map(green) 
            local cell = {
                color = c,--{red, green, 1.0, 1.00},
                rect = rectBounds
            }
            table.insert(cells, cell)
        end
    end
    return cells
end


state = nil


function showMessage(message)
   local windowWidth, _, _ = love.window.getMode()
   love.graphics.print(message,
        (windowWidth / 2) - 180, 0)
end

function love.load(args)
    state = {
        image = nil,
        cells = makeCells(20),
        message = "These are now color-mapped rectangles (from 0.0 to 1.0)!"
    }
    -- Stubs arg parsing
    local parser = parse.State:new{args=args}

    local n_args = table.getn(args)
    local message = {}
    local args_list = nil
end

WHITE = {1.0, 1.0, 1.0, 1.0}
function love.draw()
    local windowWidth, _, _ = love.window.getMode()
    love.graphics.setColor(WHITE)
    showMessage(state.message) 
    for i, cell in pairs(state.cells) do
        local vertices = cell.rect.points
        love.graphics.setColor(cell.color)
        love.graphics.polygon("line", vertices) 
    end
end


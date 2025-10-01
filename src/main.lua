-- TODO: Use the OOP-style API they added at some point?
require("fmt")
require("util")
require("rect")
require("colors")
require("args")
require("tesseract")

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
        for x = half_cell, windowWidth - half_cell, cellSize * 2 do
            local rectBounds = Rect:new{x, y, cellSize, cellSize}
            local green = (x + cellSize) / windowWidth
            local c = mapper:map(green)
            local cell = {
                color = c,
                rect = rectBounds
            }
            table.insert(cells, cell)
        end
    end
    return cells
end


state = nil

function renderAsPolygons(tsvData)
    local cells = {}
    local mapper = ColorMapper:new()
    for i, item in ipairs(tsvData) do
        print(i, item)
        for k, v in pairs(item) do
            print(k, v)
        end
        local conf = item.conf
        if conf ~= nil then
            if conf >= 0 then
                local normConf = conf / 100
                local color = mapp
                local t = {
                    rect = item.rect,
                    color = mapper:map(normConf)
                }
                table.insert(cells, t)
            end
        end
    end
    return cells
end

function showMessage(message)
   local windowWidth, _, _ = love.window.getMode()
   love.graphics.print(message,
        (windowWidth / 2) - 180, 0)
end

function love.load(args)
    state = {
        image = nil,
        cells = nil,
        -- cells = makeCells(20),
        message = "", -- "These are now color-mapped rectangles (from 0.0 to 1.0)!",
        image = nil,
        tesseract = TesseractRunner:new(),
        filename = args[1]
    }
    state.image = util.external.load_image(state.filename)
    local tsvDataRaw = state.tesseract:recognize(state.filename)
    state.cells = renderAsPolygons(tsvDataRaw)
    print(string.format("Got %i items", #(state.cells)))

end

function love.update(dt)

end

function love.draw()
    local windowWidth, _, _ = love.window.getMode()
    love.graphics.setColor(WHITE)
    local message = state.message
    if message then
        showMessage(state.message)
    end
    love.graphics.draw(state.image)
    for i, cell in pairs(state.cells) do
        local vertices = cell.rect.points
        love.graphics.setColor(cell.color)
        love.graphics.polygon("line", vertices)
    end
end


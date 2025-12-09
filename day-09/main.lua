io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local part1 = require("part1")

local TILE_SIZE = 16
local points = {}
local grid = {}
local max_bounds = { x_max = 0, y_max = 0 }

function love.load()
    love.window.setMode(800, 600, { resizable = false })
    love.window.setTitle("Day 9")

    -- Load points
    points, max_bounds = part1.get_points("./inputs/test.txt")

    -- Create grid
    for _, point in ipairs(points) do
        if not grid[point.y] then
            grid[point.y] = {}
        end
        grid[point.y][point.x] = true
    end
end

function love.update(dt)
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.12)

    -- Draw grid lines
    love.graphics.setColor(0.2, 0.2, 0.22)
    for y = 0, max_bounds.y_max + 1 do
        for x = 0, max_bounds.x_max + 1 do
            love.graphics.rectangle("line", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw filled points as red squares
    love.graphics.setColor(0.9, 0.1, 0.1)
    for y, row in pairs(grid) do
        for x, _ in pairs(row) do
            love.graphics.rectangle("fill", x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        end
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

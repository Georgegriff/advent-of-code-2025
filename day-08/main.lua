io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local IsometricGrid = require("utils.isometric_grid")

-- Window configuration
WINDOW_WIDTH = 1000
WINDOW_HEIGHT = 600

local isometricGrid

-- Draw floor as isometric tiles
local function drawFloor()
    if not isometricGrid then
        return
    end

    -- Draw floor for all possible grid positions as filled isometric diamonds
    love.graphics.setColor(0.4, 0.4, 0.42)
    for y = 0, isometricGrid.mapHeight - 1 do
        for x = 0, isometricGrid.mapWidth - 1 do
            local vertices = isometricGrid:getTileVertices(x, y)
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Draw subtle grid lines on top
    love.graphics.setColor(0.35, 0.35, 0.37)
    love.graphics.setLineWidth(1)
    for y = 0, isometricGrid.mapHeight - 1 do
        for x = 0, isometricGrid.mapWidth - 1 do
            local vertices = isometricGrid:getTileVertices(x, y)
            love.graphics.polygon("line", vertices)
        end
    end
end

local function draw_background()
    love.graphics.clear(0.05, 0.15, 0.1)
end

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Love2D - Day 8")

    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    -- Create isometric grid with default dimensions
    isometricGrid = IsometricGrid(128, 10, 10)
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    isometricGrid:centerOnScreen(screenWidth, screenHeight)
end

function love.update(dt)
    if isometricGrid then
        isometricGrid:update(dt)
    end
end

function love.wheelmoved(x, y)
    if isometricGrid then
        isometricGrid:wheelmoved(x, y)
    end
end

function love.draw()
    draw_background()
    drawFloor()
end

-- Reset position when R is pressed
-- function love.keypressed(key)

-- end

local M = {}

function M.add(a, b)
    return a + b
end

return M

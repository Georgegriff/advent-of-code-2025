io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local BORDER = 0
local tileSrc = "empty.png"

local IsometricGrid = require("utils.isometric_grid")
local Tile = require("ui.tile")

-- Draw isometric tiles
-- tiles can be either:
--   - A Tile instance used for all tiles
--   - A function(x, y) that returns a Tile instance for each position
--   - A 2D array [y][x] of Tile instances
local function drawIsometricTiles(grid, tiles)
    for y = 0, grid.mapHeight - 1 do
        for x = 0, grid.mapWidth - 1 do
            local tile
            if type(tiles) == "function" then
                tile = tiles(x, y)
            elseif type(tiles) == "table" and tiles[y] and tiles[y][x] then
                tile = tiles[y][x]
            else
                tile = tiles
            end
            if tile and tile.draw then
                tile:draw(grid, x, y)
            end
        end
    end
end

-- Draw crosshair at screen center
local function drawCrosshair()
    love.graphics.setColor(1, 0, 0)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    love.graphics.line(0, screenHeight / 2, screenWidth, screenHeight / 2)
    love.graphics.line(screenWidth / 2, 0, screenWidth / 2, screenHeight)
end

-- Draw isometric debug visualization
local function drawIsometricDebug(grid)
    -- Draw tile outlines
    love.graphics.setColor(0.2, 0.8, 0.4)
    for y = 0, grid.mapHeight - 1 do
        for x = 0, grid.mapWidth - 1 do
            local vertices = grid:getTileVertices(x, y)
            love.graphics.polygon("line", vertices)
        end
    end
    -- Draw crosshair
    drawCrosshair()
end

local grid
local defaultTile
local panSpeed = 200
local zoomSpeed = 0.1
local minZoom = 0.1
local maxZoom = 5.0

function love.load()
    love.graphics.setDefaultFilter("linear", "linear")
    grid = IsometricGrid(128, 5, 5)
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    grid:centerOnScreen(screenWidth, screenHeight)

    local tileImage = love.graphics.newImage(tileSrc)
    -- tileImage:setFilter("nearest", "nearest")
    tileImage:setWrap("clamp", "clamp")
    local imgW, imgH = tileImage:getDimensions()
    local tileQuad = love.graphics.newQuad(
        BORDER,
        BORDER,
        imgW,
        imgH,
        imgW,
        imgH
    )
    defaultTile = Tile(tileImage, tileQuad)
end

function love.update(dt)
    -- Pan with arrow keys or WASD
    local panX, panY = 0, 0
    if love.keyboard.isDown("left", "a") then
        panX = panSpeed * dt
    end
    if love.keyboard.isDown("right", "d") then
        panX = -panSpeed * dt
    end
    if love.keyboard.isDown("up", "w") then
        panY = panSpeed * dt
    end
    if love.keyboard.isDown("down", "s") then
        panY = -panSpeed * dt
    end

    if panX ~= 0 or panY ~= 0 then
        grid.offsetX = grid.offsetX + panX
        grid.offsetY = grid.offsetY + panY
    end
end

function love.wheelmoved(x, y)
    -- Zoom with mouse wheel
    local zoomFactor = 1.0 + (y * zoomSpeed)
    local newZoom = grid.zoom * zoomFactor
    newZoom = math.max(minZoom, math.min(maxZoom, newZoom))
    grid.zoom = newZoom
end

function love.draw()
    drawIsometricTiles(grid, defaultTile)
    -- drawIsometricDebug(grid)
end

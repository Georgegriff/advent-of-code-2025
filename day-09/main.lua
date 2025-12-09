io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local m = require("part2")

local TILE_SIZE = 16 -- Will be calculated dynamically
local points = {}
local grid = {}
local max_bounds = { x_max = 0, y_max = 0 }
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local PADDING = 20

---@param points  Point[]
function getPolygon(points)
    local vertices = {}
    for _, point in ipairs(points) do
        table.insert(vertices, point.x)
        table.insert(vertices, point.y)
    end
    return vertices
end

---@return boolean
function is_inside_area(physTriangles, rect)
    for _, point in ipairs(rect) do
        if not checkCollision(physTriangles, point.x, point.y) then
            return false
        end
    end
    return true
end

---@return table[]
function get_rects(physTriangles, points)
    local rects = {}
    local max_area = 0
    for i, pointA in ipairs(points) do
        for j = i + 1, #points do
            local pointB = points[j]
            local rect = m.project_rect(pointA, pointB)
            if is_inside_area(physTriangles, rect) then
                local area = m.get_area(pointA, pointB)
                if area > max_area then
                    max_area = area
                end
                table.insert(rects, rect)
            end
        end
    end
    print(string.format("Max area: %s", max_area))
    return rects
end

function checkCollision(physTriangles, x, y)
    for _, triangle in ipairs(physTriangles) do
        if (triangle.fixture:testPoint(x, y)) then
            return true
        end
    end

    return false
end

local chainShape = nil
local chainBody = nil
local chainFixture = nil
local rects = {}
local world
function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Day 9")

    -- Load points
    points, max_bounds = m.get_points("./inputs/test.txt")

    -- Calculate dynamic tile size based on grid dimensions
    local grid_width = max_bounds.x_max + 1
    local grid_height = max_bounds.y_max + 1
    local max_tile_width = (WINDOW_WIDTH - 2 * PADDING) / grid_width
    local max_tile_height = (WINDOW_HEIGHT - 2 * PADDING) / grid_height
    TILE_SIZE = math.max(1, math.min(max_tile_width, max_tile_height))

    print(string.format("Grid dimensions: %dx%d, Tile size: %.2f", grid_width, grid_height, TILE_SIZE))

    world = love.physics.newWorld(0, 0, true)

    -- Create chain shape from points
    local vertices = getPolygon(points)
    chainShape = love.physics.newChainShape(true, vertices) -- true for looping
    chainBody = love.physics.newBody(world, 0, 0, "static")
    chainFixture = love.physics.newFixture(chainBody, chainShape)

    print(string.format("Chain shape created with %d vertices", #vertices / 2))

    rects = get_rects({ { fixture = chainFixture, body = chainBody, shape = chainShape } }, points)


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

    -- Draw grid lines (only if tile size is large enough)
    if TILE_SIZE >= 4 then
        love.graphics.setColor(0.2, 0.2, 0.22)
        for y = 0, max_bounds.y_max do
            for x = 0, max_bounds.x_max do
                love.graphics.rectangle("line", PADDING + x * TILE_SIZE, PADDING + y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
            end
        end
    end

    -- Draw filled points as red ellipses
    love.graphics.setColor(0.9, 0.1, 0.1)
    local ellipse_size = math.max(1, TILE_SIZE / 3)
    for y, row in pairs(grid) do
        for x, _ in pairs(row) do
            love.graphics.ellipse("fill", PADDING + x * TILE_SIZE, PADDING + y * TILE_SIZE, ellipse_size, ellipse_size)
        end
    end


    -- Draw rectangles with varying colors
    for i, rect in ipairs(rects) do
        -- Generate color using math - create rainbow effect
        local hue = (i / #rects) * 6.28318      -- Full circle in radians
        local r = 0.5 * math.sin(hue)
        local g = 0.5 * math.sin(hue + 2.094)   -- 120 degrees offset
        local b = 0.5 * math.sin(hue + 4.189)   -- 240 degrees offset
        local a = 0.3 + 0.2 * math.sin(i * 0.5) -- Vary opacity between 0.3 and 0.5

        love.graphics.setColor(r, g, b, a)

        -- Convert rect points to scaled vertices for polygon drawing
        local vertices = {}
        for _, point in ipairs(rect) do
            table.insert(vertices, PADDING + point.x * TILE_SIZE)
            table.insert(vertices, PADDING + point.y * TILE_SIZE)
        end

        if #vertices >= 6 then -- Need at least 3 points (6 values) for a polygon
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Draw physics chain (scale from grid to pixel coordinates)
    love.graphics.setColor(1, 1, 1, 1)
    if chainShape then
        local points = { chainBody:getWorldPoints(chainShape:getPoints()) }
        local scaledPoints = {}
        for i = 1, #points do
            scaledPoints[i] = PADDING + points[i] * TILE_SIZE
        end
        -- Draw as a closed line loop
        if #scaledPoints >= 4 then
            for i = 1, #scaledPoints - 2, 2 do
                local x1, y1 = scaledPoints[i], scaledPoints[i + 1]
                local x2, y2 = scaledPoints[i + 2], scaledPoints[i + 3]
                love.graphics.line(x1, y1, x2, y2)
            end
            -- Close the loop
            love.graphics.line(scaledPoints[#scaledPoints - 1], scaledPoints[#scaledPoints],
                scaledPoints[1], scaledPoints[2])
        end
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local m = require("part2")

local TILE_SIZE = 16
local points = {}
local grid = {}
local max_bounds = { x_max = 0, y_max = 0 }

---@param points  Point[]
function getPolygon(points)
    local vertices = {}
    for _, point in ipairs(points) do
        table.insert(vertices, point.x + 0.5)
        table.insert(vertices, point.y + 0.5)
    end
    return vertices
end

---Get the center point of a cell in pixel coordinates
---@param x number Grid x coordinate
---@param y number Grid y coordinate
---@return number, number Center x and y in pixels
function getCellCenter(x, y)
    return x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2
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

local triangles = nil
local trianglesPhs = {}
local rects = {}
local world
function love.load()
    love.window.setMode(800, 600, { resizable = false })
    love.window.setTitle("Day 9")

    -- Load points
    points, max_bounds = m.get_points("./inputs/test.txt")
    triangles = love.math.triangulate(getPolygon(points))
    world = love.physics.newWorld(0, 0, true)

    -- Print triangle coordinates (compact)
    for i = 1, #triangles do
        local tri = triangles[i]
        print(string.format("Triangle %d: (%.2f,%.2f) (%.2f,%.2f) (%.2f,%.2f)",
            i, tri[1], tri[2], tri[3], tri[4], tri[5], tri[6]))
    end
    for i = 1, #triangles do
        local poly = love.physics.newPolygonShape(unpack(triangles[i]))
        local body = love.physics.newBody(world, 0, 0, "static")

        local fixture = love.physics.newFixture(body, poly)
        local trianglePhyShape = {
            bounds = triangles,
            shape = poly,
            body = body,
            fixture = fixture
        }
        table.insert(trianglesPhs, trianglePhyShape)
    end

    rects = get_rects(trianglesPhs, points)


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


    -- Draw rectangles with varying colors
    for i, rect in ipairs(rects) do
        -- Generate color using math - create rainbow effect
        local hue = (i / #rects) * 6.28318          -- Full circle in radians
        local r = 0.5 + 0.5 * math.sin(hue)
        local g = 0.5 + 0.5 * math.sin(hue + 2.094) -- 120 degrees offset
        local b = 0.5 + 0.5 * math.sin(hue + 4.189) -- 240 degrees offset
        local a = 0.3 + 0.2 * math.sin(i * 0.5)     -- Vary opacity between 0.3 and 0.5

        love.graphics.setColor(r, g, b, a)

        -- Convert rect points to scaled vertices for polygon drawing
        local vertices = {}
        for _, point in ipairs(rect) do
            table.insert(vertices, point.x * TILE_SIZE)
            table.insert(vertices, point.y * TILE_SIZE)
        end

        if #vertices >= 6 then -- Need at least 3 points (6 values) for a polygon
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Draw physics triangles (scale from grid to pixel coordinates)
    love.graphics.setColor(1, 1, 1, 1)
    for _, tri in ipairs(trianglesPhs) do
        local points = { tri.body:getWorldPoints(tri.shape:getPoints()) }
        local scaledPoints = {}
        for i = 1, #points do
            scaledPoints[i] = points[i] * TILE_SIZE
        end
        love.graphics.polygon("line", scaledPoints)
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

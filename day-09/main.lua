io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local m = require("part2")

local points = {}
local grid = {}
local max_bounds = { x_max = 0, y_max = 0 }
local WINDOW_WIDTH = 800
local WINDOW_HEIGHT = 600
local PADDING = 20
local scale = 1
local offset_x = 0
local offset_y = 0

---@param points  Point[]
function getPolygon(points)
    local vertices = {}
    for _, point in ipairs(points) do
        table.insert(vertices, point.x)
        table.insert(vertices, point.y)
    end
    return vertices
end

function checkCollision(physTriangles, x, y)
    for _, triangle in ipairs(physTriangles) do
        if (triangle.fixture:testPoint(x, y)) then
            return true
        end
    end

    return false
end

---Check if rectangle is entirely inside the area defined by the polygon
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

local triangles = nil
local trianglesPhs = {}
local rects = {}
local world
function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Day 9")

    -- Load points
    points, max_bounds = m.get_points("./inputs/test.txt")

    -- Calculate scale to fit everything in window
    local grid_width = max_bounds.width
    local grid_height = max_bounds.height
    local scale_x = (WINDOW_WIDTH - 2 * PADDING) / grid_width
    local scale_y = (WINDOW_HEIGHT - 2 * PADDING) / grid_height
    scale = math.min(scale_x, scale_y)
    offset_x = PADDING
    offset_y = PADDING

    print(string.format("Grid dimensions: %dx%d, Scale: %.6f", grid_width, grid_height, scale))
    print(string.format("Bounds: x[%d-%d], y[%d-%d]", max_bounds.x_min, max_bounds.x_max, max_bounds.y_min,
        max_bounds.y_max))

    world = love.physics.newWorld(0, 0, true)

    -- Triangulate the polygon
    triangles = love.math.triangulate(getPolygon(points))

    -- Create physics triangles from triangulation
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

    -- Draw filled points as red dots
    love.graphics.setColor(0.9, 0.1, 0.1)
    local dot_radius = math.max(1, math.min(3, scale * 0.5))
    for y, row in pairs(grid) do
        for x, _ in pairs(row) do
            local px = offset_x + x * scale
            local py = offset_y + y * scale
            love.graphics.circle("fill", px, py, dot_radius)
        end
    end

    -- Draw rectangles with varying colors
    for i, rect in ipairs(rects) do
        -- Generate color using math - create rainbow effect
        local hue = (i / #rects) * 6.28318
        local r = 0.5 + 0.5 * math.sin(hue)
        local g = 0.5 + 0.5 * math.sin(hue + 2.094)
        local b = 0.5 + 0.5 * math.sin(hue + 4.189)
        local a = 0.3 + 0.2 * math.sin(i * 0.5)

        love.graphics.setColor(r, g, b, a)

        -- Convert rect points to scaled vertices for polygon drawing
        local vertices = {}
        for _, point in ipairs(rect) do
            table.insert(vertices, offset_x + point.x * scale)
            table.insert(vertices, offset_y + point.y * scale)
        end

        if #vertices >= 6 then
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Draw physics triangles
    love.graphics.setColor(1, 1, 1, 1)
    for _, tri in ipairs(trianglesPhs) do
        local points = { tri.body:getWorldPoints(tri.shape:getPoints()) }
        local scaledPoints = {}
        for i = 1, #points, 2 do
            table.insert(scaledPoints, offset_x + points[i] * scale)
            table.insert(scaledPoints, offset_y + points[i + 1] * scale)
        end
        love.graphics.polygon("line", scaledPoints)
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local Point = require("utils.point")
local M = {}

local unpack = table.unpack or unpack

---@param polygon table[]
---@param x number
---@param y number
---@return boolean
function M.point_in_polygon(polygon, x, y)
    local n = #polygon

    -- Check if point is on any edge
    for i = 1, n do
        local j = (i % n) + 1
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        local min_x, max_x = math.min(xi, xj), math.max(xi, xj)
        local min_y, max_y = math.min(yi, yj), math.max(yi, yj)

        if x >= min_x and x <= max_x and y >= min_y and y <= max_y then
            local cross = (y - yi) * (xj - xi) - (x - xi) * (yj - yi)
            if math.abs(cross) < 1e-10 then
                return true -- Point is on the boundary
            end
        end
    end

    -- Ray casting for interior points
    local inside = false
    local j = n

    for i = 1, n do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end

        j = i
    end

    return inside
end

function M.solution(input_file)
    local points = M.get_points(input_file)
    local max_area = M.find_max_area(points)
    return max_area
end

---@param a {x: number, y: number}
---@param c {x: number, y: number}
---@return number[]
function M.project_rect(a, c)
    -- if (a.y == c.y or a.x == c.x) then
    --     return {
    --         a.x, a.y,
    --         a.x, a.y,
    --         c.x, c.y,
    --         c.x, c.y
    --     }
    -- end
    -- other points in the rect, centered on tiles (matching triangle coordinates)
    local b = { x = a.x, y = c.y }
    local d = { x = c.x, y = a.y }
    local a_centered = { x = a.x, y = a.y }
    local c_centered = { x = c.x, y = c.y }
    local points = { a_centered, b, c_centered, d }

    return points
end

-- Check if segment (x1,y1)-(x2,y2) intersects segment (x3,y3)-(x4,y4)
function M.segments_intersect(x1, y1, x2, y2, x3, y3, x4, y4)
    local denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)
    if math.abs(denom) < 1e-10 then return false end

    local ua = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
    local ub = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom

    return ua > 0 and ua < 1 and ub > 0 and ub < 1
end

---@param points Point[]
---@return number,  {a: Point, b: Point}
function M.find_max_area(points)
    local max_area = 0
    local max_point_a = nil
    local max_point_b = nil

    for i, pointA in ipairs(points) do
        for j = i + 1, #points do
            local pointB = points[j]

            -- Get the 4 corners of the rectangle
            local min_x = math.min(pointA.x, pointB.x)
            local max_x = math.max(pointA.x, pointB.x)
            local min_y = math.min(pointA.y, pointB.y)
            local max_y = math.max(pointA.y, pointB.y)

            -- Check if all 4 corners are inside or on the polygon boundary
            if M.point_in_polygon(points, min_x, min_y) and
                M.point_in_polygon(points, max_x, min_y) and
                M.point_in_polygon(points, min_x, max_y) and
                M.point_in_polygon(points, max_x, max_y) then
                -- For concave polygons, also check that no polygon edge crosses rectangle edges
                local valid = true
                local rect_edges = {
                    { min_x, min_y, max_x, min_y }, -- top
                    { max_x, min_y, max_x, max_y }, -- right
                    { max_x, max_y, min_x, max_y }, -- bottom
                    { min_x, max_y, min_x, min_y }, -- left
                }

                local n = #points
                for k = 1, n do
                    local l = (k % n) + 1
                    local px1, py1 = points[k].x, points[k].y
                    local px2, py2 = points[l].x, points[l].y

                    for _, re in ipairs(rect_edges) do
                        if M.segments_intersect(px1, py1, px2, py2, re[1], re[2], re[3], re[4]) then
                            valid = false
                            break
                        end
                    end
                    if not valid then break end
                end

                if valid then
                    local area = M.get_area(pointA, pointB)
                    if area > max_area then
                        max_area = area
                        max_point_a = pointA
                        max_point_b = pointB
                    end
                end
            end
        end
    end
    return max_area, { a = max_point_a, b = max_point_b }
end

---@return Point[], {x_max: number, y_max: number, x_min: number, y_min: number, width: number, height: number}
function M.get_points(input_file)
    local points = {}
    local x_max = -math.huge
    local y_max = -math.huge
    local x_min = math.huge
    local y_min = math.huge

    file_utils.read_file_lines(input_file, function(line)
        local x, y = unpack(string_utils.split(line, ",", function(str)
            return tonumber(str)
        end))

        local point = Point(x, y, "#")
        if x > x_max then x_max = x end
        if y > y_max then y_max = y end
        if x < x_min then x_min = x end
        if y < y_min then y_min = y end
        table.insert(points, point)
    end)

    -- Normalize points to start at (0, 0)
    for _, point in ipairs(points) do
        point.x = point.x - x_min
        point.y = point.y - y_min
    end

    local width = x_max - x_min
    local height = y_max - y_min

    return points, {
        x_max = width,
        y_max = height,
        x_min = 0,
        y_min = 0,
        width = width,
        height = height
    }
end

---@param a {x: number, y: number}
---@param b {x: number, y: number}
function M.get_area(a, b)
    return ((math.abs(b.y - a.y)) + 1) * ((math.abs(b.x - a.x)) + 1)
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    local start_time = os.clock()
    local solution = M.solution(input_file)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

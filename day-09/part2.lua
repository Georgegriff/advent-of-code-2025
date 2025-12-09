local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local Point = require("utils.point")
local M = {}

local unpack = table.unpack or unpack

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

---@param points Point[]
---@return number,  {a: Point, b: Point}
function M.find_max_area(points)
    local max_area = 0
    local max_point_a = nil
    local max_point_b = nil
    for i, pointA in ipairs(points) do
        for j = i + 1, #points do
            local pointB = points[j]
            local area = M.get_area(pointA, pointB)
            if area > max_area then
                max_area = area
                max_point_a = pointA
                max_point_b = pointB
            end
        end
    end
    return max_area, { a = max_point_a, b = max_point_b }
end

---@return Point[], {x_max: number, y_max: number}
function M.get_points(input_file)
    local points = {}
    local x_max = 0
    local y_max = 0
    file_utils.read_file_lines(input_file, function(line)
        local x, y = unpack(string_utils.split(line, ",", function(str)
            return tonumber(str)
        end))

        local point = Point(x, y, "#")
        if x > x_max then
            x_max = x
        end
        if y > y_max then
            y_max = y
        end
        table.insert(points, point)
    end)
    return points, { x_max = x_max, y_max = y_max }
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

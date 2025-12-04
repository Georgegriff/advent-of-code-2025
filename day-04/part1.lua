local file_utils = require("utils.file")
local script_utils = require("utils.script")
local Point = require("utils.point")
local Grid = require("utils.grid")
local M = {
    ---@type Grid | nil
    grid = nil
}

local PAPER = "@"

function M.solution(input_file)
    ---@type Grid
    local grid = M.create_grid(input_file)
    local solution = 0
    grid:each_point(function(point)
        if M.is_coordinate_allowed(point.x, point.y) then
            solution = solution + 1
        end
    end)
    return solution
end

function M.is_coordinate_allowed(x, y)
    local point = M.grid.coordinates[y][x]
    local PROXIMITY_LIMIT = 4
    local proximity_counter = 0
    if point.entity == PAPER then
        -- north
        local checks = {
            --north
            { x = point.x,     y = point.y - 1 },
            -- north-east
            { x = point.x + 1, y = point.y - 1 },
            -- east
            { x = point.x + 1, y = point.y },
            -- south-east
            { x = point.x + 1, y = point.y + 1 },
            -- south
            { x = point.x,     y = point.y + 1 },
            -- south-west
            { x = point.x - 1, y = point.y + 1 },
            -- west
            { x = point.x - 1, y = point.y },
            -- north-west
            { x = point.x - 1, y = point.y - 1 }

        }
        for _, currentCheck in ipairs(checks) do
            if M.grid:in_bounds(currentCheck.x, currentCheck.y) then
                local pointAtCheck = M.grid.coordinates[currentCheck.y][currentCheck.x]
                if pointAtCheck.entity == PAPER then
                    proximity_counter = proximity_counter + 1
                end
                if proximity_counter >= PROXIMITY_LIMIT then
                    return false
                end
            end
        end
        return true
    end
    return false
end

function M.create_grid(input_file)
    M.grid = Grid()
    local row = 0
    file_utils.read_file_lines(input_file, function(line)
        row = row + 1
        for x = 1, #line do
            local c = line:sub(x, x)
            local point = Point(x, row, c)
            M.grid:add_point(point)
        end
    end)
    return M.grid
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

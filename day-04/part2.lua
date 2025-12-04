local file_utils = require("utils.file")
local script_utils = require("utils.script")
local Point = require("utils.point")
local Grid = require("utils.grid")
local Set = require("utils.set")
local M = {
    ---@type Grid | nil
    grid = nil
}

local PAPER = "@"
local EMPTY = "."

function M.solution(input_file)
    ---@type Grid
    local grid = M.create_grid(input_file)
    ---@type Set
    local allowed_points = Set()
    function checkPoint(point)
        -- check point
        if allowed_points:has(point) then
            return
        end
        if M.is_coordinate_allowed(point.x, point.y) then
            allowed_points:add(point)
            point.entity = EMPTY

            local adjacentPoints = M.adjacent_points(point)
            for _, adjPoint in ipairs(adjacentPoints) do
                if not allowed_points:has(adjPoint) then
                    -- recheck
                    checkPoint(adjPoint)
                end
            end
        end
    end

    grid:each_point(function(p)
        checkPoint(p)
    end)
    return #allowed_points
end

function M.adjacent_matrices()
    return {
        --north
        { x = 0,  y = -1 },
        -- north-east
        { x = 1,  y = -1 },
        -- east
        { x = 1,  y = 0 },
        -- south-east
        { x = 1,  y = 1 },
        -- south
        { x = 0,  y = 1 },
        -- south-west
        { x = -1, y = 1 },
        -- west
        { x = -1, y = 0 },
        -- north-west
        { x = -1, y = -1 }
    }
end

---@param point Point
function M.adjacent_points(point)
    local points = {}
    local matrices = M.adjacent_matrices()
    for _, matrix in ipairs(matrices) do
        local x = point.x + matrix.x
        local y = point.y + matrix.y
        if M.grid:in_bounds(x, y) then
            local adjPoint = M.grid.coordinates[y][x]
            table.insert(points, adjPoint)
        end
    end
    return points
end

function M.is_coordinate_allowed(x, y)
    local point = M.grid.coordinates[y][x]
    local PROXIMITY_LIMIT = 4
    local proximity_counter = 0
    if point.entity == PAPER then
        local checks = M.adjacent_points(point)
        for _, pointAtCheck in ipairs(checks) do
            if pointAtCheck.entity == PAPER then
                proximity_counter = proximity_counter + 1
            end
            if proximity_counter >= PROXIMITY_LIMIT then
                return false
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
    local input_file = arg[1] or "./inputs/input.txt"
    local start_time = os.clock()
    local solution = M.solution(input_file)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

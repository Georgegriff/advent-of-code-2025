local file_utils = require("utils.file")
local Grid = require("utils.grid")
local Point = require("utils.point")
local script_utils = require("utils.script")
local M = {}
local Set = require("utils.set")

local ENTITIES = {
    SPACE = ".",
    START = "S",
    SPLITTER = "^",
    BEAM = "|"
}

local DIRECTION = {
    UP = "up",
    DOWN = "down",
    LEFT = "left",
    RIGHT = "right"
}

function M.solution(input_file)
    ---@type Grid
    local grid, start_point = M.create_grid(input_file)
    ---@type Set
    local split_points = Set()
    M.follow_beam(start_point, grid, split_points)
    return #split_points
end

---@param point Point | nil
---@param grid Grid
---@param split_points_set Set
function M.follow_beam(point, grid, split_points_set)
    if point == nil or (point.entity ~= ENTITIES.SPACE and point.entity ~= ENTITIES.START) then
        return
    end


    if point.entity == ENTITIES.SPACE then
        point.entity = ENTITIES.BEAM
    end
    local downPoint = point
    while (true) do
        downPoint = M.get_point_at(downPoint, grid, DIRECTION.DOWN)
        if downPoint == nil or downPoint.entity == ENTITIES.SPLITTER then
            break
        end
        if downPoint.entity == ENTITIES.SPACE then
            downPoint.entity = ENTITIES.BEAM
        end
    end
    if downPoint == nil then
        return
    end


    split_points_set:add(downPoint)
    local left_point = M.get_point_at(downPoint, grid, DIRECTION.LEFT)
    if left_point ~= nil and left_point.entity == ENTITIES.BEAM then
        left_point = nil
    end
    M.follow_beam(left_point, grid, split_points_set)

    local right_point = M.get_point_at(downPoint, grid, DIRECTION.RIGHT)
    if right_point ~= nil and right_point.entity == ENTITIES.BEAM then
        right_point = nil
    end
    M.follow_beam(right_point, grid, split_points_set)


    return
end

---@param point Point
---@param grid Grid
---@param xOffset number
---@param yOffset number
---@return Point|nil
function M.get_offset_point(point, grid, xOffset, yOffset)
    local newX = point.x + xOffset
    local newY = point.y + yOffset
    if not grid:in_bounds(newX, newY) then
        return nil
    end
    return grid.coordinates[newY][newX]
end

---@param point Point
---@param grid Grid
---@param direction string
---@return Point|nil
function M.get_point_at(point, grid, direction)
    if direction == DIRECTION.UP then
        return M.get_offset_point(point, grid, 0, -1)
    elseif direction == DIRECTION.DOWN then
        return M.get_offset_point(point, grid, 0, 1)
    elseif direction == DIRECTION.LEFT then
        return M.get_offset_point(point, grid, -1, 0)
    elseif direction == DIRECTION.RIGHT then
        return M.get_offset_point(point, grid, 1, 0)
    end
end

function M.create_grid(input_file)
    M.grid = Grid()
    M.start_point = nil
    local row = 0
    file_utils.read_file_lines(input_file, function(line)
        row = row + 1
        for x = 1, #line do
            local c = line:sub(x, x)
            ---@type Point
            local point = Point(x, row, c)
            if point.entity == ENTITIES.START then
                M.start_point = point
            end
            M.grid:add_point(point)
        end
    end)
    return M.grid, M.start_point
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

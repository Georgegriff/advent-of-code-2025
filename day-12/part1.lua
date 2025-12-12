local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local M = {}

---@class GridInfo
---@field area number

---@class Input
---@identifier string
---@field area number
---@field counts number[]

local unpack = unpack or table.unpack

---@param input Input
---@param grids GridInfo[]
---@return boolean
function M.is_valid_input(input, grids)
    local area_left = input.area
    for index, index_count in ipairs(input.counts) do
        local grid = grids[index]
        local grid_area_requirements = grid.area * index_count
        area_left = area_left - grid_area_requirements
    end

    return area_left >= 0
end

function M.solution(input_file)
    ---@type GridInfo[]
    local grids = {}
    local valid_inputs = {}
    ---@type GridInfo|nil
    local current_grid = nil

    file_utils.read_file_lines(input_file, function(line)
        if line == "" then
            -- we have reset
            table.insert(grids, current_grid)
            current_grid = nil
        end

        if current_grid ~= nil then
            for i = 1, #line do
                local char = line:sub(i, i)
                if char == "#" then
                    current_grid.area = current_grid.area + 1
                end
            end
        else
            if line:find(":", 1, true) then
                if line:find("x", 1, true) then
                    -- press inputs line.
                    local area_str, inputs_str = unpack(string_utils.split(line, ":"))
                    local w, h = unpack(string_utils.split(area_str, "x", function(str) return tonumber(str) end))
                    ---@type Input

                    local counts = string_utils.split(inputs_str, " ", function(str) return tonumber(str) end)
                    local input = {
                        identifier = line,
                        area = w * h,
                        counts = counts
                    }
                    if M.is_valid_input(input, grids) then
                        table.insert(valid_inputs, input)
                    end
                else
                    current_grid = { area = 0 }
                end
            end
        end
    end)
    return #valid_inputs
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

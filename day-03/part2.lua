local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}


function M.solution(input_file)
    local solution = 0
    file_utils.read_file_lines(input_file, function(line)
        local joltage = M.largest_number(line)
        solution = solution + joltage
    end)
    return solution
end

---@param num_str string
---@return number
function M.largest_number(num_str)
    local TARGET_SIZE = 12
    local largest_numbers = {}
    local starting_idx = 1
    local finished_digits = 0
    for i = 1, TARGET_SIZE do
        for j = starting_idx, #num_str do
            local current_num = tonumber(num_str:sub(j, j))
            local digits_needed = TARGET_SIZE - (finished_digits)
            local remaining_space = #num_str - (j - 1)
            local has_space_left = digits_needed <= remaining_space
            if not has_space_left then
                finished_digits = finished_digits + 1
                break
            elseif largest_numbers[i] == nil or (current_num > largest_numbers[i] and has_space_left) then
                largest_numbers[i] = current_num
                starting_idx = j + 1
            end
        end
    end
    local out_string = M.number_array_to_str(largest_numbers)
    local num = tonumber(out_string)
    if type(num) ~= "number" then
        error(string.format("%s is not a number", out_string))
    end
    return num
end

---@param num_array number[]
---@return string
function M.number_array_to_str(num_array)
    local str_array = {}
    for i = 1, #num_array do
        str_array[i] = tostring(num_array[i])
    end
    return table.concat(str_array, "")
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    local solution = M.solution(input_file)
    print(string.format("The answer is: %s", solution))
end

return M

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
    local largest_first_digit = nil
    local largest_second_digit = nil
    for i = 1, #num_str do
        local c = num_str:sub(i, i)
        local current_num = tonumber(c)
        if largest_first_digit == nil or (current_num > largest_first_digit and i ~= #num_str) then
            largest_first_digit = current_num
            largest_second_digit = nil
        elseif largest_second_digit == nil or (current_num > largest_second_digit) then
            largest_second_digit = current_num
        end
    end
    local out_string = string.format("%s%s", largest_first_digit, largest_second_digit)
    local num = tonumber(out_string)
    if type(num) ~= "number" then
        error(string.format("%s is not a number", out_string))
    end
    return num
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    local solution = M.solution(input_file)
    print(string.format("The answer is: %s", solution))
end

return M

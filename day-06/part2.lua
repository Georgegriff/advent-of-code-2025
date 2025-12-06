local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}

---@class Operator
---@field operator string
---@field start_index number
---@field end_index number

function M.solution(input_file)
    ---@type string[]
    local calc_strings = {}

    ---@type Operator[]
    local operators = {}
    file_utils.read_file_lines(input_file, function(line)
        local is_on_operators = line:match("([*+]+)")


        if is_on_operators then
            local line_position = 1
            ---@type Operator|nil
            local current_operator = nil
            while (line_position <= #line) do
                local current_token = line:sub(line_position, line_position)
                if current_token:match("([*+]+)") then
                    if current_operator ~= nil then
                        -- take current pos, and also account for space between calculations
                        current_operator.end_index = line_position - 2
                        table.insert(operators, current_operator)
                    end
                    --
                    current_operator = {
                        operator = current_token,
                        start_index = line_position,
                        end_index = 0
                    }
                end
                line_position = line_position + 1
            end
            current_operator.end_index = #line
            table.insert(operators, current_operator)
        else
            table.insert(calc_strings, line)
        end
    end)
    local sum = 0
    for _, operator in ipairs(operators) do
        local result = M.process_and_calculate(operator, calc_strings)
        sum = sum + result
    end
    return sum
end

---@param operator Operator
---@param calc_strings string[]
---@return number
function M.process_and_calculate(operator, calc_strings)
    local rows = #calc_strings
    local result = 0
    local is_first_number = true

    for i = operator.start_index, operator.end_index do
        local num_string = ""
        for j = 1, rows do
            local row = calc_strings[j]
            local char = row:sub(i, i)
            if char ~= " " then
                num_string = num_string .. char
            end
        end
        local number = tonumber(num_string)
        if not number then
            error(string.format("failed to convert number: %s", num_string))
        end

        if is_first_number then
            result = number
            is_first_number = false
        elseif operator.operator == "*" then
            result = result * number
        elseif operator.operator == "+" then
            result = result + number
        else
            error(string.format("invalid operator %s", operator.operator))
        end
    end
    return result
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

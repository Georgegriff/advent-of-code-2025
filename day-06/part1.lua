local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}

---@class Calculation
---@field numbers number[]
---@field operator string

function M.solution(input_file)
    ---@type Calculation[]
    local calculations = {}
    file_utils.read_file_lines(input_file, function(line)
        local is_on_operators = line:match("([*+]+)")
        local parts = line:gmatch("%S+")
        local i = 0
        for part in parts do
            i = i + 1
            if i > #calculations then
                calculations[i] = {
                    numbers = {},
                    operator = ""
                }
            end
            local calculation = calculations[i]
            if is_on_operators then
                calculation.operator = part
            else
                table.insert(calculation.numbers, tonumber(part))
            end
        end
    end)
    local sum = 0
    for _, calc in ipairs(calculations) do
        local result = M.run_calculation(calc)
        sum = sum + result
    end
    return sum
end

---@param calculation Calculation
function M.run_calculation(calculation)
    local sum = 0
    for i, number in ipairs(calculation.numbers) do
        if i == 1 then
            sum = number
        elseif calculation.operator == "*" then
            sum = sum * number
        elseif calculation.operator == "+" then
            sum = sum + number
        else
            error(string.format("invalid operator %s", calculation.operator))
        end
    end
    return sum
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

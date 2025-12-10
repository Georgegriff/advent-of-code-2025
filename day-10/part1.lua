local file_utils = require("utils.file")
local script_utils = require("utils.script")
local Operation = require("operation")
local M = {}


function M.solution(input_file)
    local sum = 0
    file_utils.read_file_lines(input_file, function(line)
        ---@type Operation
        local operation = Operation.from_input_string(line)
        sum = sum + operation:find_min_presses()
    end)
    return sum
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

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}


function M.solution(input_file)
    file_utils.read_file_lines(input_file, function(line)

    end)
    return 0
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    local solution = M.solution(input_file)
    print(string.format("The answer is: %s", solution))
end

return M

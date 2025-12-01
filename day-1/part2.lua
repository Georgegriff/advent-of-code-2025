local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}


function M.solution(input_file)
    file_utils.read_file_lines(input_file, function(line)

    end)
    return 0
end

if script_utils.is_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    M.solution(input_file)
end

return M

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local Graph = require("graph")
local M = {}

function M.solution(input_file)
    local graph = Graph()
    file_utils.read_file_lines(input_file, function(line)
        graph:parse_input_line(line)
    end)

    local start_node = "you"
    local end_node = "out"

    return graph:count_paths(start_node, end_node)
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

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local Graph = require("graph")
local M = {}


function M.solution(input_file)
    ---@type Graph
    local graph = Graph()
    file_utils.read_file_lines(input_file, function(line)
        graph:parse_input_line(line)
    end)
    local path_counter = 0
    graph:traverse("svr", function(node, visited_nodes)
        if node.id == "out" then
            local nodes = {}
            local has_dac = false
            local has_fft = false
            for path in visited_nodes:pairs() do
                table.insert(nodes, path)
                if path == "dac" then
                    has_dac = true
                elseif path == "fft" then
                    has_fft = true
                end
            end

            if has_dac and has_fft then
                print(table.concat(nodes, ","))
                path_counter = path_counter + 1
            end
        end
    end)
    return path_counter
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test-part2.txt"
    local start_time = os.clock()
    local solution = M.solution(input_file)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

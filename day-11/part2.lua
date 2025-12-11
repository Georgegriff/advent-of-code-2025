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


    -- Cases:
    -- SVR -> DAC -> FFT -> OUT
    --- SVR -> FFT -> DAC -> OUT
    -- if any are zero, no paths
    -- The idea is you find all the paths from one node to another and then multiply
    local svr_to_dac = graph:count_paths("svr", "dac")
    local dac_to_fft = graph:count_paths("dac", "fft")
    local fft_to_out = graph:count_paths("fft", "out")
    local paths_dac_then_fft = svr_to_dac * dac_to_fft * fft_to_out

    local svr_to_fft = graph:count_paths("svr", "fft")
    local fft_to_dac = graph:count_paths("fft", "dac")
    local dac_to_out = graph:count_paths("dac", "out")
    local paths_fft_then_dac = svr_to_fft * fft_to_dac * dac_to_out

    return paths_dac_then_fft + paths_fft_then_dac
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

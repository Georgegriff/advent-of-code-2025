local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}


function M.solution(input_file)
    lists = { [1] = {}, [2] = {} }
    file_utils.read_file_lines(input_file, function(line)
        local index = 1
        for word in line:gmatch("%S+") do
            local current_table = lists[index]
            table.insert(current_table, tonumber(word))
            index = index + 1
        end
    end)
    local sum = 0
    for idx, list in ipairs(lists) do
        table.sort(list)
    end
    for idx, list_one_value in ipairs(lists[1]) do
        list_two_value = lists[2][idx]
        local distance = M.get_distance(list_one_value, list_two_value)
        sum = sum + distance
    end
    return sum
end

function M.get_distance(a, b)
    return math.abs(a - b)
end

if script_utils.is_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    M.solution(input_file)
end

return M

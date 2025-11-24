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
    table.sort(lists[2])
    local seen_numbers = {}
    for _, list_one_value in ipairs(lists[1]) do
        local counter = seen_numbers[list_one_value]
        if counter == nil then
            counter = 0
            local index_offset = 1
            for i = index_offset, #lists[1] do
                local list_two_value = lists[2][i]
                if list_two_value > list_one_value then
                    index_offset = i
                    break
                end
                if list_two_value == list_one_value then
                    counter = counter + 1
                end
            end
        end

        counter_score = counter * list_one_value
        seen_numbers[list_one_value] = counter
        sum = sum + counter_score
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

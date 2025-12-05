local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local M = {}

---@class Range
---@field input string
---@field min number
---@field max number

---@type Range[]

function M.solution(input_file)
    local solution = 0
    local ranges, ingredient_ids = M.load_data(input_file)
    for _, input in ipairs(ingredient_ids) do
        local is_fresh = M.check_freshness(input, ranges)
        if is_fresh then
            solution = solution + 1
        end
    end

    return solution
end

function M.load_data(input_file)
    local ranges = {}
    local ingredient_ids = {}
    local is_processing_ranges = true
    file_utils.read_file_lines(input_file, function(line)
        if line == "" and is_processing_ranges then
            is_processing_ranges = false
            return
        end
        if is_processing_ranges then
            local range = M.parse_range(line)
            table.insert(ranges, range)
        else
            -- we are now on ingredient ids
            table.insert(ingredient_ids, tonumber(line))
        end
    end)
    return ranges, ingredient_ids
end

---@param input string
---@return Range
function M.parse_range(input)
    if not string.find(input, "-", 1, true) then
        error(input .. ": is missing a - separator")
    end
    local parts = string_utils.split(input, "-")
    local first = tonumber(parts[1])
    local last = tonumber(parts[2])
    if type(first) ~= "number" then
        error(input .. ": is missing a first number")
    end
    if type(last) ~= "number" then
        error(input .. ": is missing a last number")
    end
    return {
        input = input,
        min = first,
        max = last
    }
end

---@param number number
function M.check_freshness(number, ranges)
    for _, range in ipairs(ranges) do
        if number >= range.min and number <= range.max then
            return true
        end
    end
    return false
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

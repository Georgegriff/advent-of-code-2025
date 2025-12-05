local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local M = {}

---@class Range
---@field input string
---@field min number
---@field max number


function M.solution(input_file)
    local ranges = M.get_sorted_ranges(input_file)
    local fresh_numbers = 0
    for _, range in ipairs(ranges) do
        local numbers_in_range = range.max - (range.min - 1)
        fresh_numbers = fresh_numbers + numbers_in_range
    end
    return fresh_numbers
end

---@param input_file  string
---@return Range[]
function M.get_sorted_ranges(input_file)
    ---@type Range[]
    local ranges = {}
    file_utils.read_file_lines(input_file, function(line)
        if line == "" then
            -- ignore the rest of the file - break
            return false
        end
        local range = M.parse_range(line)
        table.insert(ranges, range)
    end)
    table.sort(ranges, function(a, b)
        if a.min == b.min then
            return a.max < b.max
        end
        return a.min < b.min
    end)
    ---@type Range[]
    local collapsed_ranges = {
        ranges[1]
    }
    -- collapse ranges
    for i, range in ipairs(ranges) do
        if i ~= 1 then
            ---@type Range
            local prevI = collapsed_ranges[#collapsed_ranges]
            if range.min <= prevI.max then
                -- the next number might have a lower min but not a higher max
                prevI.max = math.max(prevI.max, range.max)
            else
                table.insert(collapsed_ranges, range)
            end
        end
    end
    return collapsed_ranges
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
    local input_file = arg[1] or "./inputs/input.txt"
    local start_time = os.clock()
    local solution = M.solution(input_file)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

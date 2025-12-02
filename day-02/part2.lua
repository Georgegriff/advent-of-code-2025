local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local number_utils = require("utils.number")
local M = {}

---@class Range
---@field input string
---@field first number
---@field last number

function M.solution(input_file)
    local solution = 0
    file_utils.read_file_lines(input_file, function(line)
        local ranges = M.parse_input(line)
        for _, range in ipairs(ranges) do
            local invalid_numbers = M.find_invalid_in_range(range)

            solution = solution + number_utils.sum(invalid_numbers)
        end
    end)
    return solution
end

---@param range Range
---@return number[]
function M.find_invalid_in_range(range)
    local invalid_numbers = {}
    for i = range.first, range.last do
        if (M.is_invalid_number(i)) then
            table.insert(invalid_numbers, i)
        end
    end
    return invalid_numbers
end

---@param number number
---@return boolean
function M.is_invalid_number(number)
    local number_as_str = tostring(number)
    local len = #number_as_str
    -- skip first, we don't need it
    for i = 2, len do
        if len % i == 0 then
            local size = math.floor(len / i)
            local segment = number_as_str:sub(1, size)
            local repeated = segment:rep(i)

            if repeated == number_as_str then
                return true
            end
        end
    end
    return false
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
        first = first,
        last = last
    }
end

---@param input string
---@return Range[]
function M.parse_input(input)
    return string_utils.split(input, ",", M.parse_range)
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    local solution = M.solution(input_file)
    print(string.format("The answer is: %s", solution))
end

return M

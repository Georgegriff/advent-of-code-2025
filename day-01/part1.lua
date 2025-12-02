local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}

local start_location = 50
local default_max_location = 99
local default_min_location = 0

---@class Instruction
---@field direction number
---@field amount number


---
function M.solution(input_file)
    local number_of_zeroes = 0
    local current_position = start_location
    file_utils.read_file_lines(input_file, function(line)
        local instruction = M.parse_instruction(line)
        current_position = M.follow_instruction(current_position, instruction, default_min_location, default_max_location)
        -- print(string.format("instruction: %s, new_position: %s", line, current_position))
        if (current_position == 0) then
            number_of_zeroes = number_of_zeroes + 1
            -- print(string.format("zero found: %s", number_of_zeroes))
        end
    end)

    return number_of_zeroes
end

function M.parse_instruction(instruction)
    local direction = 0
    local amount = 0

    for directionStr, amountStr in instruction:gmatch("([LR])([^LR]+)") do
        direction = directionStr == "L" and -1 or 1
        local amountNum = tonumber(amountStr)
        if amountNum ~= nil then
            amount = amountNum
        end
    end
    return {
        direction = direction,
        amount = amount
    }
end

---@param current_position number
---@param instruction Instruction
---@return number
function M.follow_instruction(current_position, instruction, min_location, max_location)
    min_location = min_location or default_min_location
    max_location = max_location or default_max_location
    local range = max_location - min_location + 1
    local amount = instruction.direction * instruction.amount
    local new_position = (current_position + amount) % range

    if new_position < 0 then
        new_position = new_position + range
    end
    return new_position
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    M.solution(input_file)
end

return M

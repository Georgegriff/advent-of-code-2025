pcall(function() require("lldebugger").start() end)

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local M = {}

local start_location = 50
local default_max_location = 99
local default_min_location = 0

---@class Instruction
---@field direction number
---@field amount number

function M.solution(input_file)
    local number_of_zeroes = 0
    local current_position = start_location
    print("")
    print(string.format("The dial starts by pointing at: %s", start_location))
    file_utils.read_file_lines(input_file, function(line)
        local instruction = M.parse_instruction(line)
        current_position, zeros_passed = M.follow_instruction(current_position, instruction, default_min_location,
            default_max_location)
        if (zeros_passed > 0) then
            print(string.format("The dial is rotated %s to point at %s; during this rotation, it points at 0 %s", line,
                current_position, zeros_passed))
        else
            print(string.format("The dial is rotated %s to point at %s", line, current_position))
        end
        number_of_zeroes = number_of_zeroes + zeros_passed
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
---@return number, number
function M.follow_instruction(current_position, instruction, min_location, max_location)
    min_location = min_location or default_min_location
    max_location = max_location or default_max_location
    local range = max_location - min_location + 1
    local zeroes_crossed = 0
    local amount_left = instruction.amount
    while (true) do
        if instruction.direction == -1 then
            if amount_left < current_position then
                current_position = current_position - amount_left
                amount_left = 0
            else
                remainder = amount_left - current_position
                amount_left = remainder
                if amount_left ~= 0 and current_position ~= 0 then
                    zeroes_crossed = zeroes_crossed + 1
                end
                current_position = range
            end
        elseif instruction.direction == 1 then
            if amount_left + current_position < range then
                current_position = amount_left + current_position
                amount_left = 0
            else
                amount_left = (current_position + amount_left) - range
                current_position = min_location
                if amount_left ~= 0 then
                    zeroes_crossed = zeroes_crossed + 1
                end

                -- current_position =
            end
        end
        if amount_left == 0 then
            if current_position == range then
                current_position = 0
            end
            return current_position, zeroes_crossed
        end
    end
end

if script_utils.is_main() then
    local input_file = arg[1] or "./inputs/test.txt"
    M.solution(input_file)
end

return M

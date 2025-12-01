io.stdout:setvbuf("no")
local file_utils = require("utils.file")
local m = require("part2")
if arg[2] == "debug" then
    require("lldebugger").start()
end

-- Safe dial configuration
MIN_VALUE = 0
MAX_VALUE = 99
START_VALUE = 50
SAFE_SPEED = 150
---@class Instruction[]
local instructions = {}
local current_instruction_idx = 1

function love.load()
    -- Enable antialiasing
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    local input_file = "./inputs/test.txt"

    file_utils.read_file_lines(input_file, function(line)
        local instruction = m.parse_instruction(line)
        table.insert(instructions, instruction)
    end)


    -- Safe dial properties
    safe = {
        x = 400,
        y = 300,
        radius = 100,
        value = START_VALUE,
        moved_amount = 0,
        previous_value = START_VALUE,
        zero_crossings = 0
    }
end

function love.update(dt)
    ---@class Instruction
    local current_instruction = instructions[current_instruction_idx]
    -- local next_value = m.follow_instruction(safe.last_value, current_instruction, MIN_VALUE, MAX_VALUE)
    if safe.value == 0 then
        safe.zero_crossings = safe.zero_crossings + 1
    end
    if current_instruction_idx > #instructions then
        safe.moved_amount = 0
        return
    end
    if (safe.moved_amount == current_instruction.amount) then
        current_instruction_idx = current_instruction_idx + 1
        safe.moved_amount = 0
        return
    end
    safe.moved_amount = safe.moved_amount + 1
    safe.previous_value = safe.value
    if current_instruction.direction == 1 then
        safe.value = safe.value + 1
    else
        safe.value = safe.value - 1
    end
end

function draw_background()
    love.graphics.clear(0, 0, 0)
end

function draw_title()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(24)
    local title = "Day 1 - Part 2"
    local screenWidth = love.graphics.getWidth()
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, (screenWidth - titleWidth) / 2, 30)
end

function draw_dial()
    -- Draw the outer ring
    love.graphics.setColor(0.5, 0.5, 0.5) -- medium gray
    love.graphics.circle("fill", safe.x, safe.y, safe.radius * 1.15)

    -- Draw the outer circle (dial)
    love.graphics.setColor(0.3, 0.3, 0.3) -- dark gray
    love.graphics.circle("fill", safe.x, safe.y, safe.radius)

    -- Draw the inner circle (center)
    love.graphics.setColor(0.2, 0.2, 0.2) -- darker gray
    love.graphics.circle("fill", safe.x, safe.y, safe.radius * 0.6)
end

function draw_tick_marks()
    love.graphics.setColor(1, 1, 1) -- white
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value
    local rotationOffset = -(safe.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local isMainTick = (i % 10 == 0)
        local tickStart = isMainTick and safe.radius * 0.85 or safe.radius * 0.9
        local tickEnd = safe.radius * 0.95

        local x1 = safe.x + math.cos(angle) * tickStart
        local y1 = safe.y + math.sin(angle) * tickStart
        local x2 = safe.x + math.cos(angle) * tickEnd
        local y2 = safe.y + math.sin(angle) * tickEnd

        love.graphics.line(x1, y1, x2, y2)
    end
end

function draw_numbers()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value
    local rotationOffset = -(safe.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE, 10 do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local numRadius = safe.radius * 0.75
        local x = safe.x + math.cos(angle) * numRadius
        local y = safe.y + math.sin(angle) * numRadius

        love.graphics.print(tostring(i), x - 8, y - 6)
    end
end

function draw_indicator()
    -- Draw white line from the top (indicator at 12 o'clock position)
    love.graphics.setColor(1, 1, 1) -- white
    love.graphics.setLineWidth(3)
    local topAngle = -math.pi / 2   -- Top position (12 o'clock)
    local lineStart = safe.radius * 1.05
    local lineEnd = safe.radius * 1.12
    love.graphics.line(safe.x + math.cos(topAngle) * lineStart,
        safe.y + math.sin(topAngle) * lineStart,
        safe.x + math.cos(topAngle) * lineEnd,
        safe.y + math.sin(topAngle) * lineEnd)
    love.graphics.setLineWidth(1)
end

function draw_current_instruction()
    local screenHeight = love.graphics.getHeight()
    if current_instruction_idx <= #instructions then
        local current_instruction = instructions[current_instruction_idx]
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(20)
        love.graphics.print("Command: " .. current_instruction.command, 50, screenHeight - 80)
        love.graphics.print("Zero Crossings: " .. safe.zero_crossings, 50, screenHeight - 50)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(20)
        love.graphics.print("All instructions complete!", 50, screenHeight - 80)
        love.graphics.print("Zero Crossings: " .. safe.zero_crossings, 50, screenHeight - 50)
    end
end

function love.draw()
    draw_background()
    draw_title()
    draw_dial()
    draw_tick_marks()
    draw_numbers()
    draw_indicator()
    draw_current_instruction()
end

-- Control the safe dial with arrow keys
function love.keypressed(key)
    if key == "r" then
        safe.value = START_VALUE
        safe.previous_value = START_VALUE
        safe.zero_crossings = 0
        current_instruction_idx = 1
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

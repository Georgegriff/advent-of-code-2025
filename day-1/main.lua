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
DEFAULT_SPEED = 5000
SPEED = DEFAULT_SPEED
MAX_SPEED = 100000
---@class Instruction[]
local instructions = {}
local current_instruction_idx = 1

-- Slider configuration
local slider = {
    x = 50,
    y = 100,
    width = 600,
    height = 20,
    dragging = false
}

function love.load()
    -- Enable antialiasing
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")
    local input_file = "./inputs/input.txt"

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
        target_value = START_VALUE,
        logical_value = START_VALUE,
        zero_crossings = 0,
        progress = 0 -- Animation progress (0 to instruction.amount)
    }
end

function love.update(dt)
    -- Update progress
    safe.progress = safe.progress + SPEED * dt

    -- Process multiple instructions per frame if needed
    while current_instruction_idx <= #instructions do
        ---@class Instruction
        local current_instruction = instructions[current_instruction_idx]

        -- Calculate target value and zero crossings using follow_instruction
        local target, zero_crossings = m.follow_instruction(safe.logical_value, current_instruction, MIN_VALUE, MAX_VALUE)
        safe.target_value = target

        -- Check if we've completed this instruction
        if safe.progress >= current_instruction.amount then
            -- Move to next instruction and add zero crossings from this instruction
            safe.logical_value = safe.target_value
            safe.zero_crossings = safe.zero_crossings + zero_crossings
            -- Also count if we land on zero
            if safe.target_value == 0 then
                safe.zero_crossings = safe.zero_crossings + 1
            end
            safe.progress = safe.progress - current_instruction.amount
            current_instruction_idx = current_instruction_idx + 1
        else
            -- Still working on this instruction
            break
        end
    end

    -- Update visual value (animate progress from logical_value to target_value)
    if current_instruction_idx <= #instructions then
        local current_instruction = instructions[current_instruction_idx]
        local progress_fraction = math.min(safe.progress / current_instruction.amount, 1)
        safe.value = safe.logical_value + (safe.target_value - safe.logical_value) * progress_fraction
    else
        -- All done, snap to final value
        safe.value = safe.logical_value
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

function draw_slider()
    -- Draw label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("Speed: " .. math.floor(SPEED), slider.x, slider.y - 25)

    -- Draw slider track
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height)

    -- Draw slider fill
    local fill_width = (SPEED / MAX_SPEED) * slider.width
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.rectangle("fill", slider.x, slider.y, fill_width, slider.height)

    -- Draw slider handle
    local handle_x = slider.x + fill_width
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", handle_x, slider.y + slider.height / 2, 10)
end

function love.draw()
    draw_background()
    draw_title()
    draw_slider()
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
        safe.target_value = START_VALUE
        safe.logical_value = START_VALUE
        safe.zero_crossings = 0
        safe.progress = 0
        current_instruction_idx = 1
        SPEED = DEFAULT_SPEED
        slider.dragging = false
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if click is on slider
        if x >= slider.x and x <= slider.x + slider.width and
            y >= slider.y and y <= slider.y + slider.height then
            slider.dragging = true
            -- Update speed immediately
            local relative_x = math.max(0, math.min(x - slider.x, slider.width))
            SPEED = (relative_x / slider.width) * MAX_SPEED
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        slider.dragging = false
    end
end

function love.mousemoved(x, y, dx, dy)
    if slider.dragging then
        local relative_x = math.max(0, math.min(x - slider.x, slider.width))
        SPEED = (relative_x / slider.width) * MAX_SPEED
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

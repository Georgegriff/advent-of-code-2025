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
DEFAULT_SPEED = 50
SPEED = DEFAULT_SPEED
MAX_SPEED = 100000
---@class Instruction[]
local instructions = {}
local current_instruction_idx = 1
local use_test_input = true -- Toggle between test.txt and input.txt

-- Slider configuration
local slider = {
    x = 50,
    y = 100,
    width = 600,
    height = 20,
    dragging = false
}

-- Toggle button configuration
local toggle_button = {
    x = 670,
    y = 95,
    width = 100,
    height = 30
}

-- Snow particles for festive effect
local snowflakes = {}
for i = 1, 100 do
    table.insert(snowflakes, {
        x = math.random(0, 800),
        y = math.random(0, 600),
        speed = math.random(10, 30),
        size = math.random(2, 5)
    })
end

function load_instructions()
    instructions = {}
    local input_file = use_test_input and "./inputs/test.txt" or "./inputs/input.txt"
    file_utils.read_file_lines(input_file, function(line)
        local instruction = m.parse_instruction(line)
        table.insert(instructions, instruction)
    end)
end

function reset_safe()
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
    current_instruction_idx = 1
end

function love.load()
    -- Enable antialiasing
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    load_instructions()
    reset_safe()
end

function love.update(dt)
    -- Update snow
    for _, flake in ipairs(snowflakes) do
        flake.y = flake.y + flake.speed * dt
        if flake.y > love.graphics.getHeight() then
            flake.y = -10
            flake.x = math.random(0, love.graphics.getWidth())
        end
    end

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
    -- Dark Christmas green background
    love.graphics.clear(0.05, 0.15, 0.1)
end

function draw_snow()
    love.graphics.setColor(1, 1, 1, 0.8)
    for _, flake in ipairs(snowflakes) do
        love.graphics.circle("fill", flake.x, flake.y, flake.size)
    end
end

function draw_christmas_stars()
    -- Draw decorative stars around the dial
    local time = love.timer.getTime()
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2
        local distance = safe.radius * 1.4
        local x = safe.x + math.cos(angle) * distance
        local y = safe.y + math.sin(angle) * distance
        local pulse = 0.5 + 0.5 * math.sin(time * 3 + i)

        -- Draw gold star
        love.graphics.setColor(1, 0.84, 0, 0.3 + pulse * 0.4)
        love.graphics.circle("fill", x, y, 4 + pulse * 2)
        love.graphics.setColor(1, 1, 1, 0.5 + pulse * 0.5)
        love.graphics.circle("fill", x, y, 2)
    end
end

function draw_title()
    love.graphics.setNewFont(24)
    local title = "Day 1 - Part 2"
    local screenWidth = love.graphics.getWidth()
    local titleWidth = love.graphics.getFont():getWidth(title)
    local x = (screenWidth - titleWidth) / 2
    local y = 30

    -- Red shadow for festive depth
    love.graphics.setColor(0.7, 0.1, 0.1)
    love.graphics.print(title, x + 2, y + 2)
    -- Gold/yellow Christmas color
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.print(title, x, y)
end

function draw_dial()
    -- Draw the outer ring - gold
    love.graphics.setColor(0.8, 0.65, 0.1)
    love.graphics.circle("fill", safe.x, safe.y, safe.radius * 1.15)

    -- Draw the outer circle (dial) - Christmas red
    love.graphics.setColor(0.7, 0.1, 0.1)
    love.graphics.circle("fill", safe.x, safe.y, safe.radius)

    -- Draw the inner circle (center) - dark Christmas green
    love.graphics.setColor(0.1, 0.3, 0.1)
    love.graphics.circle("fill", safe.x, safe.y, safe.radius * 0.6)
end

function draw_tick_marks()
    -- Gold tick marks
    love.graphics.setColor(1, 0.84, 0)
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
    -- White numbers with gold shadow for festive look
    love.graphics.setNewFont(12)
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value
    local rotationOffset = -(safe.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE, 10 do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local numRadius = safe.radius * 0.75
        local x = safe.x + math.cos(angle) * numRadius
        local y = safe.y + math.sin(angle) * numRadius

        -- Gold shadow
        love.graphics.setColor(1, 0.84, 0, 0.5)
        love.graphics.print(tostring(i), x - 7, y - 5)
        -- White text
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(tostring(i), x - 8, y - 6)
    end
end

function draw_indicator()
    -- Draw gold line from the top (indicator at 12 o'clock position)
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setLineWidth(3)
    local topAngle = -math.pi / 2 -- Top position (12 o'clock)
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
    love.graphics.setNewFont(20)
    if current_instruction_idx <= #instructions then
        local current_instruction = instructions[current_instruction_idx]
        -- Command in Christmas red
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.print("Command: " .. current_instruction.command, 50, screenHeight - 80)
        -- Zero crossings in gold
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.print("Zero Crossings: " .. safe.zero_crossings, 50, screenHeight - 50)
    else
        -- Completion message in bright green
        love.graphics.setColor(0.2, 0.9, 0.2)
        love.graphics.print("All instructions complete!", 50, screenHeight - 80)
        -- Zero crossings in gold
        love.graphics.setColor(1, 0.84, 0)
        love.graphics.print("Zero Crossings: " .. safe.zero_crossings, 50, screenHeight - 50)
    end
end

function draw_slider()
    -- Draw label - gold
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setNewFont(16)
    love.graphics.print("Speed: " .. math.floor(SPEED), slider.x, slider.y - 25)

    -- Draw slider track - dark green
    love.graphics.setColor(0.1, 0.3, 0.1)
    love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height)

    -- Draw slider fill - Christmas red
    local fill_width = (SPEED / MAX_SPEED) * slider.width
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", slider.x, slider.y, fill_width, slider.height)

    -- Draw slider handle - gold
    local handle_x = slider.x + fill_width
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.circle("fill", handle_x, slider.y + slider.height / 2, 10)
end

function draw_toggle_button()
    -- Draw button background
    if use_test_input then
        love.graphics.setColor(0.8, 0.6, 0.1) -- Gold when test
    else
        love.graphics.setColor(0.1, 0.3, 0.1) -- Dark green when input
    end
    love.graphics.rectangle("fill", toggle_button.x, toggle_button.y, toggle_button.width, toggle_button.height, 5, 5)

    -- Draw button border - gold
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", toggle_button.x, toggle_button.y, toggle_button.width, toggle_button.height, 5, 5)
    love.graphics.setLineWidth(1)

    -- Draw button text
    love.graphics.setNewFont(14)
    local text = use_test_input and "TEST" or "INPUT"
    local text_width = love.graphics.getFont():getWidth(text)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(text, toggle_button.x + (toggle_button.width - text_width) / 2, toggle_button.y + 8)
end

function love.draw()
    draw_background()
    draw_snow()
    draw_title()
    draw_slider()
    draw_toggle_button()
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
        -- Check if click is on toggle button
        if x >= toggle_button.x and x <= toggle_button.x + toggle_button.width and
            y >= toggle_button.y and y <= toggle_button.y + toggle_button.height then
            use_test_input = not use_test_input
            load_instructions()
            reset_safe()
            return
        end

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

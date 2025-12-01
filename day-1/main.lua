io.stdout:setvbuf("no")
local file_utils = require("utils.file")
local m = require("part2")
if arg[2] == "debug" then
    require("lldebugger").start()
end

-- Vault dial configuration
MIN_VALUE = 0
MAX_VALUE = 99
START_VALUE = 50
DEFAULT_SPEED = 30
SPEED = DEFAULT_SPEED
MAX_SPEED = 1000000
---@class Instruction[]
local instructions = {}
local current_instruction_idx = 1
local use_test_input = true -- Toggle between test.txt and input.txt
local debug_pause = false   -- Pause when complete instead of opening vault

-- Slider configuration
local slider = {
    x = 145,
    y = 100,
    width = 600,
    height = 20,
    dragging = false
}

-- Toggle switch configuration
local toggle_switch = {
    x = 755,
    y = 95,
    width = 100,
    height = 35,
    knob_width = 45,
    transition = 0 -- 0 to 1, animates the knob position
}

-- Snow particles for festive effect
local snowflakes = {}
for i = 1, 100 do
    table.insert(snowflakes, {
        x = math.random(0, 1000),
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

function reset_vault()
    vault = {
        x = 500,
        y = 300,
        radius = 80,
        value = START_VALUE,
        target_value = START_VALUE,
        logical_value = START_VALUE,
        zero_crossings = 0,
        progress = 0 -- Animation progress (0 to instruction.amount)
    }
    current_instruction_idx = 1
end

function love.load()
    -- Set window size to accommodate opened vault door
    love.window.setMode(1000, 600, { resizable = false })

    -- Enable antialiasing
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    load_instructions()
    reset_vault()
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

    -- PAUSE when all instructions complete for debugging
    if debug_pause and current_instruction_idx > #instructions then
        return
    end

    -- Animate toggle switch transition
    local target_transition = use_test_input and 0 or 1
    if toggle_switch.transition < target_transition then
        toggle_switch.transition = math.min(toggle_switch.transition + dt * 5, target_transition)
    elseif toggle_switch.transition > target_transition then
        toggle_switch.transition = math.max(toggle_switch.transition - dt * 5, target_transition)
    end

    -- Calculate how much to move this frame
    local movement_this_frame = SPEED * dt
    local range = MAX_VALUE - MIN_VALUE + 1

    -- Process multiple instructions per frame if needed
    while current_instruction_idx <= #instructions and movement_this_frame > 0 do
        ---@class Instruction
        local current_instruction = instructions[current_instruction_idx]

        -- Calculate target value and zero crossings using follow_instruction
        local target, zero_crossings = m.follow_instruction(vault.logical_value, current_instruction, MIN_VALUE,
            MAX_VALUE)
        vault.target_value = target

        -- Calculate how much is left in this instruction
        local remaining_in_instruction = current_instruction.amount - vault.progress

        if movement_this_frame >= remaining_in_instruction then
            -- Complete this instruction
            local movement_to_use = remaining_in_instruction

            -- Update visual value
            if current_instruction.direction == -1 then
                -- L: decrease value (dial rotates clockwise due to negative rotationOffset)
                vault.value = vault.value - movement_to_use
                while vault.value < MIN_VALUE do
                    vault.value = vault.value + range
                end
            else
                -- R: increase value (dial rotates counter-clockwise due to negative rotationOffset)
                vault.value = vault.value + movement_to_use
                while vault.value > MAX_VALUE do
                    vault.value = vault.value - range
                end
            end

            -- Move to next instruction and add zero crossings from this instruction
            vault.logical_value = vault.target_value
            vault.zero_crossings = vault.zero_crossings + zero_crossings
            -- Also count if we land on zero
            if vault.target_value == 0 then
                vault.zero_crossings = vault.zero_crossings + 1
            end

            -- Sync visual value to logical value to prevent drift
            vault.value = vault.logical_value

            -- Debug logging
            print(string.format("Completed %s: visual=%.2f logical=%d target=%d",
                current_instruction.command, vault.value, vault.logical_value, vault.target_value))

            vault.progress = 0
            movement_this_frame = movement_this_frame - movement_to_use
            current_instruction_idx = current_instruction_idx + 1
        else
            -- Continue with current instruction
            vault.progress = vault.progress + movement_this_frame

            -- Update visual value
            if current_instruction.direction == -1 then
                -- L: decrease value (dial rotates clockwise due to negative rotationOffset)
                vault.value = vault.value - movement_this_frame
                while vault.value < MIN_VALUE do
                    vault.value = vault.value + range
                end
            else
                -- R: increase value (dial rotates counter-clockwise due to negative rotationOffset)
                vault.value = vault.value + movement_this_frame
                while vault.value > MAX_VALUE do
                    vault.value = vault.value - range
                end
            end

            movement_this_frame = 0
        end
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
        local distance = vault.radius * 1.4
        local x = vault.x + math.cos(angle) * distance
        local y = vault.y + math.sin(angle) * distance
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
    local title = "Day 1: Secret Entrance"
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

function draw_3d_vault()
    local vault_radius = 150
    local is_open = (not debug_pause) and current_instruction_idx > #instructions

    if is_open then
        -- Draw open vault - interior circular opening
        love.graphics.setColor(0.05, 0.03, 0.03)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius * 0.9)

        -- Draw interior ring detail
        love.graphics.setColor(0.1, 0.08, 0.08)
        love.graphics.setLineWidth(10)
        love.graphics.circle("line", vault.x, vault.y, vault_radius * 0.85)
        love.graphics.setLineWidth(1)

        -- Draw open circular door to the left (hinged at vault edge)
        local door_x = vault.x - vault_radius - vault_radius - 10
        local door_y = vault.y

        -- Draw door 3D edge (circular)
        love.graphics.setColor(0.12, 0.1, 0.1)
        love.graphics.circle("fill", door_x + 10, door_y, vault_radius)

        -- Draw door face (circular vault door)
        love.graphics.setColor(0.15, 0.12, 0.12)
        love.graphics.circle("fill", door_x, door_y, vault_radius)

        -- Draw outer ring
        love.graphics.setColor(0.25, 0.22, 0.22)
        love.graphics.setLineWidth(15)
        love.graphics.circle("line", door_x, door_y, vault_radius * 0.95)
        love.graphics.setLineWidth(1)

        -- Draw locking bolts around door
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local bolt_x = door_x + math.cos(angle) * vault_radius * 0.7
            local bolt_y = door_y + math.sin(angle) * vault_radius * 0.7
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.circle("fill", bolt_x, bolt_y, 8)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("fill", bolt_x, bolt_y, 5)
        end

        -- Draw hinges connecting door to vault frame
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", vault.x - vault_radius - 10, door_y - 40, 20, 25)
        love.graphics.rectangle("fill", vault.x - vault_radius - 10, door_y + 20, 20, 25)

        -- Draw vault frame (circular opening)
        love.graphics.setColor(0.2, 0.18, 0.18)
        love.graphics.setLineWidth(12)
        love.graphics.circle("line", vault.x, vault.y, vault_radius)
        love.graphics.setLineWidth(1)
    else
        -- Draw closed vault door
        -- Draw outer vault ring (3D effect)
        love.graphics.setColor(0.2, 0.18, 0.18)
        love.graphics.circle("fill", vault.x + 3, vault.y + 3, vault_radius + 10)

        -- Draw main outer ring
        love.graphics.setColor(0.25, 0.22, 0.22)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius + 10)

        -- Draw main vault door face
        love.graphics.setColor(0.15, 0.12, 0.12)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius)

        -- Draw inner ring detail
        love.graphics.setColor(0.12, 0.1, 0.1)
        love.graphics.setLineWidth(8)
        love.graphics.circle("line", vault.x, vault.y, vault_radius * 0.85)
        love.graphics.setLineWidth(1)

        -- Draw locking bolts around the door (8 positions)
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local bolt_x = vault.x + math.cos(angle) * vault_radius * 0.7
            local bolt_y = vault.y + math.sin(angle) * vault_radius * 0.7

            -- Bolt base
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.circle("fill", bolt_x, bolt_y, 8)

            -- Bolt highlight
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.circle("fill", bolt_x, bolt_y, 5)
        end

        -- Draw handle/wheel in center (but not overlapping dial)
        local handle_radius = vault_radius * 0.5
        love.graphics.setColor(0.6, 0.5, 0.1)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", vault.x, vault.y, handle_radius)
        love.graphics.setLineWidth(1)

        -- Draw spokes from handle
        for i = 1, 4 do
            local angle = (i / 4) * math.pi * 2
            local spoke_start = vault.radius * 1.4
            local spoke_end = handle_radius
            love.graphics.setColor(0.6, 0.5, 0.1)
            love.graphics.setLineWidth(3)
            love.graphics.line(
                vault.x + math.cos(angle) * spoke_start,
                vault.y + math.sin(angle) * spoke_start,
                vault.x + math.cos(angle) * spoke_end,
                vault.y + math.sin(angle) * spoke_end
            )
        end
        love.graphics.setLineWidth(1)
    end
end

function draw_dial()
    -- Draw the outer ring - gold
    love.graphics.setColor(0.8, 0.65, 0.1)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius * 1.15)

    -- Draw the outer circle (dial) - Christmas red
    love.graphics.setColor(0.7, 0.1, 0.1)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius)

    -- Draw the inner circle (center) - light grey
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius * 0.6)
end

function draw_tick_marks()
    -- Gold tick marks
    love.graphics.setColor(1, 0.84, 0)
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value (negative to rotate dial opposite to value)
    local rotationOffset = -(vault.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local isMainTick = (i % 10 == 0)
        local tickStart = isMainTick and vault.radius * 0.85 or vault.radius * 0.9
        local tickEnd = vault.radius * 0.95

        local x1 = vault.x + math.cos(angle) * tickStart
        local y1 = vault.y + math.sin(angle) * tickStart
        local x2 = vault.x + math.cos(angle) * tickEnd
        local y2 = vault.y + math.sin(angle) * tickEnd

        love.graphics.line(x1, y1, x2, y2)
    end
end

function draw_numbers()
    -- White numbers with gold shadow for festive look
    love.graphics.setNewFont(12)
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value (negative to rotate dial opposite to value)
    local rotationOffset = -(vault.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE, 10 do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local numRadius = vault.radius * 0.75
        local x = vault.x + math.cos(angle) * numRadius
        local y = vault.y + math.sin(angle) * numRadius

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
    local lineStart = vault.radius * 1.05
    local lineEnd = vault.radius * 1.12
    love.graphics.line(vault.x + math.cos(topAngle) * lineStart,
        vault.y + math.sin(topAngle) * lineStart,
        vault.x + math.cos(topAngle) * lineEnd,
        vault.y + math.sin(topAngle) * lineEnd)
    love.graphics.setLineWidth(1)
end

function draw_current_instruction()
    local screenHeight = love.graphics.getHeight()

    if (not debug_pause) and current_instruction_idx > #instructions then
        -- Vault is open - show solution inside the vault
        love.graphics.setNewFont(28)
        love.graphics.setColor(1, 0.84, 0)
        local solution_text = "Solution"
        local solution_width = love.graphics.getFont():getWidth(solution_text)
        love.graphics.print(solution_text, vault.x - solution_width / 2, vault.y - 30)

        -- Number below
        love.graphics.setNewFont(48)
        local number_text = tostring(vault.zero_crossings)
        local number_width = love.graphics.getFont():getWidth(number_text)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(number_text, vault.x - number_width / 2, vault.y + 5)

        -- Completion message at bottom in bright green
        love.graphics.setNewFont(20)
        love.graphics.setColor(0.2, 0.9, 0.2)
        love.graphics.print("Vault opened", 50, screenHeight - 50)
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

    -- Calculate slider position using exponential curve
    -- Convert SPEED to slider position (0 to 1)
    local slider_position = math.sqrt(SPEED / MAX_SPEED)
    local fill_width = slider_position * slider.width

    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", slider.x, slider.y, fill_width, slider.height)

    -- Draw slider handle - gold
    local handle_x = slider.x + fill_width
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.circle("fill", handle_x, slider.y + slider.height / 2, 10)
end

function draw_toggle_button()
    -- Draw switch track (background)
    local track_color = use_test_input and { 0.8, 0.6, 0.1 } or { 0.1, 0.5, 0.1 }
    love.graphics.setColor(track_color[1], track_color[2], track_color[3], 0.5)
    love.graphics.rectangle("fill", toggle_switch.x, toggle_switch.y, toggle_switch.width, toggle_switch.height,
        toggle_switch.height / 2)

    -- Draw gold border around track
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", toggle_switch.x, toggle_switch.y, toggle_switch.width, toggle_switch.height,
        toggle_switch.height / 2)
    love.graphics.setLineWidth(1)

    -- Draw labels inside track
    love.graphics.setNewFont(11)
    -- TEST label on left
    love.graphics.setColor(1, 1, 1, use_test_input and 0.4 or 0.8)
    love.graphics.print("TEST", toggle_switch.x + 8, toggle_switch.y + 10)
    -- INPUT label on right
    love.graphics.setColor(1, 1, 1, use_test_input and 0.8 or 0.4)
    love.graphics.print("INPUT", toggle_switch.x + toggle_switch.width - 38, toggle_switch.y + 10)

    -- Calculate knob position
    local knob_x = toggle_switch.x + toggle_switch.transition * (toggle_switch.width - toggle_switch.knob_width)
    local knob_y = toggle_switch.y

    -- Draw knob shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", knob_x + 2, knob_y + 2, toggle_switch.knob_width, toggle_switch.height,
        toggle_switch.height / 2)

    -- Draw knob
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.rectangle("fill", knob_x, knob_y, toggle_switch.knob_width, toggle_switch.height,
        toggle_switch.height / 2)

    -- Draw knob highlight
    love.graphics.setColor(1, 1, 0.6, 0.5)
    love.graphics.rectangle("fill", knob_x + 3, knob_y + 3, toggle_switch.knob_width - 6, toggle_switch.height / 2 - 3,
        toggle_switch.height / 4)

    -- Draw active text on knob
    love.graphics.setNewFont(12)
    local knob_text = use_test_input and "TEST" or "INPUT"
    local text_width = love.graphics.getFont():getWidth(knob_text)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print(knob_text, knob_x + (toggle_switch.knob_width - text_width) / 2, knob_y + 9)
end

function love.draw()
    draw_background()
    draw_snow()
    draw_title()
    draw_slider()
    draw_toggle_button()
    draw_3d_vault()

    -- Only draw dial and related elements if vault is not open
    local is_open = (not debug_pause) and current_instruction_idx > #instructions
    if not is_open then
        draw_dial()
        draw_tick_marks()
        draw_numbers()
        draw_indicator()
    end

    draw_current_instruction()
end

-- Control the vault dial with arrow keys
function love.keypressed(key)
    if key == "r" then
        vault.value = START_VALUE
        vault.target_value = START_VALUE
        vault.logical_value = START_VALUE
        vault.zero_crossings = 0
        vault.progress = 0
        current_instruction_idx = 1
        SPEED = DEFAULT_SPEED
        slider.dragging = false
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check if click is on toggle switch
        if x >= toggle_switch.x and x <= toggle_switch.x + toggle_switch.width and
            y >= toggle_switch.y and y <= toggle_switch.y + toggle_switch.height then
            use_test_input = not use_test_input
            load_instructions()
            reset_vault()
            return
        end

        -- Check if click is on slider
        if x >= slider.x and x <= slider.x + slider.width and
            y >= slider.y and y <= slider.y + slider.height then
            slider.dragging = true
            -- Update speed immediately using exponential curve
            local relative_x = math.max(0, math.min(x - slider.x, slider.width))
            local slider_position = relative_x / slider.width
            SPEED = (slider_position * slider_position) * MAX_SPEED
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
        -- Update speed using exponential curve (x^2) for better control at low speeds
        local relative_x = math.max(0, math.min(x - slider.x, slider.width))
        local slider_position = relative_x / slider.width
        SPEED = (slider_position * slider_position) * MAX_SPEED
    end
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

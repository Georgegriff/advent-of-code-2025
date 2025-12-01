io.stdout:setvbuf("no")
local file_utils = require("utils.file")
local m = require("part2")
local Slider = require("ui.slider")
local Toggle = require("ui.toggle")
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

-- UI Components
local speed_slider = Slider.create({
    x = 145,
    y = 100,
    width = 600,
    height = 20,
    min_value = 0,
    max_value = MAX_SPEED,
    initial_value = DEFAULT_SPEED,
    exponential = true,
    label = "Speed",
    on_change = function(value)
        SPEED = value
    end
})

local input_toggle = Toggle.create({
    x = 755,
    y = 95,
    width = 100,
    height = 35,
    knob_width = 45,
    initial_state = false, -- false = TEST, true = INPUT
    label_off = "TEST",
    label_on = "INPUT",
    on_toggle = function(state)
        use_test_input = not state
        load_instructions()
        reset_vault()
    end
})

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
        progress = 0,               -- Animation progress (0 to instruction.amount)
        door_open_time = nil,       -- Time when door was opened
        door_animation_progress = 0 -- 0 to 1 for door opening animation
    }
    current_instruction_idx = 1
end

function love.load()
    -- Set window size to accommodate opened vault door
    love.window.setMode(1000, 600, { resizable = false })
    love.window.setTitle("Love2D - Day 1: Secret Entrance")

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

    -- Check if vault just opened and start door animation
    local is_open = (not debug_pause) and current_instruction_idx > #instructions
    if is_open and not vault.door_open_time then
        vault.door_open_time = love.timer.getTime()
    end

    -- Update door animation (subtle backwards movement over 0.8 seconds)
    if vault.door_open_time then
        local elapsed = love.timer.getTime() - vault.door_open_time
        local duration = 0.8
        if elapsed < duration then
            -- Ease out cubic for smooth deceleration
            local t = elapsed / duration
            vault.door_animation_progress = 1 - math.pow(1 - t, 3)
        else
            vault.door_animation_progress = 1
        end
    end

    -- PAUSE when all instructions complete for debugging
    if debug_pause and current_instruction_idx > #instructions then
        return
    end

    -- Update UI components
    Toggle.update(input_toggle, dt)

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
        -- Draw open vault - interior circular opening (expanded to fill the frame)
        love.graphics.setColor(0.05, 0.05, 0.06)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius * 1.05)

        -- Draw interior ring detail
        love.graphics.setColor(0.15, 0.15, 0.18)
        love.graphics.setLineWidth(10)
        love.graphics.circle("line", vault.x, vault.y, vault_radius * 0.95)
        love.graphics.setLineWidth(1)

        -- Apply subtle backwards animation to door (scale down and move slightly)
        local anim_scale = 1.0 - (vault.door_animation_progress * 0.08) -- Subtle 8% scale reduction
        local anim_offset_x = vault.door_animation_progress * 12        -- Move away horizontally
        local anim_offset_y = vault.door_animation_progress * 8         -- Move away slightly down for depth
        local anim_alpha = 1.0 - (vault.door_animation_progress * 0.15) -- Slight fade for depth

        -- Hinge stays fixed at vault edge
        local hinge_x = vault.x - vault_radius - 10

        -- Draw open circular door to the left (edge always touches hinge)
        local door_radius = vault_radius * anim_scale
        -- Door center is positioned so its right edge touches the hinge
        local door_x = hinge_x - door_radius
        local door_y = vault.y + anim_offset_y

        -- Draw door 3D edge (circular) - shadow
        love.graphics.setColor(0.15 * anim_alpha, 0.15 * anim_alpha, 0.18 * anim_alpha)
        love.graphics.circle("fill", door_x + 10, door_y, door_radius)

        -- Draw door face (circular vault door) - dark metal
        love.graphics.setColor(0.25 * anim_alpha, 0.25 * anim_alpha, 0.28 * anim_alpha)
        love.graphics.circle("fill", door_x, door_y, door_radius)

        -- Draw outer ring - metallic
        love.graphics.setColor(0.4 * anim_alpha, 0.4 * anim_alpha, 0.45 * anim_alpha)
        love.graphics.setLineWidth(15 * anim_scale)
        love.graphics.circle("line", door_x, door_y, door_radius * 0.95)
        love.graphics.setLineWidth(1)

        -- Draw locking bolts around door
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local bolt_x = door_x + math.cos(angle) * door_radius * 0.7
            local bolt_y = door_y + math.sin(angle) * door_radius * 0.7
            love.graphics.setColor(0.35 * anim_alpha, 0.35 * anim_alpha, 0.4 * anim_alpha)
            love.graphics.circle("fill", bolt_x, bolt_y, 8 * anim_scale)
            love.graphics.setColor(0.5 * anim_alpha, 0.5 * anim_alpha, 0.55 * anim_alpha)
            love.graphics.circle("fill", bolt_x, bolt_y, 5 * anim_scale)
        end

        -- Draw hinges connecting door to vault frame (pill-shaped, smaller)
        love.graphics.setColor(0.3, 0.3, 0.35)

        -- Top hinge
        local hinge_width = 12
        local hinge_height = 18
        local hinge_radius = hinge_width / 2
        love.graphics.circle("fill", hinge_x + hinge_radius, vault.y - 30, hinge_radius)
        love.graphics.circle("fill", hinge_x + hinge_radius, vault.y - 30 + hinge_height, hinge_radius)
        love.graphics.rectangle("fill", hinge_x, vault.y - 30, hinge_width, hinge_height)

        -- Bottom hinge
        love.graphics.circle("fill", hinge_x + hinge_radius, vault.y + 15, hinge_radius)
        love.graphics.circle("fill", hinge_x + hinge_radius, vault.y + 15 + hinge_height, hinge_radius)
        love.graphics.rectangle("fill", hinge_x, vault.y + 15, hinge_width, hinge_height)

        -- Draw vault frame (circular opening)
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.setLineWidth(12)
        love.graphics.circle("line", vault.x, vault.y, vault_radius)
        love.graphics.setLineWidth(1)
    else
        -- Draw closed vault door
        -- Draw outer vault ring (3D effect - shadow)
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.circle("fill", vault.x + 3, vault.y + 3, vault_radius + 10)

        -- Draw main outer ring - dark metal
        love.graphics.setColor(0.35, 0.35, 0.4)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius + 10)

        -- Draw main vault door face - darker metal
        love.graphics.setColor(0.25, 0.25, 0.28)
        love.graphics.circle("fill", vault.x, vault.y, vault_radius)

        -- Draw inner ring detail - darker still
        love.graphics.setColor(0.18, 0.18, 0.22)
        love.graphics.setLineWidth(8)
        love.graphics.circle("line", vault.x, vault.y, vault_radius * 0.85)
        love.graphics.setLineWidth(1)

        -- Draw locking bolts around the door (8 positions)
        for i = 1, 8 do
            local angle = (i / 8) * math.pi * 2
            local bolt_x = vault.x + math.cos(angle) * vault_radius * 0.7
            local bolt_y = vault.y + math.sin(angle) * vault_radius * 0.7

            -- Bolt base - dark metal
            love.graphics.setColor(0.35, 0.35, 0.4)
            love.graphics.circle("fill", bolt_x, bolt_y, 8)

            -- Bolt highlight - lighter metal
            love.graphics.setColor(0.5, 0.5, 0.55)
            love.graphics.circle("fill", bolt_x, bolt_y, 5)
        end

        -- Draw handle/wheel in center (but not overlapping dial)
        local handle_radius = vault_radius * 0.5
        love.graphics.setColor(0.4, 0.4, 0.45)
        love.graphics.setLineWidth(4)
        love.graphics.circle("line", vault.x, vault.y, handle_radius)
        love.graphics.setLineWidth(1)
    end
end

function draw_dial()
    -- Draw the outer ring - dark metal
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius * 1.15)

    -- Draw the outer circle (dial) - dark gunmetal
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius)

    -- Draw the inner circle (center) - brushed steel
    love.graphics.setColor(0.6, 0.6, 0.65)
    love.graphics.circle("fill", vault.x, vault.y, vault.radius * 0.6)
end

function draw_tick_marks()
    -- White/silver tick marks
    love.graphics.setColor(0.9, 0.9, 0.95)
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
    -- White numbers with subtle shadow
    love.graphics.setNewFont(12)
    local totalValues = MAX_VALUE - MIN_VALUE + 1
    -- Calculate rotation offset based on current value (negative to rotate dial opposite to value)
    local rotationOffset = -(vault.value / totalValues) * math.pi * 2

    for i = MIN_VALUE, MAX_VALUE, 10 do
        local angle = (i / totalValues) * math.pi * 2 - math.pi / 2 + rotationOffset
        local numRadius = vault.radius * 0.75
        local x = vault.x + math.cos(angle) * numRadius
        local y = vault.y + math.sin(angle) * numRadius

        -- Dark shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.print(tostring(i), x - 7, y - 5)
        -- White text
        love.graphics.setColor(0.95, 0.95, 1)
        love.graphics.print(tostring(i), x - 8, y - 6)
    end
end

function draw_indicator()
    -- Draw 3D metallic indicator from the top (12 o'clock position)
    local topAngle = -math.pi / 2
    local lineStart = vault.radius * 0.95
    local lineEnd = vault.radius * 1.25

    -- Dark shadow/base layer (right side)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(8)
    love.graphics.line(vault.x + math.cos(topAngle) * lineStart + 1,
        vault.y + math.sin(topAngle) * lineStart + 1,
        vault.x + math.cos(topAngle) * lineEnd + 1,
        vault.y + math.sin(topAngle) * lineEnd + 1)

    -- Main metallic body
    love.graphics.setColor(0.6, 0.6, 0.65)
    love.graphics.setLineWidth(6)
    love.graphics.line(vault.x + math.cos(topAngle) * lineStart,
        vault.y + math.sin(topAngle) * lineStart,
        vault.x + math.cos(topAngle) * lineEnd,
        vault.y + math.sin(topAngle) * lineEnd)

    -- Bright highlight (left side)
    love.graphics.setColor(0.95, 0.95, 1, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(vault.x + math.cos(topAngle) * lineStart - 1.5,
        vault.y + math.sin(topAngle) * lineStart - 1.5,
        vault.x + math.cos(topAngle) * lineEnd - 1.5,
        vault.y + math.sin(topAngle) * lineEnd - 1.5)

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

function love.draw()
    draw_background()
    draw_snow()
    draw_title()
    Slider.draw(speed_slider)
    Toggle.draw(input_toggle)
    draw_3d_vault()

    -- Only draw dial and related elements if vault is not open
    local is_open = (not debug_pause) and current_instruction_idx > #instructions
    if not is_open then
        draw_dial()
        draw_tick_marks()
        draw_numbers()
    end

    draw_current_instruction()

    -- Draw indicator last so it's on top
    if not is_open then
        draw_indicator()
    end
end

-- Control the vault dial with arrow keys
function love.keypressed(key)
    if key == "r" then
        vault.value = START_VALUE
        vault.target_value = START_VALUE
        vault.logical_value = START_VALUE
        vault.zero_crossings = 0
        vault.progress = 0
        vault.door_open_time = nil
        vault.door_animation_progress = 0
        current_instruction_idx = 1
        SPEED = DEFAULT_SPEED
        speed_slider.value = DEFAULT_SPEED
        speed_slider.dragging = false
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        -- Check UI components
        if Toggle.mouse_pressed(input_toggle, x, y) then
            return
        end
        if Slider.mouse_pressed(speed_slider, x, y) then
            return
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        Slider.mouse_released(speed_slider)
    end
end

function love.mousemoved(x, y, dx, dy)
    Slider.mouse_moved(speed_slider, x)
end

local M = {}

function M.add(a, b)
    return a + b
end

return M

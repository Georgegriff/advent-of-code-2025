io.stdout:setvbuf("no")
local file_utils = require("utils.file")
local m = require("part2")
local number_utils = require("utils.number")
local Snow = require("ui.snow")
local Toggle = require("ui.toggle")
local Slider = require("ui.slider")

if arg[2] == "debug" then
    require("lldebugger").start()
end

-- Window configuration
WINDOW_WIDTH = 1000
WINDOW_HEIGHT = 600

-- Processing configuration
DEFAULT_SPEED = 60
SPEED = DEFAULT_SPEED
MAX_SPEED = 200000

---@class Range[]
local ranges = {}
local use_test_input = true -- Toggle between test.txt and input.txt

-- Processing state
local current_range_idx = 1
local current_number = 0
local solution = 0

-- Animation state for numbers going to trash
local animating_number = nil -- {value, x, y, target_x, target_y, progress}
local check_delay = 0        -- Delay between checking numbers
local lid_open_progress = 0  -- 0 = closed, 1 = fully open (45 degrees)

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
        load_ranges()
        reset_state()
    end
})

-- Snow particles for festive effect
local snow = Snow.create({
    particle_count = 100,
    width = WINDOW_WIDTH,
    height = WINDOW_HEIGHT
})

function load_ranges()
    ranges = {}
    local input_file = use_test_input and "./inputs/test.txt" or "./inputs/input.txt"
    file_utils.read_file_lines(input_file, function(line)
        local line_ranges = m.parse_input(line)
        for _, range in ipairs(line_ranges) do
            table.insert(ranges, range)
        end
    end)
end

function reset_state()
    current_range_idx = 1
    current_number = 0
    solution = 0
    animating_number = nil
    check_delay = 0
    lid_open_progress = 0
end

function love.load()
    -- Set window size
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Love2D - Day 2: Gift Shop")

    -- Enable antialiasing
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    load_ranges()
    reset_state()
end

function love.update(dt)
    -- Update snow
    Snow.update(snow, dt)

    -- Update UI components
    Toggle.update(input_toggle, dt)

    -- Update lid animation
    if animating_number then
        -- Open lid as number approaches
        lid_open_progress = math.min(1, lid_open_progress + dt * 8)

        -- Animation speed scales with SPEED (base speed of 3, scales up with SPEED)
        local animation_speed = 1 + (SPEED / 100)
        animating_number.progress = animating_number.progress + dt * animation_speed
        if animating_number.progress >= 1 then
            -- Animation complete - add to solution
            solution = solution + animating_number.value
            animating_number = nil
        end
        return -- Don't process new numbers while animating
    else
        -- Close lid when no animation
        lid_open_progress = math.max(0, lid_open_progress - dt * 4)
    end

    -- PAUSE when all ranges processed
    if current_range_idx > #ranges then
        return
    end

    -- Add delay between checks based on speed
    if SPEED > 0 then
        check_delay = check_delay + dt * SPEED

        while check_delay >= 1 and current_range_idx <= #ranges do
            check_delay = check_delay - 1

            local current_range = ranges[current_range_idx]

            -- Initialize current_number if starting a new range
            if current_number == 0 then
                current_number = current_range.first
            end

            -- Check if current number is invalid
            if m.is_invalid_number(current_number) then
                -- Start animation to trash
                local trash_x = WINDOW_WIDTH - 100
                local trash_y = 240 -- Adjusted to go into the top of the bin
                animating_number = {
                    value = current_number,
                    x = WINDOW_WIDTH / 2,
                    y = WINDOW_HEIGHT / 2,
                    target_x = trash_x,
                    target_y = trash_y,
                    progress = 0
                }
            end

            -- Move to next number
            current_number = current_number + 1

            -- Check if we've finished this range
            if current_number > current_range.last then
                current_range_idx = current_range_idx + 1
                current_number = 0
            end

            -- Stop processing if we started an animation
            if animating_number then
                break
            end
        end
    end
end

function draw_background()
    -- Dark Christmas green background
    love.graphics.clear(0.05, 0.15, 0.1)
end

function draw_title()
    love.graphics.setNewFont(24)
    local title = "Day 2: Gift Shop"
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

function draw_trash_can()
    local trash_x = WINDOW_WIDTH - 100
    local trash_y = 250
    local trash_width = 80
    local trash_height = 100

    -- Draw trash can body
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", trash_x - trash_width / 2, trash_y, trash_width, trash_height)

    -- Draw lid with rotation (hinged at back left)
    love.graphics.push()

    -- Calculate lid rotation (45 degrees max when fully open)
    local lid_angle = -math.pi / 4 * lid_open_progress -- Negative to rotate backwards
    local lid_width = trash_width + 10
    local lid_height = 10
    local hinge_x = trash_x - trash_width / 2 - 5
    local hinge_y = trash_y - 5 -- Center of lid thickness

    -- Move to hinge point, rotate, then draw
    love.graphics.translate(hinge_x, hinge_y)
    love.graphics.rotate(lid_angle)

    -- Draw lid
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("fill", 0, -lid_height / 2, lid_width, lid_height)

    -- Draw lid handle (positioned on the lid)
    love.graphics.setColor(0.5, 0.5, 0.5)
    local handle_x = lid_width / 2 - 10
    love.graphics.rectangle("fill", handle_x, -15, 20, 10, 5, 5)

    love.graphics.pop()

    -- Draw label below trash can
    love.graphics.setNewFont(14)
    love.graphics.setColor(1, 1, 1)
    local label_text = "Invalid Serial Numbers"
    local label_width = love.graphics.getFont():getWidth(label_text)
    love.graphics.print(label_text, trash_x - label_width / 2, trash_y + trash_height + 20)

    -- Draw total below label
    love.graphics.setNewFont(24)
    love.graphics.setColor(1, 0.84, 0)
    local total_text = tostring(solution)
    local text_width = love.graphics.getFont():getWidth(total_text)
    love.graphics.print(total_text, trash_x - text_width / 2, trash_y + trash_height + 45)
end

function draw_current_number()
    local center_x = WINDOW_WIDTH / 2
    local center_y = WINDOW_HEIGHT / 2

    -- Draw current number being checked (if not animating and still processing)
    if not animating_number and current_number > 0 and current_range_idx <= #ranges then
        love.graphics.setNewFont(48)
        love.graphics.setColor(1, 1, 1)
        local number_text = tostring(current_number)
        local text_width = love.graphics.getFont():getWidth(number_text)
        love.graphics.print(number_text, center_x - text_width / 2, center_y - 24)
    end

    -- Draw animating invalid number (can happen even after all ranges processed)
    if animating_number then
        local t = animating_number.progress
        -- Ease out cubic
        t = 1 - math.pow(1 - t, 3)

        local x = animating_number.x + (animating_number.target_x - animating_number.x) * t
        local y = animating_number.y + (animating_number.target_y - animating_number.y) * t

        -- Scale down as it moves
        local scale = 1 - (animating_number.progress * 0.5)

        love.graphics.setNewFont(48 * scale)
        love.graphics.setColor(1, 0.2, 0.2) -- Red for invalid
        local number_text = tostring(animating_number.value)
        local text_width = love.graphics.getFont():getWidth(number_text)
        love.graphics.print(number_text, x - text_width / 2, y - 24 * scale)
    end
end

function draw_current_state()
    local screenHeight = love.graphics.getHeight()

    -- Wait for animation to complete before showing solution
    if current_range_idx > #ranges and not animating_number then
        -- Completion message centered in bright green
        love.graphics.setNewFont(48)
        love.graphics.setColor(0.2, 0.9, 0.2)
        local completion_text = "Processing complete!"
        local completion_width = love.graphics.getFont():getWidth(completion_text)
        love.graphics.print(completion_text, (WINDOW_WIDTH - completion_width) / 2, WINDOW_HEIGHT / 2 - 24)
    elseif current_range_idx <= #ranges then
        -- Show current processing state
        love.graphics.setNewFont(18)
        love.graphics.setColor(1, 1, 1)
        local current_range = ranges[current_range_idx]
        local status = string.format("Finding invalid serial numbers in range %d/%d: %s",
            current_range_idx, #ranges, current_range.input)
        love.graphics.print(status, 50, 150)
    end
end

function love.draw()
    draw_background()
    Snow.draw(snow)
    draw_title()
    Slider.draw(speed_slider)
    Toggle.draw(input_toggle)
    draw_trash_can()
    draw_current_number()
    draw_current_state()
end

function love.keypressed(key)
    if key == "r" then
        reset_state()
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

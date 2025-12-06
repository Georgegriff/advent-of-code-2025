io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local file_utils = require("utils.file")
local part2 = require("part2")
local IsometricGrid = require("utils.isometric_grid")
local Tile = require("ui.tile")
local Slider = require("ui.slider")
local Toggle = require("ui.toggle")
local Set = require("utils.set")

local BORDER = 0
local PAPER = "@"
local EMPTY = "."

-- Window configuration
WINDOW_WIDTH = 1000
WINDOW_HEIGHT = 600

-- Simulation configuration
DEFAULT_SPEED = 50
SPEED = DEFAULT_SPEED
MAX_SPEED = 10000

local isometricGrid
local dataGrid
local paperTile
local panSpeed = 400
local zoomSpeed = 0.1
local minZoom = 0.1
local maxZoom = 5.0

-- Simulation state
local use_test_input = true
local points_to_check = {}   -- Queue of points to process
local allowed_points = Set() -- Points that can be removed (matches solution logic)
local allowed_count = 0      -- Manual counter to track count
local processing_delay = 0

-- Load grid from file
local function load_grid()
    local input_file = use_test_input and "./inputs/test.txt" or "./inputs/input.txt"
    dataGrid = part2.create_grid(input_file)

    -- Calculate grid dimensions
    local gridWidth = 0
    local gridHeight = 0
    if dataGrid and dataGrid.coordinates then
        gridHeight = #dataGrid.coordinates
    end

    for y = 1, gridHeight do
        local row = nil
        if dataGrid and dataGrid.coordinates then
            row = dataGrid.coordinates[y]
        end
        if row then
            local rowWidth = 0
            for x = 1, #row do
                if row[x] ~= nil then
                    rowWidth = x
                end
            end
            gridWidth = math.max(gridWidth, rowWidth)
        end
    end

    -- Create isometric grid with calculated dimensions
    isometricGrid = IsometricGrid(128, gridWidth, gridHeight)
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    isometricGrid:centerOnScreen(screenWidth, screenHeight)
end

-- Reset simulation state
local function reset_simulation()
    points_to_check = {}
    allowed_points = Set()
    allowed_count = 0
    processing_delay = 0

    -- Reload grid to restore original state (points may have been changed to EMPTY)
    load_grid()

    -- Initialize queue with ALL points (matching solution logic - grid:each_point)
    if dataGrid then
        dataGrid:each_point(function(point)
            table.insert(points_to_check, point)
        end)
    end
end

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
        load_grid()
        reset_simulation()
    end
})

-- Draw floor as isometric tiles for all grid positions
local function drawFloor()
    if not isometricGrid then
        return
    end

    -- Draw floor for all possible grid positions as filled isometric diamonds
    love.graphics.setColor(0.4, 0.4, 0.42)
    for y = 0, isometricGrid.mapHeight - 1 do
        for x = 0, isometricGrid.mapWidth - 1 do
            local vertices = isometricGrid:getTileVertices(x, y)
            love.graphics.polygon("fill", vertices)
        end
    end

    -- Draw subtle grid lines on top
    love.graphics.setColor(0.35, 0.35, 0.37)
    love.graphics.setLineWidth(1)
    for y = 0, isometricGrid.mapHeight - 1 do
        for x = 0, isometricGrid.mapWidth - 1 do
            local vertices = isometricGrid:getTileVertices(x, y)
            love.graphics.polygon("line", vertices)
        end
    end
end

-- Draw paper tiles only
local function drawPaperTiles()
    if not dataGrid or not isometricGrid then
        return
    end

    dataGrid:each_point(function(point)
        if point.entity == PAPER then
            -- Convert from 1-indexed to 0-indexed for isometric grid
            local isoX = point.x - 1
            local isoY = point.y - 1

            if paperTile and paperTile.draw then
                paperTile:draw(isometricGrid, isoX, isoY)
            end
        end
    end)
end

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Love2D - Day 4: Printing Department")

    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    load_grid()
    reset_simulation()

    -- Load paper tile image
    local paperImage = love.graphics.newImage("box.png")
    paperImage:setWrap("clamp", "clamp")
    local paperImgW, paperImgH = paperImage:getDimensions()
    local paperQuad = love.graphics.newQuad(
        BORDER,
        BORDER,
        paperImgW,
        paperImgH,
        paperImgW,
        paperImgH
    )
    paperTile = Tile(paperImage, paperQuad)
end

function love.update(dt)
    if not isometricGrid then
        return
    end

    -- Update UI components
    Toggle.update(input_toggle, dt)

    -- Pan with arrow keys or WASD
    local panX, panY = 0, 0
    if love.keyboard.isDown("left", "a") then
        panX = panSpeed * dt
    end
    if love.keyboard.isDown("right", "d") then
        panX = -panSpeed * dt
    end
    if love.keyboard.isDown("up", "w") then
        panY = panSpeed * dt
    end
    if love.keyboard.isDown("down", "s") then
        panY = -panSpeed * dt
    end

    if panX ~= 0 or panY ~= 0 then
        isometricGrid.offsetX = isometricGrid.offsetX + panX
        isometricGrid.offsetY = isometricGrid.offsetY + panY
    end

    -- Process simulation based on speed (matching part2.solution logic)
    if SPEED > 0 and #points_to_check > 0 then
        processing_delay = processing_delay + dt * SPEED

        while processing_delay >= 1 and #points_to_check > 0 do
            processing_delay = processing_delay - 1

            local point = table.remove(points_to_check, 1)

            -- Skip if already in allowed_points (matches solution checkPoint logic)
            if allowed_points:has(point) then
                goto continue
            end

            -- Use part2's is_coordinate_allowed function (exact match to solution logic)
            if part2.is_coordinate_allowed(point.x, point.y) then
                allowed_points:add(point)
                allowed_count = allowed_count + 1
                point.entity = EMPTY

                -- Add adjacent points to queue (matching solution recursive behavior)
                local adjacent = part2.adjacent_points(point)
                for _, adjPoint in ipairs(adjacent) do
                    if not allowed_points:has(adjPoint) then
                        table.insert(points_to_check, adjPoint)
                    end
                end
            end

            ::continue::
        end
    end
end

function love.wheelmoved(x, y)
    if not isometricGrid then
        return
    end

    -- Get screen center to zoom around
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    local centerX = screenWidth / 2
    local centerY = screenHeight / 2

    -- Apply zoom
    local zoomFactor = 1.0 + (y * zoomSpeed)
    local oldZoom = isometricGrid.zoom
    local newZoom = oldZoom * zoomFactor
    newZoom = math.max(minZoom, math.min(maxZoom, newZoom))

    -- Adjust offset to keep screen center point fixed during zoom
    -- Formula: newOffset = screenCenter - (screenCenter - oldOffset) * (newZoom / oldZoom)
    isometricGrid.offsetX = centerX - (centerX - isometricGrid.offsetX) * (newZoom / oldZoom)
    isometricGrid.offsetY = centerY - (centerY - isometricGrid.offsetY) * (newZoom / oldZoom)

    isometricGrid.zoom = newZoom
end

local function draw_background()
    love.graphics.clear(0.05, 0.15, 0.1)
end

local function draw_title()
    love.graphics.setNewFont(24)
    local title = "Day 4: Printing Department"
    local screenWidth = love.graphics.getWidth()
    local titleWidth = love.graphics.getFont():getWidth(title)
    local x = (screenWidth - titleWidth) / 2
    local y = 30

    love.graphics.setColor(0.7, 0.1, 0.1)
    love.graphics.print(title, x + 2, y + 2)
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.print(title, x, y)
end

local function draw_status()
    love.graphics.setNewFont(18)
    love.graphics.setColor(1, 1, 1)

    if #points_to_check > 0 then
        local status = string.format("Processing: %d points remaining", #points_to_check)
        love.graphics.print(status, 50, 150)
    else
        love.graphics.setColor(0.2, 0.9, 0.2)
        love.graphics.print("Processing complete!", 50, 150)
    end

    love.graphics.setColor(1, 0.84, 0)
    local solution_text = string.format("Rolls that can be removed: %d", allowed_count)
    love.graphics.print(solution_text, 50, 180)
end

function love.draw()
    draw_background()

    -- Draw isometric grid first (floor and paper tiles)
    drawFloor()
    drawPaperTiles()

    -- Draw UI on top
    draw_title()
    Slider.draw(speed_slider)
    Toggle.draw(input_toggle)
    draw_status()
end

function love.keypressed(key)
    if key == "r" then
        reset_simulation()
        SPEED = DEFAULT_SPEED
        speed_slider.value = DEFAULT_SPEED
        speed_slider.dragging = false
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
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

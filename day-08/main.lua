io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end

local IsometricGrid = require("utils.isometric_grid")
local part2 = require("part2")
local Slider = require("ui.slider")

-- Window configuration
WINDOW_WIDTH = 1000
WINDOW_HEIGHT = 600

local isometricGrid
local points = {}
local SCALE_FACTOR = 64 -- Will be calculated dynamically based on input data
local distances = {}
local currentStep = 0
local DEFAULT_SPEED = 2
local SPEED = DEFAULT_SPEED
local MAX_SPEED = 100
local timeSinceLastStep = 0
local isPaused = false
local isCompleted = false
local solution = nil
local use_test_input = true
local Set = require("utils.set")
local Circuit = require("circuit")

local function calculateDefaultSpeed(stepCount)
    -- Target: complete in ~30 seconds at default speed
    -- default_speed = steps_per_second = stepCount / 30
    return math.max(2, stepCount / 30)
end

local function calculateMaxSpeed(stepCount)
    -- Max speed is 20x the default speed
    return calculateDefaultSpeed(stepCount) * 20
end

-- Draw floor as isometric tiles
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

local function calculateScaleFactor(points, targetTileCount)
    -- Find the maximum range in x, y coordinates
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge

    for _, point in ipairs(points) do
        minX = math.min(minX, point.x)
        maxX = math.max(maxX, point.x)
        minY = math.min(minY, point.y)
        maxY = math.max(maxY, point.y)
    end

    local rangeX = maxX - minX
    local rangeY = maxY - minY
    local maxRange = math.max(rangeX, rangeY)

    -- Calculate how many coordinate units should fit in one tile
    -- so that the entire range fits within targetTileCount tiles
    if maxRange == 0 then
        return 1 -- Default if no range
    end

    -- Scale factor = coordinate_units_per_tile
    return maxRange / targetTileCount
end

local function getScreenPosition(point)
    -- Calculate min values for offsetting
    local minX, minY = math.huge, math.huge
    for _, p in ipairs(points) do
        local scaledX = p.x / SCALE_FACTOR
        local scaledY = p.y / SCALE_FACTOR
        minX = math.min(minX, scaledX)
        minY = math.min(minY, scaledY)
    end

    local gridX = math.floor((point.x / SCALE_FACTOR) - minX)
    local gridY = math.floor((point.y / SCALE_FACTOR) - minY)
    local scaledZ = point.z / SCALE_FACTOR

    local screenX, screenY = isometricGrid:getScreenCoords(gridX, gridY)
    screenY = screenY - (scaledZ * isometricGrid.zoom)

    local tileW = isometricGrid.tileWidth * isometricGrid.zoom
    local tileH = isometricGrid.tileHeight * isometricGrid.zoom

    return screenX + tileW / 2, screenY + tileH / 2
end

local function getCircuits()
    local circuitsList = {}
    local seenCircuits = {}

    for _, point in ipairs(points) do
        if point.circuit and not seenCircuits[point.circuit] then
            table.insert(circuitsList, point.circuit)
            seenCircuits[point.circuit] = true
        end
    end

    return circuitsList
end

local function drawConnections()
    if not isometricGrid or currentStep == 0 then
        return
    end

    local circuits = getCircuits()

    -- Color palette for different circuits
    local colors = {
        { 0.3, 0.7, 1.0 },
        { 1.0, 0.7, 0.3 },
        { 0.3, 1.0, 0.7 },
        { 1.0, 0.3, 0.7 },
        { 0.7, 0.3, 1.0 },
        { 0.7, 1.0, 0.3 },
    }

    love.graphics.setLineWidth(2)

    -- Draw connections within each circuit
    for circuitIdx, circuit in ipairs(circuits) do
        local color = colors[(circuitIdx % #colors) + 1]
        love.graphics.setColor(color[1], color[2], color[3], 0.6)

        local circuitPoints = circuit.points:values()

        -- Draw lines between all connected points in the circuit
        -- We'll use the distances that were used to connect them
        for i = 1, currentStep do
            local dist = distances[i]
            local pointA = dist.startPoint
            local pointB = dist.endPoint

            -- Check if both points are in this circuit
            if pointA.circuit == circuit and pointB.circuit == circuit then
                local x1, y1 = getScreenPosition(pointA)
                local x2, y2 = getScreenPosition(pointB)
                love.graphics.line(x1, y1, x2, y2)
            end
        end
    end
end

local function drawPoints()
    if not isometricGrid or #points == 0 then
        return
    end

    -- Calculate min values for offsetting
    local minX, minY = math.huge, math.huge
    for _, point in ipairs(points) do
        local scaledX = point.x / SCALE_FACTOR
        local scaledY = point.y / SCALE_FACTOR
        minX = math.min(minX, scaledX)
        minY = math.min(minY, scaledY)
    end

    local tileW = isometricGrid.tileWidth * isometricGrid.zoom
    local tileH = isometricGrid.tileHeight * isometricGrid.zoom
    local zoom = isometricGrid.zoom

    -- First pass: Draw shadows on the floor (as isometric ellipses)
    for _, point in ipairs(points) do
        -- Scale down and offset to grid coordinates
        local gridX = math.floor((point.x / SCALE_FACTOR) - minX)
        local gridY = math.floor((point.y / SCALE_FACTOR) - minY)
        local scaledZ = point.z / SCALE_FACTOR

        -- Get screen position for this grid tile (base position)
        local screenX, screenY = isometricGrid:getScreenCoords(gridX, gridY)

        -- Draw shadow as isometric ellipse (2:1 ratio for iso projection)
        local shadowAlpha = math.min(0.4, 0.2 + (scaledZ * 0.02))
        love.graphics.setColor(0, 0, 0, shadowAlpha)
        local shadowSize = (5 + (scaledZ * 0.5)) * zoom
        -- Ellipse with 2:1 ratio (horizontal is 2x vertical)
        love.graphics.ellipse("fill", screenX + tileW / 2, screenY + tileH / 2, shadowSize * 2, shadowSize)
    end

    -- Second pass: Draw points with height
    for _, point in ipairs(points) do
        -- Color based on whether point is in a circuit
        if point.circuit then
            love.graphics.setColor(0.3, 1.0, 0.3, 0.9) -- Green for connected points
        else
            love.graphics.setColor(1, 0.3, 0.3, 0.9)   -- Red for unconnected points
        end

        -- Scale down and offset to grid coordinates
        local gridX = math.floor((point.x / SCALE_FACTOR) - minX)
        local gridY = math.floor((point.y / SCALE_FACTOR) - minY)
        local scaledZ = point.z / SCALE_FACTOR

        -- Get screen position for this grid tile
        local screenX, screenY = isometricGrid:getScreenCoords(gridX, gridY)

        -- Apply height (z-axis) by offsetting y upward
        screenY = screenY - (scaledZ * zoom)

        -- Draw ellipse at tile center with height offset (2:1 ratio for iso projection)
        -- Size increases with height and scales with zoom
        local pointSize = (4 + (scaledZ * 0.3)) * zoom
        love.graphics.ellipse("fill", screenX + tileW / 2, screenY + tileH / 2, pointSize * 2, pointSize)
    end
end

-- UI Components (will be initialized in love.load)
local speed_slider = nil

local function reset_simulation()
    currentStep = 0
    timeSinceLastStep = 0
    isPaused = false
    isCompleted = false
    solution = nil
    -- Clear circuit assignments from points
    for _, point in ipairs(points) do
        point.circuit = nil
    end
end


local function draw_background()
    love.graphics.clear(0.05, 0.15, 0.1)
end

local function draw_title()
    love.graphics.setNewFont(24)
    local title = "Day 8: Playground"
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

    love.graphics.print(string.format("Step: %d / %d", currentStep, #distances), 50, 150)

    local circuits = getCircuits()
    love.graphics.print(string.format("Circuits: %d", #circuits), 50, 180)

    -- Count connected points
    local connectedCount = 0
    for _, point in ipairs(points) do
        if point.circuit then
            connectedCount = connectedCount + 1
        end
    end
    love.graphics.print(string.format("Connected Points: %d / %d", connectedCount, #points), 50, 210)

    if isCompleted and solution then
        love.graphics.setColor(0.2, 0.9, 0.2)
        love.graphics.print("Processing complete!", 50, 240)

        love.graphics.setColor(1, 0.84, 0)
        local connecting_box = distances[currentStep]
        love.graphics.print(string.format("Final Connection: (%d,%d,%d) <-> (%d,%d,%d)",
            connecting_box.startPoint.x, connecting_box.startPoint.y, connecting_box.startPoint.z,
            connecting_box.endPoint.x, connecting_box.endPoint.y, connecting_box.endPoint.z), 50, 270)
        love.graphics.print(string.format("Solution: %d x %d = %d",
            connecting_box.startPoint.x, connecting_box.endPoint.x, solution), 50, 300)
    elseif not isPaused then
        love.graphics.setColor(0.2, 0.9, 0.2)
        love.graphics.print("Running...", 50, 240)
    else
        love.graphics.setColor(1, 0.5, 0.2)
        love.graphics.print("Paused (SPACE to resume)", 50, 240)
    end
end

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, { resizable = false })
    love.window.setTitle("Love2D - Day 8: Playground")

    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setLineStyle("smooth")
    love.graphics.setLineJoin("bevel")

    -- Load points from input file
    local input_file = use_test_input and "inputs/test.txt" or "inputs/input.txt"
    points = part2.load_points(input_file)

    -- Get ordered distances for the algorithm
    distances = part2.get_ordered_distances(points)

    -- Calculate speeds based on step count
    DEFAULT_SPEED = calculateDefaultSpeed(#distances)
    MAX_SPEED = calculateMaxSpeed(#distances)
    SPEED = DEFAULT_SPEED

    -- Create speed slider with calculated values (at bottom of screen)
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    speed_slider = Slider.create({
        x = 200,
        y = screenHeight - 60,
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

    -- Calculate dynamic scale factor (target ~50 tiles for the largest dimension)
    SCALE_FACTOR = calculateScaleFactor(points, 50)

    -- Calculate grid size based on scaled points
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for _, point in ipairs(points) do
        local scaledX = point.x / SCALE_FACTOR
        local scaledY = point.y / SCALE_FACTOR
        minX = math.min(minX, scaledX)
        maxX = math.max(maxX, scaledX)
        minY = math.min(minY, scaledY)
        maxY = math.max(maxY, scaledY)
    end

    local mapWidth = math.ceil(maxX - minX) + 2
    local mapHeight = math.ceil(maxY - minY) + 2

    -- Create isometric grid with calculated dimensions
    isometricGrid = IsometricGrid(64, mapWidth, mapHeight)
    isometricGrid.zoom = 0.5 -- Start zoomed out to see more of the scene
    local screenWidth, screenHeight = love.graphics.getPixelDimensions()
    isometricGrid:centerOnScreen(screenWidth, screenHeight)
end

local function executeAlgorithmStep()
    if currentStep >= #distances then
        return
    end

    currentStep = currentStep + 1
    local curr_distance = distances[currentStep]
    local pointA = curr_distance.startPoint
    local pointB = curr_distance.endPoint

    -- This is the exact logic from part2.connect_circuits_until_fully_connected
    if pointA.circuit and pointB.circuit and pointB.circuit ~= pointA.circuit then
        -- join the circuits
        local circuitB = pointB.circuit
        for _, cirPoint in ipairs(circuitB.points:values()) do
            pointA.circuit:add_point(cirPoint)
        end
    elseif not pointA.circuit and not pointB.circuit then
        local circuit = Circuit()
        circuit:add_point(pointA)
        circuit:add_point(pointB)
    elseif pointA.circuit and not pointB.circuit then
        local circuit = pointA.circuit
        circuit:add_point(pointB)
    elseif pointB.circuit and not pointA.circuit then
        local circuit = pointB.circuit
        circuit:add_point(pointA)
    end

    -- Check if we're done (single circuit AND all points connected)
    local circuits = getCircuits()
    local connectedCount = 0
    for _, point in ipairs(points) do
        if point.circuit then
            connectedCount = connectedCount + 1
        end
    end

    if #circuits == 1 and connectedCount == #points then
        isPaused = true
        isCompleted = true
        -- The connecting box is the distance we just processed (currentStep)
        local connecting_box = distances[currentStep]
        solution = connecting_box.startPoint.x * connecting_box.endPoint.x
    end
end

function love.update(dt)
    if isometricGrid then
        isometricGrid:update(dt)
    end

    -- Step through the algorithm based on speed
    if not isPaused and SPEED > 0 and currentStep < #distances then
        timeSinceLastStep = timeSinceLastStep + dt * SPEED

        while timeSinceLastStep >= 1 and currentStep < #distances do
            timeSinceLastStep = timeSinceLastStep - 1
            executeAlgorithmStep()
        end
    end
end

function love.wheelmoved(x, y)
    if isometricGrid then
        isometricGrid:wheelmoved(x, y)
    end
end

function love.draw()
    draw_background()
    drawFloor()
    drawConnections()
    drawPoints()

    -- Draw UI on top
    draw_title()
    draw_status()
    Slider.draw(speed_slider)
end

function love.keypressed(key)
    if key == "space" then
        isPaused = not isPaused
    elseif key == "r" then
        reset_simulation()
        SPEED = DEFAULT_SPEED
        speed_slider.value = DEFAULT_SPEED
        speed_slider.dragging = false
    elseif key == "=" or key == "+" then
        -- Speed up
        SPEED = math.min(MAX_SPEED, SPEED + 5)
        speed_slider.value = SPEED
        speed_slider.on_change(SPEED)
    elseif key == "-" or key == "_" then
        -- Slow down
        SPEED = math.max(0, SPEED - 5)
        speed_slider.value = SPEED
        speed_slider.on_change(SPEED)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
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

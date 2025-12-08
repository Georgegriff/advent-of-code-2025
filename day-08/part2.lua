local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local Point = require("utils.point3d")
local Circuit = require("circuit")
local Set = require("utils.set")
local M = {}

---@class Distance
---@field distance number
---@field startPoint Point3D
---@field endPoint Point3D

---@return Distance[]
function M.get_ordered_distances(points)
    local distances = {}
    -- Only generate unique pairs (i < j) to avoid duplicates and expensive memoization
    for i, pointA in ipairs(points) do
        for j = i + 1, #points do
            local pointB = points[j]
            local distance = M.euclidean_distance(pointA, pointB)
            table.insert(distances, {
                distance = distance,
                startPoint = pointA,
                endPoint = pointB
            })
        end
    end

    table.sort(distances, function(distA, distB)
        return distA.distance < distB.distance
    end)

    return distances
end

function M.solution(input_file)
    ---@type Circuit[]
    local circuits = {}

    ---@type Point3D[]
    local points = {}
    file_utils.read_file_lines(input_file, function(line)
        local x, y, z = table.unpack(string_utils.split(line, ",", function(str_part) return tonumber(str_part) end))
        local point = Point(x, y, z)
        table.insert(points, point)
    end)

    local distances = M.get_ordered_distances(points)

    ---@type Set
    local connected_points = Set()
    local is_completed = function() return #circuits == 1 and #connected_points == #points end
    local iterations_count = 1
    while (not is_completed() and iterations_count <= #distances) do
        local curr_distance = distances[iterations_count]
        local pointA = curr_distance.startPoint
        local pointB = curr_distance.endPoint
        if pointA.circuit and pointB.circuit and pointB.circuit ~= pointA.circuit then
            -- join the circuits

            local circuitB = pointB.circuit
            for _, cirPoint in ipairs(circuitB.points:values()) do
                pointA.circuit:add_point(cirPoint)
            end
            table.remove(circuits, M.index_of(circuits, circuitB))
        elseif not pointA.circuit and not pointB.circuit then
            local circuit = Circuit()
            circuit:add_point(pointA)
            circuit:add_point(pointB)
            connected_points:add(pointA)
            connected_points:add(pointB)
            table.insert(circuits, circuit)
        elseif pointA.circuit and not pointB.circuit then
            local circuit = pointA.circuit
            connected_points:add(pointB)
            circuit:add_point(pointB)
        elseif pointB.circuit and not pointA.circuit then
            local circuit = pointB.circuit
            connected_points:add(pointA)
            circuit:add_point(pointA)
        end
        iterations_count = iterations_count + 1
    end
    local connecting_box = distances[iterations_count - 1]
    -- find two closest points, join them and build a circuit
    -- keep track of unconnected points
    -- find then next two closest points, if one of these points is already in a circuit add it to that circuit
    --- else create new circuit
    -- repeat until you have no more unconnected points

    ---
    -- todo sort by size of points Set
    if not connecting_box then
        error("No connecting box found")
    end
    return connecting_box.startPoint.x * connecting_box.endPoint.x
end

function M.index_of(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

---@param pointA Point3D
---@param pointB Point3D
---@return number
function M.euclidean_distance(pointA, pointB)
    ---@param p1 number
    ---@param p2 number
    function inner(p1, p2)
        return math.pow((p2 - p1), 2)
    end

    return math.sqrt(inner(pointB.x, pointA.x) + inner(pointB.y, pointA.y) + inner(pointB.z, pointA.z))
end

---@param circuits Circuit[]
---@return number
function M.top_3_largest_circuit(circuits)
    table.sort(circuits, function(a, b)
        return a:size() > b:size()
    end)

    local top_3_sum = circuits[1]:size()
    for i = 2, 3 do
        if i > #circuits then
            error("Not enough circuits!")
        end
        top_3_sum = top_3_sum * circuits[i]:size()
    end
    return top_3_sum
end

if script_utils.should_run_main() then
    local input_file = arg[1] or "./inputs/input.txt"
    local start_time = os.clock()
    local solution = M.solution(input_file)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

local file_utils = require("utils.file")
local script_utils = require("utils.script")
local string_utils = require("utils.string")
local Point = require("utils.point3d")
local Circuit = require("circuit")
local M = {}

---@class Distance
---@field distance number
---@field startPoint Point3D
---@field endPoint Point3D

---@return Distance[]
function M.get_ordered_distances(points)
    local distances = {}
    local memoized_checks = {}
    for _, pointA in ipairs(points) do
        for _, pointB in ipairs(points) do
            if pointA ~= pointB then
                local memo_string = M.get_memo_string(points, pointA, pointB)
                if not memoized_checks[memo_string] then
                    local distance = M.euclidean_distance(pointA, pointB)
                    memoized_checks[memo_string] = true
                    table.insert(distances, {
                        distance = distance,
                        startPoint = pointA,
                        endPoint = pointB
                    })
                end
            end
        end
    end

    table.sort(distances, function(distA, distB)
        return distA.distance < distB.distance
    end)

    return distances
end

function M.solution(input_file, iterations_count)
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

    local iterations_max = iterations_count
    local iterations_count = 1
    -- might need to be > 1 because can't make a line from 1 point
    while (iterations_count <= iterations_max) do
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
            table.insert(circuits, circuit)
        elseif pointA.circuit and not pointB.circuit then
            local circuit = pointA.circuit
            circuit:add_point(pointB)
        elseif pointB.circuit and not pointA.circuit then
            local circuit = pointB.circuit
            circuit:add_point(pointA)
        end
        iterations_count = iterations_count + 1
    end
    -- find two closest points, join them and build a circuit
    -- keep track of unconnected points
    -- find then next two closest points, if one of these points is already in a circuit add it to that circuit
    --- else create new circuit
    -- repeat until you have no more unconnected points

    ---
    -- todo sort by size of points Set

    return M.top_3_largest_circuit(circuits)
end

function M.index_of(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

function M.get_memo_string(points, pointA, pointB)
    local indexA = M.index_of(points, pointA)
    local indexB = M.index_of(points, pointB)

    if indexA < indexB then
        local currA = pointA
        pointA = pointB
        pointB = currA
    end

    return string.format("%s-%s", pointA:to_s(), pointB:to_s())
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
    local solution = M.solution(input_file, 1000)
    local end_time = os.clock()
    local elapsed_time = (end_time - start_time) * 1000
    print(string.format("The answer is: %s", solution))
    print(string.format("Time taken: %.2f milliseconds", elapsed_time))
end

return M

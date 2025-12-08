local Object = require "utils.object"
local Set = require("utils.set")
---@class Circuit
---@field points Set
local Circuit = Object:extend()


function Circuit:new()
    self.points = Set()
end

---@param point Point3D
function Circuit:add_point(point)
    self.points:add(point)
    point.circuit = self
end

---@param point Point3D
function Circuit:has_point(point)
    return self.points:has(point)
end

function Circuit:size()
    return #self.points
end

return Circuit

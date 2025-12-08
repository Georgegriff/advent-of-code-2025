local Object = require "utils.object"

---@class Point3D : Object
---@field x number
---@field y number
---@field z number
---@field circuit Circuit|nil
local Point3D = Object:extend()


---@param x number
---@param y number
function Point3D:new(x, y, z)
    self.x = x or nil
    self.y = y or nil
    self.z = z or nil
    self.circuit = nil
end

function Point3D:to_s()
    return string.format("%s,%s,%s", self.x, self.y, self.z)
end

return Point3D

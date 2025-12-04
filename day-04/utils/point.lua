local Object = require "utils.object"

---@class Point : Object
---@field x number
---@field y number
---@field entity string
local Point = Object:extend()


---@param x number
---@param y number
---@param entity string
function Point:new(x, y, entity)
    self.x = x or nil
    self.y = y or nil
    self.entity = entity
end

return Point

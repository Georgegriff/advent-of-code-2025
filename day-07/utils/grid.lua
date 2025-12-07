local Object = require "utils.object"
local Point = require "utils.point"

---@class Grid : Object
---@field coordinates Point[][]
---@field width number
---@field height number
local Grid = Object:extend()

function Grid:new()
    self.coordinates = {}
end

---@param point Point
function Grid:add_point(point)
    local x = point.x
    local y = point.y
    local row = self.coordinates[y]

    if row == nil then
        self.coordinates[y] = {}
        row = self.coordinates[y]
    end
    row[x] = point
end

function Grid:in_bounds(x, y)
    if x < 1 or y < 1 or y > #self.coordinates then
        return false
    end
    local row = self.coordinates[y]

    if x > #row then
        return false
    end

    return true
end

function Grid:each_point(callback)
    local rows = self.coordinates
    for y = 1, #rows do
        local row = rows[y]
        for x = 1, #row do
            local point = self.coordinates[y][x]
            callback(point)
        end
    end
end

function Grid:to_s()
    local rows = self.coordinates
    if #rows == 0 then
        return ""
    end
    local printer = ""
    for y = 1, #rows do
        ---@type Point[]
        local row = rows[y]
        if row == nil then
            return ""
        end
        local rowPrinter = ""
        for x = 1, #row do
            local point = row[x]
            rowPrinter = rowPrinter .. point.entity
        end
        local newline = y < #rows and "\n" or ""
        printer = printer .. rowPrinter .. newline
    end
    return printer
end

function Grid:print()
    print(self:to_s())
end

return Grid

local Object = require "utils.object"

---@class OrderedMap : Object
---@field data table
---@field order any[]
---@field index table
local OrderedMap = Object:extend()

function OrderedMap:new()
    self.data = {}
    self.order = {}
    self.index = {} -- maps key → position in `order`
end

function OrderedMap:set(k, v)
    if self.data[k] == nil then
        -- new key
        table.insert(self.order, k)
        self.index[k] = #self.order
    end
    self.data[k] = v
end

function OrderedMap:get(k)
    return self.data[k]
end

function OrderedMap:remove(k)
    local pos = self.index[k]
    if not pos then return end

    -- remove from data
    self.data[k] = nil
    self.index[k] = nil

    -- remove from order array (compact)
    table.remove(self.order, pos)

    -- fix indexes of shifted keys
    for i = pos, #self.order do
        self.index[self.order[i]] = i
    end
end

function OrderedMap:pairs()
    local i = 0
    return function()
        i = i + 1
        local k = self.order[i]
        if k then
            return k, self.data[k]
        end
    end
end

return OrderedMap

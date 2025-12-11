local Object = require "utils.object"




---@class Node : Object
---@field id string
---@field neighbors Node[]
local Node = Object:extend()

---@param id string
function Node:new(id)
    self.id = id
    self.neighbors = {}
end

---@param nodes Node[]
function Node:add_neighbors(nodes)
    for _, node in ipairs(nodes) do
        table.insert(self.neighbors, node)
    end
end

---@param node Node
function Node:add_neighbor(node)
    table.insert(self.neighbors, node)
end

function Node:__tostring()
    return self:to_s()
end

function Node:to_s()
    local neighbors_str = {}
    for _, neighbor in ipairs(self.neighbors) do
        table.insert(neighbors_str, string.format("%s", neighbor.id))
    end
    local printer = string.format("%s: %s", self.id, table.concat(neighbors_str, " "))
    return printer
end

return Node

local Object = require "utils.object"
local Node = require "node"
local string_utils = require "utils.string"
local unpack = table.unpack or unpack

---@class Graph : Object
---@field coordinates Point[][]
---@field width number
---@field height number
local Graph = Object:extend()

---@param line string
function Graph:parse_input_line(line)
    local id, neighbour_str = unpack(string_utils.split(line, ":"))
    ---@type Node[]
    local neighbors = string_utils.split(neighbour_str, " ", function(n)
        return self:add_node(n)
    end)
    local new_node = self:add_node(id)
    new_node:add_neighbors(neighbors)
end

function Graph:new()
    self.nodes = {}
end

---@param id string
---@return Node
function Graph:add_node(id)
    if not self.nodes[id] then
        local node = Node(id)
        self.nodes[id] = node
    end
    return self.nodes[id]
end

---@param id string
---@return Node|nil
function Graph:get_node(id)
    return self.nodes[id]
end

---@param start_node_id string
---@param callback fun(node: Node)
function Graph:traverse(start_node_id, callback)
    ---@param search_node Node
    function dfs(search_node, visited_nodes)
        visited_nodes = visited_nodes or {}
        if visited_nodes[search_node.id] then
            return
        end
        visited_nodes[search_node.id] = true
        callback(search_node)
        for _, neighbor in ipairs(search_node.neighbors) do
            dfs(neighbor, visited_nodes)
        end
        visited_nodes[search_node.id] = nil
    end

    local start_node = self.nodes[start_node_id]
    dfs(start_node)
end

function Graph:to_s()
    local nodes_str = {}
    for _, node in pairs(self.nodes) do
        table.insert(nodes_str, string.format("%s", node))
    end
    return table.concat(nodes_str, "\n")
end

function Graph:__tostring()
    return self:to_s()
end

function Graph:print()
    print(self:to_s())
end

return Graph

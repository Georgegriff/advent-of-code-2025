local Object = require "utils.object"
local Node = require "node"
local string_utils = require "utils.string"
local OrderedMap = require "utils.orderedmap"
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
---@param callback fun(node: Node, visited_nodes: table)
function Graph:traverse(start_node_id, callback)
    ---@param search_node Node
    function dfs(search_node, visited_nodes)
        ---@type OrderedMap
        visited_nodes = visited_nodes or OrderedMap()
        if visited_nodes:get(search_node.id) == true then
            return
        end
        visited_nodes:set(search_node.id, true)
        callback(search_node, visited_nodes)
        for _, neighbor in ipairs(search_node.neighbors) do
            dfs(neighbor, visited_nodes)
        end
        visited_nodes:remove(search_node.id)
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

---@param start_node_id string
---@param end_node_id string
---@return number
function Graph:count_paths(start_node_id, end_node_id)
    local path_counts = {}


    local function count_from_node(current_id, target_id)
        if path_counts[current_id] ~= nil then
            return path_counts[current_id]
        end

        if current_id == target_id then
            path_counts[current_id] = 1
            return 1
        end

        local current_node = self.nodes[current_id]
        local has_neighbors = current_node and current_node.neighbors and #current_node.neighbors > 0

        if not has_neighbors then
            path_counts[current_id] = 0
            return 0
        end

        local paths_from_current = 0
        for _, neighbor in ipairs(current_node.neighbors) do
            paths_from_current = paths_from_current + count_from_node(neighbor.id, target_id)
        end

        path_counts[current_id] = paths_from_current
        return paths_from_current
    end

    return count_from_node(start_node_id, end_node_id)
end

return Graph

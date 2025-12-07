local Object = require "utils.object"
---@class Set
local Set = Object:extend()

function Set:new()
    self._ = {}
end

function Set:add(x)
    self._[x] = true
end

function Set:remove(x)
    self._[x] = nil
end

function Set:has(x)
    return self._[x] ~= nil
end

function Set.__len(self)
    local n = 0
    for _ in pairs(self._) do
        n = n + 1
    end
    return n
end

return Set

local Object = require "utils.object"

---@class Set
local Set = Object:extend()

function Set:new()
    self._ = {}
    self._order = {}
end

function Set:add(x)
    if not self._[x] then
        table.insert(self._order, x)
    end
    self._[x] = true
end

function Set:remove(x)
    if self._[x] then
        self._[x] = nil
        for i, v in ipairs(self._order) do
            if v == x then
                table.remove(self._order, i)
                break
            end
        end
    end
end

function Set:has(x)
    return self._[x] ~= nil
end

function Set:nth(n)
    return self._order[n]
end

function Set:values()
    return self._order
end

function Set.__len(self)
    local n = 0
    for _ in pairs(self._) do
        n = n + 1
    end
    return n
end

function Set.__ipairs(self)
    return ipairs(self._order)
end

function Set.__pairs(self)
    return ipairs(self._order)
end

function Set:iter()
    local i = 0
    return function()
        i = i + 1
        return self._order[i]
    end
end

return Set

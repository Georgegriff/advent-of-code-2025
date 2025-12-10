local Object = require "utils.object"
local string_utils = require "utils.string"
---@class State : Object
---@field values number[]
---@field type string
local State = Object:extend()

local ON = "#"
local OFF = "."

---@param char string
function State.parse_target_char(char)
    local value = char == ON and 1 or 0
    return value
end

---@param values number[]
function State:new(values, type)
    self.values = values
    self.type = type or "target"
end

function State:to_target_string()
    local printer = ""
    for _, entry in ipairs(self.values) do
        local value = entry == 1 and ON or OFF
        printer = printer .. string.format("%s", value)
    end
    return printer
end

function State:to_button_string()
    local state_values = {}
    for i, value in ipairs(self.values) do
        if value == 1 then
            table.insert(state_values, i - 1)
        end
    end
    return table.concat(state_values, ",")
end

function State:to_values_strings()
    local printer = ""
    for _, entry in ipairs(self.values) do
        printer = printer .. string.format("%d", entry)
    end
    return printer
end

function State:__tostring()
    if self.type == "target" then
        return self:to_target_string()
    else
        return self:to_button_string()
    end
end

---@param sequence State
function State:xor(sequence)

end

return State

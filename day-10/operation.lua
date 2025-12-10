local Object = require "utils.object"
local State = require "state"
---@class Operation : Object
---@field target State
---@field buttons State[]
local Operation = Object:extend()

local TOKENS = {
    TARGET_START = "[",
    TARGET_END = "]",
    TARGET_OFF = ".",
    TARGET_ON = "#",
    BUTTON_START = "(",
    BUTTON_SEPARATOR = ",",
    BUTTON_END = ")"
}

---@param input string
function Operation.from_input_string(input)
    local buttons = {}
    local target = nil
    local currentTokenIndex = 1
    while (currentTokenIndex <= #input) do
        local currentToken = input:sub(currentTokenIndex, currentTokenIndex)

        if currentToken == TOKENS.TARGET_START then
            currentTokenIndex = currentTokenIndex + 1
            target, currentTokenIndex = Operation.consume_target(input, currentTokenIndex)
        elseif currentToken == TOKENS.BUTTON_START then
            currentTokenIndex = currentTokenIndex + 1
            if target == nil then
                error("Target not fond before buttons")
            end
            local button, newTokenIndex = Operation.consume_button(target, input, currentTokenIndex)
            table.insert(buttons, button)
            currentTokenIndex = newTokenIndex
        else
            currentTokenIndex = currentTokenIndex + 1
        end
    end

    return Operation(target, buttons)
end

---@param input string
---@param target State
---@param currentTokenIndex number
---@returns State, number
function Operation.consume_button(target, input, currentTokenIndex)
    local currentToken = input:sub(currentTokenIndex, currentTokenIndex)
    local values = {}
    for _ in ipairs(target.values) do
        table.insert(values, 0)
    end
    while currentToken ~= TOKENS.BUTTON_END do
        if currentToken ~= TOKENS.BUTTON_SEPARATOR then
            local value_index = tonumber(currentToken) + 1
            values[value_index] = 1
        end
        currentTokenIndex = currentTokenIndex + 1
        currentToken = input:sub(currentTokenIndex, currentTokenIndex)
    end
    local button = State(values, "button")
    return button, currentTokenIndex + 1
end

---@param input string
---@param currentTokenIndex number
---@returns State, number
function Operation.consume_target(input, currentTokenIndex)
    local currentToken = input:sub(currentTokenIndex, currentTokenIndex)
    local values = {}
    while currentToken ~= TOKENS.TARGET_END do
        table.insert(values, State.parse_target_char(currentToken))
        currentTokenIndex = currentTokenIndex + 1
        currentToken = input:sub(currentTokenIndex, currentTokenIndex)
    end
    local target = State(values, "target")
    return target, currentTokenIndex + 1
end

---@param target State
---@param buttons State[]
function Operation:new(target, buttons)
    self.target = target
    self.buttons = buttons
end

function Operation:to_string()
    local printer = string.format("%s%s%s ", TOKENS.TARGET_START, self.target, TOKENS.TARGET_END)
    local button_values = {}
    for _, button in ipairs(self.buttons) do
        table.insert(button_values, TOKENS.BUTTON_START .. string.format("%s", button) .. TOKENS.BUTTON_END)
    end
    printer = printer .. table.concat(button_values, " ")
    return printer
end

function Operation:to_values_string()
    local printer = string.format("Target:     %s\n", self.target:to_values_strings())

    for i, entry in ipairs(self.buttons) do
        printer = printer .. string.format("Button %s:   %s\n", i, entry:to_values_strings())
    end
    return printer
end

function Operation:__tostring()
    return self:to_string()
end

return Operation

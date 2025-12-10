local Object = require "utils.object"
local State = require "state"
---@class Operation : Object
---@field current State
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

local function combos_of_size(list, k)
    local results = {}

    local function backtrack(start, current)
        -- If we reached size k, store a copy
        if #current == k then
            local c = {}
            for i = 1, k do c[i] = current[i] end
            results[#results + 1] = c
            return
        end

        -- Try all remaining elements
        for i = start, #list do
            current[#current + 1] = list[i]
            backtrack(i + 1, current)
            current[#current] = nil -- undo
        end
    end

    backtrack(1, {})
    return results
end


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

function Operation.create_initial_state(target_size)
    local values = {}
    for i = 1, target_size do
        table.insert(values, 0)
    end

    return State(values)
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
    self:reset()
end

function Operation:reset()
    self.current = Operation.create_initial_state(#self.target.values)
end

function Operation:find_min_presses()
    for combo_size = 1, #self.buttons do
        local combinations = combos_of_size(self.buttons, combo_size)
        for _, button_combo in ipairs(combinations) do
            self:reset()
            self:xor_array(button_combo)
            if self:state_matches_target() then
                return combo_size
            end
        end
    end

    return nil
end

---@param input_arr State[]
function Operation:xor_array(input_arr)
    for _, button in ipairs(input_arr) do
        self.current:xor(button)
    end
end

function Operation:state_matches_target()
    local target_str = self.target:to_target_string()
    local current_str = self.current:to_target_string()
    return target_str == current_str
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

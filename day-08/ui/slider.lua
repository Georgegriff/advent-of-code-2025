local M = {}

---@class Slider
---@field x number
---@field y number
---@field width number
---@field height number
---@field min_value number
---@field max_value number
---@field value number
---@field exponential boolean
---@field dragging boolean
---@field label string
---@field on_change function

---Create a new slider
---@param config table Configuration with x, y, width, height, min_value, max_value, initial_value, label, exponential, on_change
---@return Slider
function M.create(config)
    return {
        x = config.x,
        y = config.y,
        width = config.width or 600,
        height = config.height or 20,
        min_value = config.min_value or 0,
        max_value = config.max_value or 100,
        value = config.initial_value or config.min_value or 0,
        exponential = config.exponential or false,
        dragging = false,
        label = config.label or "Value",
        on_change = config.on_change or function() end
    }
end

---Draw a slider
---@param slider Slider
function M.draw(slider)
    -- Draw label with keyboard hint
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setNewFont(16)
    love.graphics.print(slider.label .. ": " .. math.floor(slider.value), slider.x, slider.y - 25)

    -- Draw keyboard hint
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setNewFont(12)
    love.graphics.print("(+/- keys)", slider.x + 100, slider.y - 22)

    -- Draw slider track
    love.graphics.setColor(0.1, 0.3, 0.1)
    love.graphics.rectangle("fill", slider.x, slider.y, slider.width, slider.height)

    -- Calculate slider position
    local range = slider.max_value - slider.min_value
    local normalized_value = (slider.value - slider.min_value) / range

    local slider_position
    if slider.exponential then
        -- Use square root for exponential slider (inverse of x^2)
        slider_position = math.sqrt(normalized_value)
    else
        slider_position = normalized_value
    end

    local fill_width = slider_position * slider.width

    -- Draw slider fill
    love.graphics.setColor(0.8, 0.1, 0.1)
    love.graphics.rectangle("fill", slider.x, slider.y, fill_width, slider.height)

    -- Draw slider handle
    local handle_x = slider.x + fill_width
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.circle("fill", handle_x, slider.y + slider.height / 2, 10)
end

---Update slider value from mouse position
---@param slider Slider
---@param mouse_x number
local function update_value(slider, mouse_x)
    local relative_x = math.max(0, math.min(mouse_x - slider.x, slider.width))
    local slider_position = relative_x / slider.width

    local normalized_value
    if slider.exponential then
        -- Use x^2 for exponential response
        normalized_value = slider_position * slider_position
    else
        normalized_value = slider_position
    end

    local range = slider.max_value - slider.min_value
    slider.value = slider.min_value + (normalized_value * range)
    slider.on_change(slider.value)
end

---Handle mouse press for slider
---@param slider Slider
---@param x number
---@param y number
---@return boolean true if slider was clicked
function M.mouse_pressed(slider, x, y)
    if x >= slider.x and x <= slider.x + slider.width and
        y >= slider.y and y <= slider.y + slider.height then
        slider.dragging = true
        update_value(slider, x)
        return true
    end
    return false
end

---Handle mouse release for slider
---@param slider Slider
function M.mouse_released(slider)
    slider.dragging = false
end

---Handle mouse moved for slider
---@param slider Slider
---@param x number
function M.mouse_moved(slider, x)
    if slider.dragging then
        update_value(slider, x)
    end
end

return M

local M = {}

---@class ToggleSwitch
---@field x number
---@field y number
---@field width number
---@field height number
---@field knob_width number
---@field transition number
---@field state boolean
---@field label_off string
---@field label_on string
---@field on_toggle function

---Create a new toggle switch
---@param config table Configuration with x, y, width, height, initial_state, label_off, label_on, on_toggle
---@return ToggleSwitch
function M.create(config)
    return {
        x = config.x,
        y = config.y,
        width = config.width or 100,
        height = config.height or 35,
        knob_width = config.knob_width or 45,
        transition = config.initial_state and 1 or 0,
        state = config.initial_state or false,
        label_off = config.label_off or "OFF",
        label_on = config.label_on or "ON",
        on_toggle = config.on_toggle or function() end
    }
end

---Update toggle switch animation
---@param toggle ToggleSwitch
---@param dt number
function M.update(toggle, dt)
    local target_transition = toggle.state and 1 or 0
    if toggle.transition < target_transition then
        toggle.transition = math.min(toggle.transition + dt * 5, target_transition)
    elseif toggle.transition > target_transition then
        toggle.transition = math.max(toggle.transition - dt * 5, target_transition)
    end
end

---Draw a toggle switch
---@param toggle ToggleSwitch
function M.draw(toggle)
    -- Draw switch track (background)
    local track_color = toggle.state and { 0.1, 0.5, 0.1 } or { 0.8, 0.6, 0.1 }
    love.graphics.setColor(track_color[1], track_color[2], track_color[3], 0.5)
    love.graphics.rectangle("fill", toggle.x, toggle.y, toggle.width, toggle.height, toggle.height / 2)

    -- Draw gold border around track
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", toggle.x, toggle.y, toggle.width, toggle.height, toggle.height / 2)
    love.graphics.setLineWidth(1)

    -- Draw labels inside track
    love.graphics.setNewFont(11)
    -- OFF label on left
    love.graphics.setColor(1, 1, 1, toggle.state and 0.8 or 0.4)
    local off_width = love.graphics.getFont():getWidth(toggle.label_off)
    love.graphics.print(toggle.label_off, toggle.x + 8, toggle.y + 10)

    -- ON label on right
    love.graphics.setColor(1, 1, 1, toggle.state and 0.4 or 0.8)
    local on_width = love.graphics.getFont():getWidth(toggle.label_on)
    love.graphics.print(toggle.label_on, toggle.x + toggle.width - on_width - 8, toggle.y + 10)

    -- Calculate knob position
    local knob_x = toggle.x + toggle.transition * (toggle.width - toggle.knob_width)
    local knob_y = toggle.y

    -- Draw knob shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", knob_x + 2, knob_y + 2, toggle.knob_width, toggle.height, toggle.height / 2)

    -- Draw knob
    love.graphics.setColor(1, 0.84, 0)
    love.graphics.rectangle("fill", knob_x, knob_y, toggle.knob_width, toggle.height, toggle.height / 2)

    -- Draw knob highlight
    love.graphics.setColor(1, 1, 0.6, 0.5)
    love.graphics.rectangle("fill", knob_x + 3, knob_y + 3, toggle.knob_width - 6, toggle.height / 2 - 3,
        toggle.height / 4)

    -- Draw active text on knob
    love.graphics.setNewFont(12)
    local knob_text = toggle.state and toggle.label_on or toggle.label_off
    local text_width = love.graphics.getFont():getWidth(knob_text)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.print(knob_text, knob_x + (toggle.knob_width - text_width) / 2, knob_y + 9)
end

---Handle mouse press for toggle switch
---@param toggle ToggleSwitch
---@param x number
---@param y number
---@return boolean true if toggle was clicked
function M.mouse_pressed(toggle, x, y)
    if x >= toggle.x and x <= toggle.x + toggle.width and
        y >= toggle.y and y <= toggle.y + toggle.height then
        toggle.state = not toggle.state
        toggle.on_toggle(toggle.state)
        return true
    end
    return false
end

return M

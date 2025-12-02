local M = {}

---@class Snowflake
---@field x number
---@field y number
---@field speed number
---@field size number

---@class Snow
---@field snowflakes Snowflake[]
---@field width number
---@field height number

---Create a new snow effect
---@param config table Configuration with particle_count (default 100), width, height
---@return Snow
function M.create(config)
    local particle_count = config.particle_count or 100
    local width = config.width or love.graphics.getWidth()
    local height = config.height or love.graphics.getHeight()

    local snowflakes = {}
    for i = 1, particle_count do
        table.insert(snowflakes, {
            x = math.random(0, width),
            y = math.random(0, height),
            speed = math.random(10, 30),
            size = math.random(2, 5)
        })
    end

    return {
        snowflakes = snowflakes,
        width = width,
        height = height
    }
end

---Update snow particles
---@param snow Snow
---@param dt number
function M.update(snow, dt)
    for _, flake in ipairs(snow.snowflakes) do
        flake.y = flake.y + flake.speed * dt
        if flake.y > snow.height then
            flake.y = -10
            flake.x = math.random(0, snow.width)
        end
    end
end

---Draw snow particles
---@param snow Snow
function M.draw(snow)
    love.graphics.setColor(1, 1, 1, 0.8)
    for _, flake in ipairs(snow.snowflakes) do
        love.graphics.circle("fill", flake.x, flake.y, flake.size)
    end
end

return M

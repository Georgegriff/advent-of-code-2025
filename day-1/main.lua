io.stdout:setvbuf("no")

if arg[2] == "debug" then
    require("lldebugger").start()
end



function love.load()
    print("Hello")
end

function love.update(dt)

end

function love.draw()

end

-- Reset position when R is pressed
-- function love.keypressed(key)

-- end

local M = {}

function M.add(a, b)
    return a + b
end

return M

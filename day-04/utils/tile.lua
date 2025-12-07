local Object = require("utils.classic")

local Tile = Object:extend()

function Tile:new(image, quad)
    self.image = image
    self.quad = quad
end

function Tile:draw(grid, x, y)
    if not self.image then
        return
    end
    local isoX, isoY = grid:getScreenCoords(x, y)
    local imgW, imgH = self.image:getDimensions()
    local scale = grid.tileWidth / (imgW)
    local scaledW = (imgW) * scale
    local scaledH = (imgH) * scale
    local drawX = isoX + grid.tileWidth / scaledW / 2
    local drawY = isoY + grid.tileHeight - scaledH

    love.graphics.setColor(1, 1, 1)
    if self.quad then
        love.graphics.draw(self.image, self.quad, drawX, drawY, 0, scale, scale)
    else
        love.graphics.draw(self.image, drawX, drawY, 0, scale, scale)
    end
end

return Tile


local Object = require("utils.classic")

local IsometricGrid = Object:extend()

function IsometricGrid:new(tileWidth, mapWidth, mapHeight)
    self.tileWidth = tileWidth
    self.tileHeight = tileWidth / 2
    self.mapWidth = mapWidth
    self.mapHeight = mapHeight
    self.offsetX = 0
    self.offsetY = 0
    self.zoom = 1.0
end

-- Converts grid (x, y) to isometric screen coords
function IsometricGrid:isoCoords(x, y)
    return (x - y) * self.tileWidth / 2 * self.zoom, (x + y) * self.tileHeight / 2 * self.zoom
end

-- Get map bounds
function IsometricGrid:getMapBounds()
    local topLeftX, topLeftY = self:isoCoords(0, self.mapHeight - 1)
    local bottomRightX, bottomRightY = self:isoCoords(self.mapWidth - 1, 0)
    local width = bottomRightX - topLeftX + self.tileWidth * self.zoom
    local height = bottomRightY - topLeftY + self.tileHeight * self.zoom
    return topLeftX, topLeftY, width, height
end

-- Get offset to center map on screen
function IsometricGrid:getCenterOffset(screenWidth, screenHeight)
    local minX, minY, mapW, mapH = self:getMapBounds()
    local cx = ((screenWidth - mapW) / 2) - minX
    local cy = ((screenHeight - mapH) / 2) - minY
    return cx, cy
end

-- Set offset to center map on screen
function IsometricGrid:centerOnScreen(screenWidth, screenHeight)
    self.offsetX, self.offsetY = self:getCenterOffset(screenWidth, screenHeight)
end

-- Get screen coordinates for a grid position
function IsometricGrid:getScreenCoords(x, y)
    local isoX, isoY = self:isoCoords(x, y)
    return isoX + self.offsetX, isoY + self.offsetY
end

-- Get tile polygon vertices for a grid position
function IsometricGrid:getTileVertices(x, y)
    local isoX, isoY = self:getScreenCoords(x, y)
    local w = self.tileWidth * self.zoom
    local h = self.tileHeight * self.zoom
    return {
        isoX, isoY + h / 2,
        isoX + w / 2, isoY,
        isoX + w, isoY + h / 2,
        isoX + w / 2, isoY + h
    }
end

return IsometricGrid

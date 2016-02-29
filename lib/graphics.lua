local constants = require('game.constants')

local graphics = {
}

local function to_screen(x, y)
  return (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
end

function graphics.cover(color)
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', 0, 0,
      constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)
end

function graphics.draw(x, y, color)
  local sx, sy = to_screen(x, y)
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', sx, sy,
      constants.CELL_WIDTH, constants.CELL_HEIGHT)
end

return graphics
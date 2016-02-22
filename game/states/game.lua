--[[

Copyright (c) 2016 by Marco Lizza (marco.lizza@gmail.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgement in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]]--

-- MODULE INCLUSIONS -----------------------------------------------------------

local constants = require('game.constants')
local Emitter = require('game.emitter')
local Maze = require('game.maze')
local Input = require('lib.input')

-- MODULE DECLARATION ----------------------------------------------------------

local game = {
  maze = nil,
  position = { x = 8, y = 8 },
  input = nil
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function game:initialize()
  self.input = Input.new()
  self.input:initialize({ 'up', 'down', 'left', 'right' }, 0.2)
  
  self.maze = Maze.new()
  self.maze:initialize(constants.MAZE_WIDTH, constants.MAZE_HEIGHT)

  self.maze:spawn_emitter('player', 8, 8, 10, 1)
  self.maze:spawn_emitter('torch_1', 32, 12, 8, 1)
  self.maze:spawn_emitter('torch_2', 32, 32, 5, 1, 10)
  self.maze:spawn_emitter('torch_3', 12, 32, 5, 1, 30)
end

function game:enter()
end

function game:leave()
  self.maze = nil
end

function game:events(dt)
  local keys, has_input = self.input:update(dt)
  if not has_input then
    return
  end
  
  local dx, dy = 0, 0 -- find the delta movement
  if keys['up'] then
    dy = dy - 1
  end
  if keys['down'] then
    dy = dy + 1
  end
  if keys['left'] then
    dx = dx - 1
  end
  if keys['right'] then
    dx = dx + 1
  end

  -- Compute the new position by checking the map walkability. Note that we
  -- don't need to check the boundaries since the map features a non-walkable
  -- border that force the player *inside* the map itself.
  local position = self.position
  local nx, ny = position.x + dx, position.y + dy
  if self.maze:is_walkable(nx, ny) then
    position.x = nx
    position.y = ny
  elseif self.maze:is_walkable(position.x, ny) then
    position.y = ny
  elseif self.maze:is_walkable(nx, position.y) then
    position.x = nx
  end

  local emitter = self.maze:get_emitter('player')
  emitter:set_position(math.floor(position.x), math.floor(position.y))
end

function game:update(dt)
  self:events(dt)

  self.maze:update(dt)

  return nil
end

function game:draw()
  self.maze:scan(function(x, y, visibility, energy)
    local sx, sy = (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
    local color = visibility and 63 or 15
    love.graphics.setColor(color, color, color)
    love.graphics.rectangle('fill', sx, sy,
      constants.CELL_WIDTH, constants.CELL_HEIGHT)
  end)

  self.maze:scan(function(x, y, visibility, energy)
      local sx, sy = (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
      local color = math.floor(255 * energy)
      love.graphics.setColor(255, 255, 255, color)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end)

  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return game

-- END OF FILE -----------------------------------------------------------------

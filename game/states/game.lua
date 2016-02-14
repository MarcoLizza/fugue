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
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local game = {
  maze = nil,
  position = { x = 8, y = 8 }
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function game:initialize()
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

function game:update(dt)
  local keys, has_input = utils.grab_input({ 'up', 'down', 'left', 'right' })

  local position = self.position
  if keys['up'] then
    position.y = position.y - 3 * dt
    if position.y < 1 then
      position.y = 1
    end
  end
  if keys['down'] then
    position.y = position.y + 3 * dt
    if position.y > constants.MAZE_HEIGHT then
      position.y = constants.MAZE_HEIGHT
    end
  end
  if keys['left'] then
    position.x = position.x - 3 * dt
    if position.x < 1 then
      position.x = 1
    end
  end
  if keys['right'] then
    position.x = position.x + 3 * dt
    if position.x > constants.MAZE_WIDTH then
      position.x = constants.MAZE_WIDTH
    end
  end

  local emitter = self.maze:get_emitter('player')
  emitter:set_position(math.floor(position.x), math.floor(position.y))
  self.maze:update(dt)

  return nil
end

function game:draw()
  self.maze:scan(function(x, y, visibility, energy)
      local sx, sy = (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
      local hue = visibility and 255 or 0
      local color = math.floor(hue * energy)
      love.graphics.setColor(color, color, color)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end)
  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return game

-- END OF FILE -----------------------------------------------------------------

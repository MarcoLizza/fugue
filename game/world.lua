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

local config = require('game.config')
local constants = require('game.constants')
local Maze = require('game.maze')
local Foe = require('game.foe')

-- MODULE DECLARATION ----------------------------------------------------------

local world = {
  maze = nil,
  entities = {
    avatar = { position = { x = 2, y = 2 }, visible = true },
    key = { position = { x = 18, y = 22 }, visible = true },
    door = { position = { x = 10, y = 32 }, visible = true }
  },
  foes = {},
  player = {
    name = 'avatar',
    has_key = false
  }
}

-- LOCAL VARIABLES -------------------------------------------------------------

local _tints = {
  ground = { 0x99, 0x88, 0x77, 0 },
  wall = { 0x77, 0x55, 0x22, 0 },
  concrete = { 0x44, 0x33, 0x11, 0 },
  undefined = { 0x3f, 0x3f, 0x3f, 0 }
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function to_screen(x, y)
    return (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function world:initialize()
  self.maze = Maze.new()
  self.maze:initialize(constants.MAZE_WIDTH, constants.MAZE_HEIGHT)

  self.maze:spawn_emitter('avatar', 2, 2, 5, 3)
  self.maze:spawn_emitter('torch_1', 32, 12, 5, 1)
  self.maze:spawn_emitter('torch_2', 32, 32, 3, 1, 10)
  self.maze:spawn_emitter('torch_3', 12, 32, 3, 1, 30)
  
  for i = 1, 4 do
    local foe = Foe.new()
    foe:initialize(self, 22, 22)
    self.foes[#self.foes + 1] = foe
  end
end

function world:events(keys)
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
  local avatar = self.entities['avatar']
  local position = avatar.position
  local _ = self:move(position, dx, dy)

  local emitter = self.maze:get_emitter('avatar')
  emitter:set_position(math.floor(position.x), math.floor(position.y))
end

function world:update(dt)
  -- Update the maze state.
  self.maze:update(dt)

  -- Update and advance the foes.
  for _, foe in pairs(self.foes) do
    foe:update(dt)
  end
end

function world:draw()
  if config.debug.shadows then
    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = to_screen(x, y)
        local tint = _tints[color]
        local alpha = math.min(math.floor(255 * energy), 255)
        tint[4] = alpha
        love.graphics.setColor(tint)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)
  else
    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = to_screen(x, y)
        local tint = cell and 63 or 15
        love.graphics.setColor(tint, tint, tint)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)

    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = to_screen(x, y)
        local alpha = math.min(math.floor(255 * energy), 255)
        love.graphics.setColor(alpha, alpha, alpha, 127)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)
  end

  -- Draw the entities
  for _, entity in pairs(self.entities) do
    if entity.visible then
      local x, y = entity.position.x, entity.position.y
      local energy = self.maze:energy_at(x, y)
      local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
      local sx, sy = to_screen(x, y)
      love.graphics.setColor(127, 255, 127, alpha)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end
  end

  for _, foe in pairs(self.foes) do
    foe:draw()
  end

  love.graphics.setColor(255, 255, 255)
end

function world:generate()
  self.maze:generate()
end

function world:move(point, dx, dy) -- Maze:move_to()
  local moved = true
  local nx, ny = point.x + dx, point.y + dy
  if self.maze:is_walkable(nx, ny) then
    point.x = nx
    point.y = ny
  elseif self.maze:is_walkable(point.x, ny) then
    point.y = ny
  elseif self.maze:is_walkable(nx, point.y) then
    point.x = nx
  else
    moved = false
  end
  return moved
end

-- END OF MODULE -------------------------------------------------------------

return world

-- END OF FILE ---------------------------------------------------------------

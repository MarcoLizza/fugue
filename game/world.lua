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
local Entities = require('game.entities')
local Hud = require('game.hud')
local Maze = require('game.maze')
local graphics = require('lib.graphics')

-- MODULE DECLARATION ----------------------------------------------------------

local world = {
  maze = nil,
  entities = nil,
  hud = nil,
  level = 12
}

-- LOCAL VARIABLES -------------------------------------------------------------

local TINTS = {
  ground = { 0x99, 0x88, 0x77 },
  wall = { 0x77, 0x55, 0x22 },
  concrete = { 0x44, 0x33, 0x11 },
  undefined = { 0x3f, 0x3f, 0x3f }
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function world:initialize()
  self.maze = Maze.new()
  self.maze:initialize(constants.MAZE_WIDTH, constants.MAZE_HEIGHT)

  self.entities = Entities.new()
  self.entities:initialize(self)

  self.hud = Hud.new()
  self.hud:initialize(self)
end

function world:generate()
  self.maze:generate()
  self.entities:generate(self.level)

  local position = self.entities.avatar.position
  self.maze:spawn_emitter('avatar', position.x, position.y, 5, 3)
end

function world:events(keys)
  self.entities:events(keys)

  -- TODO: keep the avatar in synch with the emitters here!
end

function world:update(dt)
  -- Update the maze state. The callback will be invoked when an emitter
  -- disappear.
  self.maze:update(dt, function(id)
      self.entities.flares[id] = nil
    end)

  -- Update the entities.
  self.entities:update(dt)

  self.hud:update(dt)

--  if avatar.duration == 0 or avatar.health == 0 then
--    return 'game-over'
--  elseif avatar.goal then
--    return 'game-win'
--  else
--    return nil
--  end
end

function world:draw()
  if config.debug.shadows then
    self.maze:scan(function(x, y, color, cell, energy)
        local r, g, b = unpack(TINTS[color])
        local alpha = math.min(math.floor(255 * energy), 255)
        graphics.draw(x, y, { r, g, b, alpha })
      end)

    local danger = self.entities:danger_level()
    graphics.cover({ 255, 0, 0, math.floor(danger * 127) })
  else
    self.maze:scan(function(x, y, color, cell, energy)
        local tint = cell and 63 or 15
        graphics.draw(x, y, { tint, tint, tint, 255 })
      end)

    self.maze:scan(function(x, y, color, cell, energy)
        local alpha = math.min(math.floor(255 * energy), 255)
        graphics.draw(x, y, { alpha, alpha, alpha, 127 })
      end)
  end

  self.entities:draw()

  self.hud:draw()

  love.graphics.setColor(255, 255, 255)
end

function world:move(point, dx, dy) -- Maze:move_to()
  local x, y = point.x, point.y
  local nx, ny = x + dx, y + dy
  if self.maze:is_walkable(nx, ny) then
    point.x = nx
    point.y = ny
  elseif self.maze:is_walkable(x, ny) then
    point.y = ny
  elseif self.maze:is_walkable(nx, y) then
    point.x = nx
  end
  return point.x ~= x or point.y ~= y
end

-- END OF MODULE -------------------------------------------------------------

return world

-- END OF FILE ---------------------------------------------------------------

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
}

-- LOCAL CONSTANTS -------------------------------------------------------------

local TINTS = {
  ground = 'peru',
  wall = 'saddlebrown',
  undefined = 'purple'
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

function world:generate(level)
  self.level = level -- FIXME: should use global environment or move HUD to the game instance.
  
  -- According to the current level, set a "dusk" period, that is the length
  -- of a "see everything" dimming twilight. From some level onward the twilight
  -- won't be present at all.
  local dusk_period = math.max(0, 10 - level * 0.5)

  self.maze:generate(dusk_period)
  self.entities:generate(level)

  local position = self.entities.avatar.position
  self.maze:spawn_emitter('avatar', position.x, position.y, 5, 3)
end

function world:input(keys)
  self.entities:input(keys)

  -- The avatar position could have changed, so we keep its emitter's
  -- position synched.
  local position = self.entities.avatar.position
  self.maze:move_emitter('avatar', math.floor(position.x), math.floor(position.y))
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
end

function world:get_state()
  local entities = self.entities
  local avatar = entities.avatar
  local door = entities.door
  local keys = entities.keys

  if door.unlocked then
    return 'goal'
  elseif avatar.duration <= 0 or avatar.health <= 0 then
    return 'game-over'
  else
    return nil
  end
end

function world:draw()
  if config.debug.shadows then
    -- We compare the dusk and energy alpha, and draw the current
    -- tile according to the maximum one.
    self.maze:scan(function(x, y, color, cell, energy)
        local alpha = math.min(math.floor(255 * energy), 255)
        graphics.square(x, y, TINTS[color], alpha)
      end)

    local danger = self.entities:danger_level()
    graphics.fill({ 255, 0, 0 }, math.floor(danger * 127))
  else
    self.maze:scan(function(x, y, color, cell, energy)
        local tint = cell and 63 or 15
        graphics.square(x, y, { tint, tint, tint }, 255)
      end)

    self.maze:scan(function(x, y, color, cell, energy)
        local alpha = math.min(math.floor(255 * energy), 255)
        graphics.square(x, y, { alpha, alpha, alpha }, 127)
      end)
  end

  self.entities:draw()

  self.hud:draw()
end

function world:move(point, dx, dy) -- Maze:move_to()
  local x, y = point.x, point.y
  local nx, ny = x + dx, y + dy
  -- We cannot move diagonally by design.
  if dy ~= 0 and self.maze:is_walkable(x, ny) then
    point.y = ny
  elseif dx ~=  0 and self.maze:is_walkable(nx, y) then
    point.x = nx
  end
  return point.x ~= x or point.y ~= y
end

-- END OF MODULE -------------------------------------------------------------

return world

-- END OF FILE ---------------------------------------------------------------

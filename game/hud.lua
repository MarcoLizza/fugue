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
local collections = require('lib.collections')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local Hud = {
  world = nil,
  font = nil
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Hud.__index = Hud

function Hud.new()
  local self = setmetatable({}, Hud)
  return self
end

-- LOCAL VARIABLES -------------------------------------------------------------

local DIRECTIONS = {
  'e', 'se', 's', 'sw', 'w', 'nw', 'n', 'ne'
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

-- http://stackoverflow.com/questions/1437790/how-to-snap-a-directional-2d-vector-to-a-compass-n-ne-e-se-s-sw-w-nw
local function compass(x, y)
  if x == 0 and y == 0 then
    return '-'
  end
  local angle = math.atan2(y, x)
  local scaled = math.floor(angle / (2 * math.pi / 8))
  local value = (scaled + 8) % 8
  return DIRECTIONS[value + 1]
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Hud:initialize(world)
  self.world = world
  
  local charset = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'
  self.font = love.graphics.newImageFont('assets/fonts/silkscreen_normal_8.png', charset)
end

function Hud:update(dt)
end

function Hud:draw()
  local world = self.world
  local entities = world.entities
  local avatar = entities.avatar

  -- The target is the first visible key (the player could have collected them
  -- in any order), or the door.
  local key = collections.select(entities.keys, function(_, value)
        return value.visible
      end)
  local target = key or entities.door
  
  -- Compute the angle/distance from the current target (key, door, etc)
  -- and display a compass.
  local dx, dy = utils.delta(target.position, avatar.position)
  local compass = compass(dx, dy)

  love.graphics.setFont(self.font)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(string.format('L: %d | D: %d | H: %d | F: %d | A: %s',
      world.level, avatar.duration, avatar.health, avatar.flares, compass),
      0, constants.SCREEN_HEIGHT - 8)
end

-- END OF MODULE ---------------------------------------------------------------

return Hud

-- END OF FILE -----------------------------------------------------------------

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
local array = require('lib.array')
local graphics = require('lib.graphics')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local Foe = {
}

-- LOCAL CONSTANTS -------------------------------------------------------------

local DIRECTIONS = { 'n', 's', 'w', 'e' }

local OPPOSITES = { n = 's', s = 'n', w = 'e', e = 'w' }

local DELTAS = {
  n = { x = 0, y = -1 },
  s = { x = 0, y = 1 },
  w = { x = -1, y = 0 },
  e = { x = 1, y = 0 },
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Foe.__index = Foe

function Foe.new()
  local self = setmetatable({}, Foe)
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Foe:initialize(world, x, y, period)
  self.world = world
  self.position = { x = x, y = y }
  self.time = 0
  self.period = period
  self.state = 'roaming'
  self.memory = 0
  self.persistence = 0
  self.direction = DIRECTIONS[love.math.random(4)]
  self.target = nil -- if nil the foe is roaming
end

function Foe:update(dt)
  -- Keep the foe updating at discrete step (delayed by a period time). If the
  -- foe is currenly seeking for the a target (avatar or flare, this is not
  -- that important) it will updated more frequently.
  -- When the maximum update frequency is reached, the foe will noticeably move
  -- faster than the avatar.
  self.time = self.time + dt
  local period = self.period
  if self.state == 'seeking' then
    period = period * 0.90
  end
  if self.time < period then
    return
  end
  self.time = 0

  local world = self.world
  local maze = world.maze
  local entities = world.entities
  local avatar = entities.avatar

  -- Scan the flares, checking for the nearest visible one. If found, mark the
  -- identifier, we will use it to drive the foe toward it.
  local bait = nil
  local distance_so_far = math.huge
  for k, flare in pairs(entities.flares) do
    local flare_distance = utils.distance(self.position, flare.position)
    if flare_distance < 7 and maze:is_visible(self.position, flare.position) then
      if distance_so_far > flare_distance then
        distance_so_far = flare_distance
        bait = k -- the foes is following a bait
      end
    end
  end

  -- If the avatar is spotted, record it's view position.
  if bait then
    local flare = entities.flares[bait]
    self.target = { x = flare.position.x, y = flare.position.y }
    self.state = 'seeking'
    self.memory = 10
  elseif utils.distance(self.position, avatar.position) < 5 and maze:is_visible(self.position, avatar.position) then
    self.target = { x = avatar.position.x, y = avatar.position.y }
    self.state = 'seeking'
    self.memory = 10
  else
    if self.memory <= 0 then
      self.target = nil -- will resume moving with the direction in use when the avatar was spotted
      self.state = 'roaming'
    else
      self.memory = self.memory - 1
    end
  end

  -- If the avatar sightning position is reached, switch to roaming.
  if self.state == 'seeking' then
    local dx, dy = utils.delta(self.target, self.position) -- TODO: pathfinding
    local _ = world:move(self.position, utils.sign(dx), utils.sign(dy))
    if self.position.x == self.target.x and self.position.y == self.target.y then
--      self.target = nil
--      self.state = 'roaming'
      self.memory = 0
    end
    return
  end

  -- The AI will keep on moving toward the current direction until a wall
  -- is reached *or* too many steps have been done.
  local delta = DELTAS[self.direction]
  local moved = world:move(self.position, delta.x, delta.y)
  if moved then
    self.persistence = self.persistence - 1
  end
  if not moved or self.persistence <= 0 then
    local directions = array.shuffle(DIRECTIONS)
    for _, direction in ipairs(directions) do
      if direction ~= OPPOSITES[self.direction] then -- discard the coming direction
        local delta = DELTAS[direction]
        moved = world:move(self.position, delta.x, delta.y)
        if moved then
          self.direction = direction
          self.persistence = 10
          break
        end
      end
    end
  end
end

function Foe:draw()
  local x, y = self.position.x, self.position.y
  local energy = self.world.maze:energy_at(x, y)
  local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
  graphics.square(x, y, 'red', alpha)
  if config.debug.details then
    love.graphics.setColor(127, 127, 255, alpha)
--    love.graphics.print(string.format("%s %.5f", self.direction, self.memory), sx, sy - 8)
    if self.target then
      graphics.square(self.target.x, self.target.y, 'orange', alpha)
    end
  end
end

-- END OF MODULE -------------------------------------------------------------

return Foe

-- END OF FILE ---------------------------------------------------------------

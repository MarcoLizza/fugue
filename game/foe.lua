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

-- MODULE DECLARATION ----------------------------------------------------------

local Foe = {
  world = nil,
  position = nil,
  time = nil,
  dampening = nil,
  state = nil,
  memory = nil,
  direction = nil
}

-- LOCAL VARIABLES -------------------------------------------------------------

local _directions = { 'n', 's', 'w', 'e' }
local _opposites = { n = 's', s = 'n', w = 'e', e = 'w' }
local _deltas = {
  n = { x = 0, y = -1 },
  s = { x = 0, y = 1 },
  w = { x = -1, y = 0 },
  e = { x = 1, y = 0 },
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function sign(delta) -- TODO: move to "utils"
  if delta < 0 then
    return -1
  elseif delta > 0 then
    return 1
  else
    return 0
  end
end

local function delta(a, b, c, d) -- points
  local dx, dy
  if type(a) == 'table' and type(b) == 'table' then
    dx, dy = a.x - b.x, a.y - b.y
  else
    dx, dy = a - c, b - d
  end
  return dx, dy
end

local function distance(a, b, c, d) -- points
  local dx, dy = delta(a, b, c, d)
  return math.sqrt(dx * dx + dy * dy)
end

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Foe.__index = Foe

function Foe.new()
  local self = setmetatable({}, Foe)
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Foe:initialize(world, x, y)
  self.world = world
  self.position = { x = x, y = y }
  self.time = 0
  self.dampening = 0.5
  self.state = 'roaming'
  self.memory = 0
  self.direction = _directions[love.math.random(4)]
  self.target = nil -- if nil the foe is roaming
end

function Foe:update(dt)
  self.time = self.time + dt -- DAMPENER
  if self.time < self.dampening then
    return
  end
  self.time = 0

  local world = self.world
  local avatar = world.avatar

  -- Scan the flares, checking for the nearest visible one. If found, mark the
  -- identifier, we will use it to drive the foe toward it.
  local bait = nil
  local distance_so_far = math.huge
  for k, flare in pairs(world.flares) do
    local flare_distance = distance(self.position, flare.position)
    if flare_distance < 7 and world:is_visible(self.position, flare.position) then
      if distance_so_far > flare_distance then
        distance_so_far = flare_distance
        bait = k -- the foes is following a bait
      end
    end
  end

  -- If the avatar is spotted, record it's view position.
  if bait then
    local flare = world.flares[bait]
    self.target = { x = flare.position.x, y = flare.position.y }
    self.state = 'seeking'
    self.memory = 10
    self.dampening = 0.5
  elseif distance(self.position, avatar.position) < 5 and world:is_visible(self.position, avatar.position) then
    self.target = { x = avatar.position.x, y = avatar.position.y }
    self.state = 'seeking'
    self.memory = 10
    self.dampening = 0.5
  else
    if self.memory <= 0 then
      self.target = nil -- will resume moving with the direction in use when the avatar was spotted
      self.state = 'roaming'
      self.dampening = 0.5
    else
      self.memory = self.memory - 1
    end
  end

  -- If the avatar sightning position is reached, switch to roaming.
  if self.state == 'seeking' then
    local dx, dy = delta(self.target, self.position) -- TODO: pathfinding
    local _ = world:move(self.position, sign(dx), sign(dy))
    if self.position.x == self.target.x and self.position.y == self.target.y then
--      self.target = nil
--      self.state = 'roaming'
      self.memory = 0
    end
    return
  end
  
  -- roaming
  local delta = _deltas[self.direction]
  local moved = world:move(self.position, delta.x, delta.y)
  if not moved then
    local directions = array.shuffle(_directions)
    for _, direction in ipairs(directions) do
      if direction ~= _opposites[self.direction] then -- discard the coming direction
        local delta = _deltas[direction]
        moved = world:move(self.position, delta.x, delta.y)
        if moved then
          self.direction = direction
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
  local sx, sy = self.world:to_screen(x, y)
  love.graphics.setColor(255, 127, 127, alpha)
  love.graphics.rectangle('fill', sx, sy,
    constants.CELL_WIDTH, constants.CELL_HEIGHT)
  if config.debug.details then
    love.graphics.setColor(127, 127, 255, alpha)
    love.graphics.print(string.format("%s %.5f", self.direction, self.memory), sx, sy - 8)
    if self.target then
      sx, sy = to_screen(self.target.x, self.target.y)
      love.graphics.setColor(255, 127, 255, alpha)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end
  end
end

-- END OF MODULE -------------------------------------------------------------

return Foe

-- END OF FILE ---------------------------------------------------------------

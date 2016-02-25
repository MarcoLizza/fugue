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

-- MODULE DECLARATION ----------------------------------------------------------

local Foe = {
  world = nil,
  position = nil,
  time = nil,
  state = nil,
  memory = nil
}

-- LOCAL VARIABLES -------------------------------------------------------------

local _delta = { -1, 0, 1 }

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function to_screen(x, y)
    return (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
end

local function sign(delta) -- TODO: move to "utils"
  if delta < 0 then
    return -1
  elseif delta > 0 then
    return 1
  else
    return 0
  end
end

local function delta(a, b, c, d)
  local dx, dy
  if type(a) == 'table' and type(b) == 'table' then
    dx, dy = a.x - b.x, a.y - b.y
  else
    dx, dy = a - c, b - d
  end
  return dx, dy
end

local function distance(a, b, c, d)
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
  self.state = 'roaming'
  self.memory = 0
end

function Foe:update(dt)
  local world = self.world
  local avatar = world.entities['avatar']

  self.time = self.time + dt -- DAMPENER
  if self.time < 0.5 then
    return
  end
  self.time = 0

  if distance(self.position, avatar.position) < 5 and
      self.maze:is_visible(self.position, avatar.position) then
    self.state = 'seeking'
    self.memory = 10
  else
    if self.memory <= 0 then
      self.state = 'roaming'
    else
      self.memory = self.memory - (1 * dt)
    end
  end

  if self.state == 'seeking' then
    local dx, dy = delta(avatar.position, self.position)
    local _ = world:move(self.position, sign(dx), sign(dy))
    return
  end
  
  -- roaming
  repeat
    local dx, dy = _delta[love.math.random(3)], _delta[love.math.random(3)]
    local moved = world:move(self.position, dx, dy)
  until moved
end

function Foe:draw()
  local x, y = self.position.x, self.position.y
  local energy = self.world.maze:energy_at(x, y)
  local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
  local sx, sy = to_screen(x, y)
  love.graphics.setColor(255, 127, 127, alpha)
  love.graphics.rectangle('fill', sx, sy,
    constants.CELL_WIDTH, constants.CELL_HEIGHT)
end

-- END OF MODULE -------------------------------------------------------------

return Foe

-- END OF FILE ---------------------------------------------------------------

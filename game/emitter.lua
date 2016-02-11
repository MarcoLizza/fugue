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

-- MODULE DECLARATION ----------------------------------------------------------

local Emitter = {
  _VERSION = '0.1.0',
  -- PARAMETERS --
  x = nil,
  y = nil,
  radius = nil,
  energy = nil,
  duration = nil,
  -- VALUES --
  life = nil,
  alpha = nil
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Emitter.__index = Emitter

function Emitter.new(params)
  local self = setmetatable({}, Maze)
  for k, v in pairs(params) do
  	self[k] = v
  end
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Emitter:initialize(x, y, radius, energy, duration)
  self.x = x
  self.y = y
  self.radius = radius
  self.energy = energy
  self.duration = duration -- can be "nil" for everlasting emitters
  self.life = 0
  self.alpha = 1.0
end

function Emitter:energy_at(x, y)
  local dx = x - self.x
  local dy = y - self.y
  local distance = math.sqrt(dx * dx + dy * dy) -- FIXME: could use squared value
  if distance > self.radius then
    return 0
  else
    return (distance / self.radius) * self.energy * self.alpha -- FIXME: the latter can be precalculated
  end
end

function Emitter:update(dt)
  if self:is_alive() then
    self.life = self.life + dt
    if self.life > self.duration then -- bound check
      self.life = self.duration
    end
    self.alpha = self.life / self.duration
  end
end

function Emitter:is_alive()
  -- If the [duration] property is null then the emitter is everlasting.
  return self.duration and self.life < self.duration or true
end

function Emitter:get_position()
  return self.x, self.y
end

function Emitter:set_position(x, y)
  self.x = x
  self.y = y
end

-- END OF MODULE ---------------------------------------------------------------

return Emitter

-- END OF FILE -----------------------------------------------------------------

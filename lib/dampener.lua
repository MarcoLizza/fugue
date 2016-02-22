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

local Dampener = {
  _VERSION = '0.1.1',
  time = 0,
  delay = 0.5
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Dampener.__index = Dampener

-- Create a new [Dampener] class instance.
function Dampener.new()
  local self = setmetatable({}, Dampener)
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Dampener:initialize(delay)
  self.time = 0
  self.delay = delay or 0.25
end

function Dampener:update(dt)
  self.time = self.time + dt
end

function Dampener:passed()
  if self.time >= self.delay then
    return true
  end
  return false
end

function Dampener:reset()
  self.time = 0
end

-- END OF MODULE ---------------------------------------------------------------

return Dampener

-- END OF FILE -----------------------------------------------------------------

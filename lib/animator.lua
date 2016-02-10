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

local Animator = {
  _VERSION = '0.1.0',
  animations = {},
  period = 1 / 50,
  animation = nil,
  elapsed = 0,
  frame = nil,
  running = nil
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Animator.__index = Animator

function Animator.new()
  local self = setmetatable({}, Animator)
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Animator:initialize(animations, frequency)
  self.animations = animations
  self.period = 1 / (frequency or 50)
end

function Animator:update(dt)
  if not self.animation or not self.running then
    return
  end
  
  self.elapsed = self.elapsed + dt
  while self.elapsed > self.period do
    self.frame = (self.frame % #self.animation) + 1 -- move to next, damned 1-indices!
    self.elapsed = self.elapsed - self.period
  end
end

function Animator:switch_to(index, reset)
  if reset or true then
    self.elapsed = 0
    self.frame = nil
    self.running = true
  end

  if self.animations[index] then
    self.animation = self.animations[index]
    self.frame = 1
  end
end

function Animator:pause()
  self.running = false
end

function Animator:resume()
  self.running = true
end

function Animator:seek(frame)
  if frame >= 1 and frame <= #self.animation then
    self.frame = frame
  end
end

function Animator:get_frame()
  return self.animation[self.frame]
end

-- END OF MODULE ---------------------------------------------------------------

return Animator

-- END OF FILE -----------------------------------------------------------------

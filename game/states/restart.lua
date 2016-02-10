--[[

Copyright (c) 2016 by Marco Lizza (marco.lizza@gmail.com)

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
2
1. The origin of this software must not be misrepresented; you must not
   claim that you wrote the original software. If you use this software
   in a product, an acknowledgement in the product documentation would be
   appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
   misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

]]--

-- MODULE INCLUSIONS -----------------------------------------------------------

utils = require('lib.utils')
Dampener = require('lib.dampener')

-- MODULE DECLARATION ----------------------------------------------------------

local gameover = {
  dampener = Dampener.new(),
  image = nil,
  current = nil,
  delay = 3,
  progress = nil
}

-- MODULE CONSTANTS ------------------------------------------------------------

local COLORS = {
  { 255,   0,   0 },
  { 255, 255,   0 },
  {   0, 255,   0 },
  {   0, 255, 255 },
  {   0,   0, 255 },
  { 255,   0, 255 }
}

local KEYS = {
  'x'
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function gameover:initialize()
  self.dampener:initialize(0.5)
  
  self.image = love.graphics.newImage('assets/gameover.png')
end

function gameover:enter()
  self.dampener:reset()

  self.current = 1
  self.progress = 0
end

function gameover:leave()
end

function gameover:update(dt)
  self.dampener:update(dt)
  local passed = self.dampener:passed()
  if not passed then
    return
  end

  self.progress = self.progress + dt
  
  if self.progress >= self.delay then
    self.current = (self.current % #COLORS) + 1
    self.progress = 0
  end

  local keys, has_input = utils.grab_input(KEYS)

  return keys['x'] and 'splash' or nil
end

function gameover:draw()
  local alpha = self.progress / self.delay

  local next = (self.current % #COLORS) + 1

  local color = utils.lerp(COLORS[self.current], COLORS[next], alpha)

  love.graphics.setColor(color) -- colorize the image
  love.graphics.draw(self.image, 0, 0)

  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return gameover

-- END OF FILE -----------------------------------------------------------------

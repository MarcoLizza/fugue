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

local constants = require('game.constants')

local graphics = require('lib.graphics')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local gameover = {
  delay = 3,
}

-- LOCAL CONSTANTS -------------------------------------------------------------

local COLORS = {
  { 127,   0,   0 },
  { 127, 127,   0 },
  {   0, 127,   0 },
  {   0, 127, 127 },
  {   0,   0, 127 },
  { 127,   0, 127 }
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function gameover:initialize(environment)
  self.environment = environment
end

function gameover:enter()
  self.index = 1
  self.progress = 0
  self.continue = false
end

function gameover:leave()
end

function gameover:input(keys)
  if keys.pressed['x'] then
    self.continue = true
  end
end

function gameover:update(dt)
  self.progress = self.progress + dt
  
  if self.progress >= self.delay then
    self.index = utils.forward(self.index, COLORS)
    self.progress = 0
  end

  return self.continue and 'menu' or nil
end

function gameover:draw()
  local alpha = self.progress / self.delay

  local next = utils.forward(self.index, COLORS)

  local color = utils.lerp(COLORS[self.index], COLORS[next], alpha)
  graphics.fill(color)
  graphics.text('GAME OVER',
    constants.SCREEN_RECT, 'retro-computer', utils.scale(color, 0.80), 'center', 'middle', 2)
  graphics.text(string.format('YOU REACHED NIGHT #%d', self.environment.level),
    { 0, constants.SCREEN_HEIGHT * 2 / 3, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT },
    'silkscreen', { 255, 255, 255, 127 }, 'center', 'top', 2)
  graphics.text('PRESS X TO RESTART',
    constants.SCREEN_RECT, 'silkscreen', { 255, 255, 255, 191 }, 'center', 'bottom')

  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return gameover

-- END OF FILE -----------------------------------------------------------------

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

local Dampener = require('lib.dampener')
local graphics = require('lib.graphics')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local gameover = {
  dampener = Dampener.new(),
  image = nil,
  image_index = nil,
  text_index = nil,
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

function gameover:initialize(environment)
  self.dampener:initialize(0.5)
  
  self.image = love.graphics.newImage('assets/gameover.png')
end

function gameover:enter()
  self.dampener:reset()

  self.image_index = 1
  self.text_index = #COLORS
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
    self.image_index = utils.forward(self.image_index, COLORS)
    self.text_index = utils.backward(self.text_index, COLORS)
    self.progress = 0
  end

  local keys, has_input = utils.grab_input(KEYS)

  return keys['x'] and 'menu' or nil
end

function gameover:draw()
  local alpha = self.progress / self.delay

  local image_next = utils.forward(self.image_index, COLORS)
  local text_next = utils.backward(self.text_index, COLORS)
  
  local image_color = utils.lerp(COLORS[self.image_index], COLORS[image_next], alpha)
  love.graphics.setColor(image_color) -- colorize the image
  love.graphics.draw(self.image, 0, 0)

  local text_color = utils.lerp(COLORS[self.text_index], COLORS[text_next], alpha)
  graphics.text('PRESS X TO RESTART',
    constants.SCREEN_RECT, 'retro-computer', text_color) -- colorize the text
end

-- END OF MODULE ---------------------------------------------------------------

return gameover

-- END OF FILE -----------------------------------------------------------------

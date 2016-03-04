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

local Dampener = require('lib.dampener')
local graphics = require('lib.graphics')

-- MODULE DECLARATION ----------------------------------------------------------

local menu = {
  states = {
    {
      mode = 'cross-in',
      delay = 3,
      init = function(self, context)
          self.progress = 0
        end,
      update = function(self, context, dt)
          self.progress = self.progress + dt
        end,
      condition = function(self, context)
          return self.progress >= self.delay
        end,
      alpha = function(self)
          return math.min(self.progress / self.delay, 1.0)
        end,
      draw = function(self, context) 
          graphics.cover('dimgray')
          graphics.text('FUGUE',
            constants.SCREEN_RECT, 'retro-computer', 'gray', 'center', 'middle', 3)
        end,
      deinit = function(self, context)
          self.image = nil
        end
    },
    {
      init = function(self, context)
        end,
      update = function(self, context, dt)
        end,
      condition = function(self, context)
          return context.begin
        end,
      alpha = nil,
      draw = function(self, context) 
          graphics.cover('dimgray')
          graphics.text('FUGUE',
            constants.SCREEN_RECT, 'retro-computer', 'gray', 'center', 'middle', 3)
          graphics.text('PRESS X TO START',
            constants.SCREEN_RECT, 'retro-computer', 'white', 'center', 'bottom')
        end,
      deinit = function(self, context)
          self.image = nil
        end
    },
    {
      mode = 'fade-out',
      delay = 5,
      init = function(self, context)
          self.progress = 0
        end,
      update = function(self, context, dt)
          self.progress = self.progress + dt
        end,
      condition = function(self, context)
          return self.progress >= self.delay
        end,
      alpha = function(self)
          return math.min(self.progress / self.delay, 1.0)
        end,
      draw = function(self, context) 
          graphics.cover('dimgray')
          graphics.text('FUGUE',
            constants.SCREEN_RECT, 'retro-computer', 'gray', 'center', 'middle', 3)
        end,
      deinit = function(self, context)
          self.image = nil
        end
    },
  }
}

-- LOCAL CONSTANTS -------------------------------------------------------------

local KEYS = {
  'x'
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

-- Very simple easing (quadratic) function.
local function ease(value)
  return math.pow(value, 2.0)
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function menu:initialize()
  self.dampener = Dampener.new()
  self.dampener:initialize(0.5)
end

function menu:enter()
  self.dampener:reset()
  
  self.index = nil
  self.begin = false
end

function menu:leave()
end

function menu:update(dt)
  self.dampener:update(dt)
  local passed = self.dampener:passed()
  if passed then
    local keys, has_input = utils.grab_input(KEYS)
    if keys('x') then
      self.begin = true
    end
  end
  
  -- Determine if we should move to the next state. This happens if the index is
  -- not defined, or a programmable condition has triggere, or if (after advancing
  -- the progress counter) the timeout has elapsed.
  local change = false
  
  if not self.index then
    self.index = 0
    change = true
  else
    self.state:update(self, dt)
    change = self.state:condition(self)
  end

  if change then
    -- Advance to the next state. When the end of the sequence is reached, we
    -- need to switch to the game state.
    self.index = self.index + 1
    if self.index > #self.states then
      return 'game'
    end

    -- Get the next state. If an image is defined, pre-load it. Then, we
    -- store the new state delay and reset the progress variable.
    if self.state then
      self.state:deinit(self)
    end
    self.state = self.states[self.index]
    self.state:init(self)
  end

  return nil
end

function menu:draw()
  -- If the state index has not been updated yet, skip and wait next
  -- iteration.
  if not self.index then
    return
  end
  
  local state = self.state
  
  -- Draw the state.
  state:draw()

  if not state.alpha or not state.mode then
    return
  end

  -- Calculate the current fading progress ratio.
  local alpha = state:alpha()

  -- According to the current mode, compute the fading color.
  local color = nil
  if state.mode == 'fade-in' then -- from black
    local factor = ease(1.0 - alpha)
    color = { 0, 0, 0, factor * 255 }
  elseif state.mode == 'fade-out' then -- to black
    local factor = ease(alpha)
    color = { 0, 0, 0, factor * 255 }
  elseif state.mode == 'cross-in' then -- from white
    local factor = ease(1.0 - alpha)
    color = { 255, 255, 255, factor * 255 }
  elseif state.mode == 'cross-out' then -- to white
    local factor = ease(alpha)
    color = { 255, 255, 255, factor * 255 }
  end

  -- If the overlay "fading" color is defined, draw a full size filled
  -- rectangle over the current display.
  if color then
    graphics.cover(color)
  end
  
  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return menu

-- END OF FILE -----------------------------------------------------------------

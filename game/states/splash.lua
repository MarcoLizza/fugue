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

local splash = {
  states = {
    { mode = 'fade-in', delay = 1, file = 'assets/splash-0.png' },
    { mode = 'display', delay = 5, file = 'assets/splash-0.png' },
    { mode = 'cross-out', delay = 0.25, file = 'assets/splash-0.png' },
    { mode = 'cross-in', delay = 0.25, file = 'assets/splash-1.png' },
    { mode = 'display', delay = 5, file = 'assets/splash-1.png' },
    { mode = 'cross-out', delay = 0.25, file = 'assets/splash-1.png' },
    { mode = 'cross-in', delay = 0.25, file = 'assets/splash-2.png' },
    { mode = 'display', delay = 5, file = 'assets/splash-2.png' },
    { mode = 'fade-out', delay = 2, file = 'assets/splash-2.png' },
  },
  index = nil,
  image = nil,
  delay = 0,
  progress = 0
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

-- Very simple easing (quadratic) function.
local function ease(value)
  return math.pow(value, 2.0)
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function splash:initialize()
end

function splash:enter()
  self.index = nil
end

function splash:leave()
  -- Release the image resource upon state leaving.
  self.image = nil
end

function splash:update(dt)
  -- Determine if we should move to the next state. This happens if the index is
  -- not defined or if (after advancing the progress counter) the timeout has
  -- elapsed.
  local change = false
  
  if not self.index then
    self.index = 0
    change = true
  elseif self.progress < self.delay then
    self.progress = self.progress + dt
    if self.progress >= self.delay then
      change = true
    end
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
    local state = self.states[self.index]
    if state.file then
      self.image = love.graphics.newImage(state.file)
    else
      self.image = nil
    end
    self.delay = state.delay
    self.progress = 0
  end

  return nil
end

function splash:draw()
  -- If the state index has not been updated yet, skip and wait next
  -- iteration.
  if not self.index then
    return
  end
  
  -- If defined, draw the background image.
  if self.image then
    love.graphics.draw(self.image, 0, 0)
  end

  -- Calculate the current fading progress ratio.
  local alpha = self.progress / self.delay

  -- According to the current mode, compute the fading color.
  local color = nil
  local state = self.states[self.index]
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
    love.graphics.setColor(color)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(255, 255, 255)
  end
end

-- END OF MODULE ---------------------------------------------------------------

return splash

-- END OF FILE -----------------------------------------------------------------

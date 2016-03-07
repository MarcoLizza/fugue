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
local graphics = require('lib.graphics')

-- MODULE DECLARATION ----------------------------------------------------------

local game = {
  world = require('game.world'),
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function game:initialize(environment)
  self.environment = environment

  self.world:initialize()
end

function game:enter()
  -- Reset to the first ("prologue") level.
  self:reset(0)
end

function game:reset(level)
  -- Update the global variable to track game progress.
  self.environment.level = level

  -- Regenerate the world, according to the new level.
  self.world:generate(level)

  -- Reset the presentation variables, to display the level information.
  self.progress = 0
  self.running = false
end

function game:leave()
end

function game:input(keys)
  self.world:input(keys)
end

function game:update(dt)
  if not self.running then
    self.progress = self.progress + dt
    self.running = self.progress >= 3
    return
  end
  
  -- Update the world, then get the current world state used to drive the
  -- engine state-machine.
  self.world:update(dt)
  
  local state = self.world:get_state()
  if state then
    if state == 'goal' then
      self:reset(self.environment.level + 1)
    elseif state == 'game-over' then
      return 'restart'
    end
  end

  return nil
end

function game:draw()
  if self.running then
    self.world:draw()
  else
    graphics.cover('black')
    graphics.text(string.format('DAY #%d', self.environment.level),
      constants.SCREEN_RECT, 'retro-computer', 'white', 'center', 'middle', 2)
  end

  love.graphics.setColor(255, 255, 255)
end

-- END OF MODULE ---------------------------------------------------------------

return game

-- END OF FILE -----------------------------------------------------------------

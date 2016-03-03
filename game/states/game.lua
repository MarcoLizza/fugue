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
local Input = require('lib.input')

-- MODULE DECLARATION ----------------------------------------------------------

local game = {
  environment = nil,
  input = nil,
  world = require('game.world'),
  --
  progress = nil,
  running = nil
}

-- MODULE FUNCTIONS ------------------------------------------------------------

function game:initialize(environment)
  self.environment = environment

  self.input = Input.new()
  self.input:initialize({ up = 'move_up', down = 'move_down', left = 'move_left', right = 'move_right', x = 'action' },
    { move_up = 0.2, move_down = 0.2, move_left = 0.2, move_right = 0.2, action = math.huge })

  self.world:initialize()
end

function game:enter()
  self.progress = 0
  self.running = false
  self.environment.level = 0
  self.world:generate(self.environment.level)
end

function game:leave()
end

function game:events(dt)
  local keys = self.input:update(dt)
  if keys.amount == 0 then
    return
  end

  self.world:events(keys)
end

function game:update(dt)
  if not self.running then
    self.progress = self.progress + dt
    self.running = self.progress >= 3
    return
  end
  
  -- Handle the events, that is mostly the inputs.
  self:events(dt)

  -- Update the world, then get the current world state used to drive the
  -- engine state-machine.
  self.world:update(dt)
  local state = self.world:get_state()
  
  if state then
    if state == 'goal' then
      self.environment.level = self.environment.level + 1
    elseif state == 'game-over' then
      return 'restart'
    end
    self.progress = 0
    self.running = false
    self.world:generate(self.environment.level)
  end

  return nil
end

function game:draw()
  if self.running then
    self.world:draw()
  else
    graphics.cover({ 0, 0, 0 })
    graphics.text(string.format('DAY #%d', self.environment.level),
      constants.SCREEN_RECT, 'retro_computer', { 255, 255, 255 })
  end
end

-- END OF MODULE ---------------------------------------------------------------

return game

-- END OF FILE -----------------------------------------------------------------

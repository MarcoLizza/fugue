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

local config = require('game.config')
local Input = require('lib.input')
local Stateful = require('lib.stateful')

-- LOCAL VARIABLES -------------------------------------------------------------

local _stateful = nil
local _time = 0
local _input = nil

-- ENGINE CALLBACKS ------------------------------------------------------------

function love.load(args)
  if args[#args] == '-debug' then require('mobdebug').start() end

  -- We stay true to a real "pixelized" feel.
  love.graphics.setDefaultFilter('nearest', 'nearest', 1)

  -- Initializes the input handler.
  _input = Input.new()
  _input:initialize({ up = 'move_vertical', down = 'move_vertical', left = 'move_horizontal', right = 'move_horizontal', x = 'action' },
    { move_horizontal = 0.2, move_vertical = 0.2, action = math.huge })

  -- Initializes the state-engine.
  _stateful = Stateful.new()
  _stateful:initialize({
    splash = require('game.states.splash'),
    menu = require('game.states.menu'),
    game = require('game.states.game'),
    restart = require('game.states.restart')
  }, { level = 0 })
  _stateful:switch_to('splash')
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'f9' then
    config.debug.fps = not config.debug.fps
  elseif key == 'f10' then
    config.debug.details = not config.debug.details
  elseif key == 'f11' then
    config.debug.shadows = not config.debug.shadows
    config.debug.cheat = not config.debug.cheat
  elseif key == 'f12' then
    local screenshot = love.graphics.newScreenshot()
    screenshot:encode('png', os.time() .. '.png')
  end
end

function love.update(dt)
  -- Update the input handler and, if some keys are pressed,
  -- propagate to the state manager.
  local keys = self.input:update(dt)
  if keys.amount > 0 then
    _stateful:input(keys)
  end
  
  -- Update the state manager.
  local start = love.timer.getTime()
  _stateful:update(dt)
  _time = love.timer.getTime() - start
end

function love.draw()
  love.graphics.push()
  love.graphics.scale(config.display.scale)

  _stateful:draw()

  love.graphics.pop()

  if config.debug.fps then
    love.graphics.print(love.timer.getFPS() .. '|' .. _time, 0, 0)
  end
end

-- END OF FILE -----------------------------------------------------------------

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

-- ENGINE CALLBACKS ------------------------------------------------------------

function love.conf(configuration)
  configuration.identity = constants.IDENTITY
  configuration.version = '0.10.0'
  configuration.console = false

  configuration.window.title = constants.WINDOW_TITLE
  configuration.window.width = constants.WINDOW_WIDTH
  configuration.window.height = constants.WINDOW_HEIGHT

  configuration.window.display = 2

  configuration.modules.audio = true     -- Enable the audio module (boolean)
  configuration.modules.event = true     -- Enable the event module (boolean)
  configuration.modules.graphics = true  -- Enable the graphics module (boolean)
  configuration.modules.image = true     -- Enable the image module (boolean)
  configuration.modules.joystick = false -- Enable the joystick module (boolean)
  configuration.modules.keyboard = true  -- Enable the keyboard module (boolean)
  configuration.modules.math = true      -- Enable the math module (boolean)
  configuration.modules.mouse = false    -- Enable the mouse module (boolean)
  configuration.modules.physics = false  -- Enable the physics module (boolean)
  configuration.modules.sound = true     -- Enable the sound module (boolean)
  configuration.modules.system = true    -- Enable the system module (boolean)
  configuration.modules.timer = true     -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
  configuration.modules.touch = false    -- Enable the touch module (boolean)
  configuration.modules.video = false    -- Enable the video module (boolean)
  configuration.modules.window = true    -- Enable the window module (boolean)
  configuration.modules.thread = true
end

-- END OF FILE -----------------------------------------------------------------

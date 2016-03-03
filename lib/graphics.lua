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

-- MODULE DECLARATION ----------------------------------------------------------

local graphics = {
}

-- LOCAL VARIABLES -------------------------------------------------------------

local CHARSET = ' !"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'

-- MODULE VARIABLES ------------------------------------------------------------

-- Preload some fonts. We are using the proper (pedantic) syntax to access the
-- map items in this case, to be safe.
graphics.fonts = {
  ['retro-computer'] = love.graphics.newImageFont('assets/fonts/retro_computer_regular_14.png', CHARSET),
  ['silkscreen'] = love.graphics.newImageFont('assets/fonts/silkscreen_normal_8.png', CHARSET)
}

-- MODULE FUNCTIONS ------------------------------------------------------------

local function to_screen(x, y)
  return (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
end

function graphics.cover(color)
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', 0, 0,
      constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)
end

function graphics.draw(x, y, color)
  local sx, sy = to_screen(x, y)
  love.graphics.setColor(color)
  love.graphics.rectangle('fill', sx, sy,
      constants.CELL_WIDTH, constants.CELL_HEIGHT)
end

function graphics.text(text, rectangle, face, color)
  local font = graphics.fonts[face]
  local x, y = rectangle[1], rectangle[2]
  if rectangle[3] and rectangle[4] then
    local width = rectangle[3] - rectangle[1]
    local height = rectangle[4] - rectangle[2]
    local text_width = font:getWidth(text)
    local text_height = font:getHeight()
    x = (width - text_width) / 2
    y = (height - text_height) / 2
  end
  love.graphics.setFont(font)
  love.graphics.setColor(color)
  love.graphics.print(text, x, y)
end

-- END OF MODULE ---------------------------------------------------------------

return graphics

-- END OF FILE------------------------------------------------------------------

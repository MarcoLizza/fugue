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

local Dampener = require('lib.dampener')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local Input = {
  _VERSION = '0.1.0',
  keys = nil,
  dampener = nil
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Input.__index = Input

function Input.new()
  local self = setmetatable({}, Input)
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Input:initialize(keys, delay)
  self.keys = keys

  self.dampener = Dampener.new()
  self.dampener:initialize(delay)
end

function Input:update(dt)
  -- Grab the current input state. While no input is provided, keep the dampener
  -- clear. During input, update the dampener and process input from time to
  -- time.
  local keys, has_input = utils.grab_input(self.keys)
    if not has_input then
    self.dampener:reset()
    return nil, false
  end
  self.dampener:update(dt)
  if not self.dampener:passed() then
    return nil, false
  end
  self.dampener:reset()
  return keys, true
end

-- END OF MODULE ---------------------------------------------------------------

return Input

-- END OF FILE -----------------------------------------------------------------

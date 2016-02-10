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

-- module tweener.lua
local tweener = {
  _VERSION = '0.1.0'
}

-- MODULE FUNCTIONS ------------------------------------------------------------

-- Creates a tweening linear functor that interpolates between the values [from]
-- and [to] in [time] seconds. Internally accumulates the current time upon each
-- subsequent call. Returns both the interpolated value and a boolean telling
-- wether the tweening has ended.
function tweener.linear(time, callback)
  local current = 0
  return function(dt)
    current = current + dt
    if current > time then
      current = time
    end
    local ratio = current / time
    return callback(ratio), current < time
  end
end

-- END OF MODULE ---------------------------------------------------------------

return tweener

-- END OF FILE -----------------------------------------------------------------

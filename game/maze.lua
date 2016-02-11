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

local Emitter = require('emitter')

-- MODULE DECLARATION ----------------------------------------------------------

local Maze = {
  _VERSION = '0.1.0',
  -- PROPERTIES --
  emitters = {}
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Maze.__index = Maze

function Maze.new(params)
  local self = setmetatable({}, Maze)
  for k, v in pairs(params) do
  	self[k] = v
  end
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Maze:initialize(width, height)
end

function Maze:spawn_emitter(id, x, y, radius, energy, duration)
  local emitter = Emitter.new()
  emitter:initialize(x, y, radius, energy, duration)

  self.emitters[id] = emitter
end

function Maze:kill_emitter()
  self.emitters[id] = nil
end

function Maze:raycast(from_x, from_y, to_x, to_y)
  return true
end

function Maze:update(dt)
  local zombies = {}
  for id, emitter in pairs(self.emitters) do
  	emitter:update(dt)
  	if not emitter:is_alive() then
  	  zombies[#zombies + 1] = id
  	end
  end

  for _, id in ipairs(zombies) do
  	self.emitters[id] = nil
  end

  for row = 1, self.height do
  	for column = 1, self.width do
  	  local energy = 0
      for _, emitter in pairs(self.emitters) do
      	if self:raycast(emitter.x, emitter.y, row, column) then
	      energy = energy + emitter:energy_at(row, column)
      	end
      end
      self.map[row][column] = energy
  	end
  end
end

function Maze:draw(canvas)
end

-- END OF MODULE ---------------------------------------------------------------

return Maze

-- END OF FILE -----------------------------------------------------------------

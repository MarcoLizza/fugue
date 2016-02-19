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

local Emitter = require('game.emitter')
local generator = require('game.generator')
local array = require('lib.array')

-- MODULE DECLARATION ----------------------------------------------------------

local Maze = {
  -- VALUES --
  width = nil,
  height = nil,
  -- PROPERTIES --
  emitters = {},
  visibility = nil,
  energy = nil
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Maze.__index = Maze

function Maze.new(params)
  local self = setmetatable({}, Maze)
  if params then
    for k, v in pairs(params) do
      self[k] = v
    end
  end
  return self
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Maze:initialize(width, height)
  self.visibility = array.create(width, height, function(x, y)
      return false
    end)

  self.energy = array.create(width, height, function(x, y)
      return 0
    end)

  self.width = width
  self.height = height
  
  self:generate()
end

local DELTAX = {
function Maze:generate()
  local width, height = self.width / 2, self.height / 2
  
  local grid = generator.generate(width, height)

  -- expand
  for y = 1, height do
    local yy = y * 2
    for x = 1, width do
      local xx = x * 2
      local directions = grid[y][x]
      if #directions > 0 then
        self.visibility[yy][xx] = true
        if array.contains(directions, 'w') then
          self.visibility[yy][xx - 1] = true
        end
        if array.contains(directions, 'e') then
          self.visibility[yy][xx + 1] = true
        end
        if array.contains(directions, 's') then
          self.visibility[yy + 1][xx] = true
        end
        if array.contains(directions, 'n') then
          self.visibility[yy - 1][xx] = true
        end
      end
    end
  end
end

function Maze:spawn_emitter(id, x, y, radius, energy, duration)
  local emitter = Emitter.new()
  emitter:initialize(x, y, radius, energy, duration)

  self.emitters[id] = emitter
end

function Maze:kill_emitter(id)
  self.emitters[id] = nil
end

function Maze:get_emitter(id)
  return self.emitters[id]
end

function Maze:raycast(x0, y0, x1, y1, evaluate)
  local dx = math.abs(x1 - x0)
  local dy = math.abs(y1 - y0)
  local sx = x0 < x1 and 1 or -1
  local sy = y0 < y1 and 1 or -1
  local e = dx - dy
 
  while true do
    -- Evaluate and check if the current point can be traversed. If not, quit
    -- telling that the ray cannot be cast from the two points.
    if not evaluate(x0, y0) then
      return false
    end
    -- Quit when the destination point has been reached.
    if x0 == x1 and y0 == y1 then
      break
    end
    --
    local e2 = e + e
    if e2 > -dy then
      e = e - dy
      x0 = x0 + sx
    end
    if e2 < dx then
      e = e + dx
      y0 = y0 + sy
    end
  end
  -- Successfully ended, the destination point is visible.
  return true
end

function Maze:update(dt)
  -- Scan the emitters' list updating them and marking the "dead" ones. The
  -- latter are pulled from the list.
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

  -- Reset the energy-map. Here we should also teke into account the non-changing
  -- parts of the map.
  for y = 1, self.height do
    for x = 1, self.width do
      self.energy[y][x] = 0
    end
  end
  
  -- Scan each emitter and, inside the bounding rectangle, calculate tha influence
  -- sphere. Sum the result to the energy-map.
  for _, emitter in pairs(self.emitters) do
    local left = emitter.x - emitter.radius
    if left < 1 then left = 1 end
    local top = emitter.y - emitter.radius
    if top < 1 then top = 1 end
    local right = emitter.x + emitter.radius
    if right > self.width then right = self.width end
    local bottom = emitter.y + emitter.radius
    if bottom > self.height then bottom = self.height end
    
    for y = top, bottom do
      for x = left, right do
        if self:raycast(emitter.x, emitter.y, x, y,
          function(x, y)
            return self.visibility[y][x]
          end) then
          self.energy[y][x] = self.energy[y][x] + emitter:energy_at(x, y)
        end
      end
    end
  end
end

function Maze:scan(callback)
  for y = 1, self.height do
    for x = 1, self.width do
      callback(x, y, self.visibility[y][x],
        self.energy[y][x])
    end
  end
end

-- END OF MODULE ---------------------------------------------------------------

return Maze

-- END OF FILE -----------------------------------------------------------------

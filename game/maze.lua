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
  cells = nil,
  energy = nil
}

-- LOCAL VARIABLES -------------------------------------------------------------

local patterns = {
  {
    matched = {
      { dx = -1, dy = -1, value = true }, -- 111    111
      { dx =  0, dy = -1, value = true }, -- 101 >> 111
      { dx =  1, dy = -1, value = true }, -- 111    111
      { dx = -1, dy =  0, value = true },
      { dx =  0, dy =  0, value = false },
      { dx =  1, dy =  0, value = true },
      { dx = -1, dy =  1, value = true },
      { dx =  0, dy =  1, value = true },
      { dx =  1, dy =  1, value = true }
    },
    filled = {
      { dx = 0, dy = 0 }
    },
    value = true
  },
  {
    matched = {
      { dx = -1, dy = -1, value = true }, -- 11111    11111
      { dx =  0, dy = -1, value = true }, -- 10001 >> 11111
      { dx =  1, dy = -1, value = true }, -- 11111    11111
      { dx =  2, dy = -1, value = true },
      { dx =  3, dy = -1, value = true },
      { dx = -1, dy =  0, value = true },
      { dx =  0, dy =  0, value = false },
      { dx =  1, dy =  0, value = false },
      { dx =  2, dy =  0, value = false },
      { dx =  3, dy =  0, value = true },
      { dx = -1, dy =  1, value = true },
      { dx =  0, dy =  1, value = true },
      { dx =  1, dy =  1, value = true },
      { dx =  2, dy =  1, value = true },
      { dx =  3, dy =  1, value = true }
    },
    filled = {
      { dx = 0, dy = 0 },
      { dx = 1, dy = 0 },
      { dx = 2, dy = 0 }
    },
    value = true
  },
  {
    matched = {
      { dx = -1, dy = -1, value = true },  -- 111    111
      { dx =  0, dy = -1, value = true },  -- 101    111
      { dx =  1, dy = -1, value = true },  -- 101 >> 111
      { dx = -1, dy =  0, value = true },  -- 101    111
      { dx =  0, dy =  0, value = false }, -- 111    111
      { dx =  1, dy =  0, value = true },
      { dx = -1, dy =  1, value = true },
      { dx =  0, dy =  1, value = false },
      { dx =  1, dy =  1, value = true },
      { dx = -1, dy =  2, value = true },
      { dx =  0, dy =  2, value = false },
      { dx =  1, dy =  2, value = true },
      { dx = -1, dy =  3, value = true },
      { dx =  0, dy =  3, value = true },
      { dx =  1, dy =  3, value = true }
    },
    filled = {
      { dx = 0, dy = 0 },
      { dx = 0, dy = 1 },
      { dx = 0, dy = 2 }
    },
    value = true
  }
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

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function clear(cells, width, height)
  for y = 1, height do
    for x = 1, width do
      cells[y][x] = false
    end
  end
end

local function expand(cells, grid, width, height)
  for y = 1, height do
    local yy = y * 2
    for x = 1, width do
      local xx = x * 2
      local directions = grid[y][x]
      if #directions > 0 then
        cells[yy][xx] = true
        if array.contains(directions, 'w') then
          cells[yy][xx - 1] = true
        end
        if array.contains(directions, 'e') then
          cells[yy][xx + 1] = true
        end
        if array.contains(directions, 's') then
          cells[yy + 1][xx] = true
        end
        if array.contains(directions, 'n') then
          cells[yy - 1][xx] = true
        end
      end
    end
  end
end

local function fill(cells, width, height, pattern)
  for y = 1, height do
    for x = 1, width do
      if cells[y][x] ~= pattern.value then
        local fill = true
        for _, matched in ipairs(pattern.matched) do
          local nx, ny = x + matched.dx, y + matched.dy
          if nx >= 1 and ny >= 1 and nx <= width and ny <= height then
            if cells[ny][nx] ~= matched.value then
              fill = false
              break
            end
          end
        end
        if fill then
          for _, filled in ipairs(pattern.filled) do
            local nx, ny = x + filled.dx, y + filled.dy
            cells[ny][nx] = pattern.value
          end
        end
      end
    end
  end
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Maze:initialize(width, height)
  self.cells = array.create(width, height, function(x, y)
      return false
    end)

  self.energy = array.create(width, height, function(x, y)
      return 0
    end)

  self.width = width
  self.height = height
end

function Maze:generate()
  -- The generator will work on a "half-size" version of the maze, since
  -- we will expand and insert the walls later. Please note that we need
  -- to ensure the the size not the have a decimal part.
  local width, height = math.floor(self.width / 2), math.floor(self.height / 2)

  -- Generate the maze, the "braid" the dead-ends. This will be useful,
  -- later, to crate the rooms.
  local grid = generator.generate(config.maze.type, width, height)
  generator.braid(grid, width, height)

  -- Clear the current map content and expand the generated grid into it.
  clear(self.cells, self.width, self.height)
  expand(self.cells, grid, width, height)
  
  -- Seek selected patterns and fill the map.
  for _, pattern in ipairs(patterns) do
    fill(self.cells, self.width, self.height, pattern)
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
    -- Compute the emitter bounding rectangle.
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
            return self.cells[y][x]
          end) then
          self.energy[y][x] = self.energy[y][x] + emitter:energy_at(x, y)
        end
      end
    end
  end
end

function Maze:is_walkable(x, y)
  return self.cells[y][x]
end

function Maze:scan(callback)
  for y = 1, self.height do
    for x = 1, self.width do
      callback(x, y, self.cells[y][x],
        self.energy[y][x])
    end
  end
end

-- END OF MODULE ---------------------------------------------------------------

return Maze

-- END OF FILE -----------------------------------------------------------------

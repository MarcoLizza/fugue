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

local array = require('lib.array')

-- MODULE DECLARATION ----------------------------------------------------------

local generator = {
}

-- LOCAL VARIABLES -------------------------------------------------------------

local DELTAX = {
  n = 0, s = 0, e = 1, w = -1,
}

local DELTAY = {
  n = -1, s = 1, e = 0, w = 0,
}

local OPPOSITE = {
  n = 's', s = 'n', e = 'w', w = 'e',
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function walk(grid, width, height, x, y)
  local directions = array.shuffle({ 'n', 's', 'e', 'w' })
  for _, direction in ipairs(directions) do
    local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
    if nx >= 1 and ny >= 1 and ny <= height and nx <= width and #grid[ny][nx] == 0 then
      table.insert(grid[y][x], direction)
      table.insert(grid[ny][nx], OPPOSITE[direction])
      return nx, ny
    end
  end
  return nil, nil
end

local function hunt(grid, width, height)
  for y = 1, height do
    for x = 1, width do
      if #grid[y][x] == 0 then -- unvisited cell
        local neighbours = {}
        if y > 1 and #grid[y - 1][x] > 0 then
          table.insert(neighbours, 'n')
        end
        if x > 1 and #grid[y][x - 1] > 0 then
          table.insert(neighbours, 'w')
        end
        if x + 1 < width and #grid[y][x + 1] > 0 then
          table.insert(neighbours, 'e')
        end
        if y + 1 < height and #grid[y + 1][x] > 0 then
          table.insert(neighbours, 's')
        end
        if #neighbours > 0 then -- at least a valid neighbour
          local direction = neighbours[love.math.random(#neighbours)]
          local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
          table.insert(grid[y][x], direction)
          table.insert(grid[ny][nx], OPPOSITE[direction])
          return nx, ny
        end
      end
    end
  end

  return nil, nil
end

local function reduce(grid, width, height, amount)
  while true do
--    local oy = love.math.random(height)
    for y = 1, height do
      for x = 1, width do
        if #grid[y][x] == 1 then
          local direction = grid[y][x][1]
          local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
          grid[y][x] = {}
          array.remove(grid[ny][nx], OPPOSITE[direction])
          amount = amount - 1
          if amount == 0 then
            return
          end
        end
      end
    end
  end
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function generator.generate(width, height)
  local grid = array.create(width, height, function(x, y)
      return {}
    end)

  local x, y = love.math.random(width), love.math.random(height)

  while true do
    x, y = walk(grid, width, height, x, y)
    if not x then
      x, y = hunt(grid, width, height)
      if not x then
        break
      end
    end
  end

--  reduce(grid, width, height, 250)

  return grid
end

-- END OF MODULE ---------------------------------------------------------------

return generator

-- END OF FILE -----------------------------------------------------------------

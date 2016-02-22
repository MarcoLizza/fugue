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

local function randomize_step()
  local try = love.math.random(100)
  if try < 51 then
    return -1
  else
    return 1
  end
end

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
--  local step_x = randomize_step()
--  local from_x = step_x == 1 and 1 or width
--  local to_x = step_x == 1 and width or 1
--  local step_y = randomize_step()
--  local from_y = step_y == 1 and 1 or height
--  local to_y = step_y == 1 and height or 1
  
--  for y = from_y, to_y, step_y do
--    for x = from_x, to_x, step_x do
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
        if x < width and #grid[y][x + 1] > 0 then
          table.insert(neighbours, 'e')
        end
        if y < height and #grid[y + 1][x] > 0 then
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

-- MODULE FUNCTIONS ------------------------------------------------------------

function generator.braid(grid, width, height)
  for y = 1, height do
    for x = 1, width do
      if #grid[y][x] == 1 then -- found a dead-end
        local source = grid[y][x][1] -- from whence we are coming?
        -- Find the available neighbours, excluding the edge and the source
        -- cell.
        local neighbours = {}
        if y > 1 and source ~= 'n' then
          table.insert(neighbours, 'n')
        end
        if x > 1 and source ~= 'w'  then
          table.insert(neighbours, 'w')
        end
        if x < width and source ~= 'e'  then
          table.insert(neighbours, 'e')
        end
        if y < height and source ~= 's'  then
          table.insert(neighbours, 's')
        end
        
        -- Carve a passage to a random picked neighbour.
        local direction = neighbours[love.math.random(#neighbours)]
        local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
        table.insert(grid[y][x], direction)
        table.insert(grid[ny][nx], OPPOSITE[direction])
      end
    end
  end
end

-- Recursive backtracker generator (stack based).
function generator.generate_rec(width, height)
  local grid = array.create(width, height, function(x, y)
      return {}
    end)

  local queue = { { x = love.math.random(width), y = love.math.random(height) } }
  local cell = nil

  while #queue > 0 do
    -- Current cell is not set, so we are going to pop-it from the stack.
    if not cell then
      cell = table.remove(queue)
    end
    local x, y = cell.x, cell.y

    -- Find any unvisited neighbours of the current cell.
    local neighbours = {}
    if y > 1 and #grid[y - 1][x] == 0 then
      table.insert(neighbours, 'n')
    end
    if x > 1 and #grid[y][x - 1] == 0 then
      table.insert(neighbours, 'w')
    end
    if x < width and #grid[y][x + 1] == 0 then
      table.insert(neighbours, 'e')
    end
    if y < height and #grid[y + 1][x] == 0 then
      table.insert(neighbours, 's')
    end

    -- If the cell has some valid neighbours...
    if #neighbours > 0 then
      -- ... push it into the stack (as we might fork from it later).
      table.insert(queue, cell)
      -- Pick a random neighbour and carve a passage to it.
      local direction = neighbours[love.math.random(#neighbours)]
      local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
      table.insert(grid[y][x], direction)
      table.insert(grid[ny][nx], OPPOSITE[direction])
      -- Update the current cell, moving to the neighbour.
      cell = { x = nx, y = ny }
    else
      -- Request a new cell from the stack.
      cell = nil
    end
  end

  return grid
end

function generator.generate_hak(width, height)
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

  return grid
end

function generator.generate(mode, width, height)
  if mode == 'hak' then
    return generator.generate_hak(width, height)
  elseif mode == 'rec' then
    return generator.generate_rec(width, height)
  else
    return generator.generate_rec(width, height)
  end
end

-- END OF MODULE ---------------------------------------------------------------

return generator

-- END OF FILE -----------------------------------------------------------------

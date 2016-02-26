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
      -- We stop on each unvisited cell...
      if #grid[y][x] == 0 then
        -- ... and check for a random neighbour already visited.
        local directions = array.shuffle({ 'n', 's', 'e', 'w' })
        for _, direction in ipairs(directions) do
          local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
          if nx >= 1 and ny >= 1 and ny <= height and nx <= width and #grid[ny][nx] > 0 then -- already visited
            table.insert(grid[y][x], direction)
            table.insert(grid[ny][nx], OPPOSITE[direction])
            return nx, ny
          end
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
        -- Pick a valid neighbour, excluding the edge and the source cell.
        local directions = array.shuffle({ 'n', 's', 'e', 'w' })
        for _, direction in ipairs(directions) do
          if direction ~= source then -- we are not considering the source
            local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
            if nx >= 1 and ny >= 1 and ny <= height and nx <= width then
              table.insert(grid[y][x], direction)
              table.insert(grid[ny][nx], OPPOSITE[direction])
              break -- relax this for bigger rooms!!!
            end
          end
        end
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
    local moved = false
    local directions = array.shuffle({ 'n', 's', 'e', 'w' })
    for _, direction in ipairs(directions) do
      local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
      if nx >= 1 and ny >= 1 and ny <= height and nx <= width and #grid[ny][nx] == 0 then
        -- ... push it into the stack (as we might fork from it later).
        table.insert(queue, cell)
      -- Carve a passage to it.
        table.insert(grid[y][x], direction)
        table.insert(grid[ny][nx], OPPOSITE[direction])
      -- Update the current cell, moving to the neighbour.
        cell = { x = nx, y = ny }
        moved = true
        break
      end
    end

    -- Request a new cell from the stack.
    if not moved then
      cell = nil
    end
  end

  return grid
end

-- Growing-tree generator.
function generator.generate_gt(width, height, chooser)
  local grid = array.create(width, height, function(x, y)
      return {}
    end)

  local queue = { { x = love.math.random(width), y = love.math.random(height) } }

  while #queue > 0 do
    local index = chooser(queue)
    local cell = queue[index]
    local x, y = cell.x, cell.y

    local directions = array.shuffle({ 'n', 's', 'e', 'w' })
    for _, direction in ipairs(directions) do
      local nx, ny = x + DELTAX[direction], y + DELTAY[direction]
      if nx >= 1 and ny >= 1 and ny <= height and nx <= width and #grid[ny][nx] == 0 then
        --
        table.insert(grid[y][x], direction)
        table.insert(grid[ny][nx], OPPOSITE[direction])
        -- ... push it into the stack (as we might fork from it later).
        table.insert(queue, { x = nx, y = ny })
        --
        index = nil
      end
    end

    if index then
      table.remove(queue, index)
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
  elseif mode == 'gt-fifo' then -- recursive backtracker
    return generator.generate_gt(width, height, function(queue)
        return #queue
      end)
  elseif mode == 'gt-filo' then -- tree
    return generator.generate_gt(width, height, function(queue)
        return 1
      end)
  elseif mode == 'gt-rand' then -- prim's algorithm
    return generator.generate_gt(width, height, function(queue)
        return love.math.random(#queue)
      end)
  else
    return generator.generate_rec(width, height)
  end
end

-- END OF MODULE ---------------------------------------------------------------

return generator

-- END OF FILE -----------------------------------------------------------------

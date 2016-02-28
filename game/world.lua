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
local constants = require('game.constants')
local Maze = require('game.maze')
local Foe = require('game.foe')

-- MODULE DECLARATION ----------------------------------------------------------

local world = {
  maze = nil,
  -- ENTITIES --
  avatar = { position = { x = 2, y = 2 }, visible = true, health = 10, keys = 0, flares = 3, duration = 60 },
  keys = { { position = { x = 18, y = 22 }, visible = true } },
  door = { position = { x = 10, y = 32 }, visible = true },
  foes = {},
  flares = {}
}

-- LOCAL VARIABLES -------------------------------------------------------------

local _tints = {
  ground = { 0x99, 0x88, 0x77, 0 },
  wall = { 0x77, 0x55, 0x22, 0 },
  concrete = { 0x44, 0x33, 0x11, 0 },
  flare = { 0xff, 0xdd, 0x00, 0xff },
  undefined = { 0x3f, 0x3f, 0x3f, 0 }
}

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function overlap(a, b, c, d) -- points
  local ax, ay, bx, by = a, b, c, d
  if type(a) == 'table' and type(b) == 'table' then
    ax, ay, bx, by = a.x, a.y, b.x, b.y
  end
  return ax == bx and ay == by
end

local function iterate(object, table, callback)
  local ax, ay = object.position.x, object.position.y
  for _, other in ipairs(table) do
    local bx, by = other.position.x, other.position.y
    if not callback(ax, ay, bx, by) then
      break
    end
  end
end

local function compass(x, y)
  if x == 0 and y == 0 then
    return '-'
  end
  local angle = math.atan2(y, x)
  local scaled = math.floor(angle / (2 * math.pi / 8))
  local value = (scaled + 8) % 8
  if value == 0 then
    return 'e'
  elseif value == 1 then
    return 'se'
  elseif value == 2 then
    return 's'
  elseif value == 3 then
    return 'sw'
  elseif value == 4 then
    return 'w'
  elseif value == 5 then
    return 'nw'
  elseif value == 6 then
    return 'n'
  elseif value == 7 then
    return 'ne'
  end
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function world:initialize()
  self.maze = Maze.new()
  self.maze:initialize(constants.MAZE_WIDTH, constants.MAZE_HEIGHT)
end

function world:events(keys)
  local dx, dy = 0, 0 -- find the delta movement
  local drop_flare = false
  if keys['up'] then
    dy = dy - 1
  end
  if keys['down'] then
    dy = dy + 1
  end
  if keys['left'] then
    dx = dx - 1
  end
  if keys['right'] then
    dx = dx + 1
  end
  if keys['x'] then
    drop_flare = true
  end

  -- Compute the new position by checking the map walkability. Note that we
  -- don't need to check the boundaries since the map features a non-walkable
  -- border that force the player *inside* the map itself.
  local avatar = self.avatar
  local position = avatar.position
  local _ = self:move(position, dx, dy)

  local emitter = self.maze:get_emitter('avatar')
  emitter:set_position(math.floor(position.x), math.floor(position.y))
  
  if drop_flare and avatar.flares > 0 then
    local flare_id = string.format('flare-%d', avatar.flares)
    local flare = { position = { x = position.x, y = position.y } }
    self.flares[flare_id] = flare
    self.maze:spawn_emitter(flare_id, position.x, position.y, 7, 3, 30)
    avatar.flares = avatar.flares - 1
  end
end

function world:update(dt)
  -- Update the maze state. The callback will be invoked when an emitter
  -- disappear.
  self.maze:update(dt, function(id)
      self.flares[id] = nil
    end)

  -- Update and advance the foes.
  for _, foe in pairs(self.foes) do
    foe:update(dt)
  end
  
  --
  local avatar = self.avatar
  
  if avatar.keys < #self.keys then
    for _, key in ipairs(self.keys) do
      if key.visible and overlap(avatar.position, key.position) then
        avatar.keys = avatar.keys + 1
        key.visible = false
      end
    end
  else
    local door = self.door
    if overlap(avatar.position, door.position) then
      door.visible = false
    end
  end
  
  -- The player duration decreases during the normal gameplay by a constant rate.
  -- This rate is higher when a foe is colliding with the player.
  local decay = 0.10
  if self:hit() then
    decay = 10
    if avatar.health > 0 then
      avatar.health = avatar.health - 2 * dt
    end
  end
  avatar.duration = avatar.duration - (decay * dt)

--  if avatar.duration == 0 or avatar.health == 0 then
--    return 'game-over'
--  elseif avatar.goal then
--    return 'game-win'
--  else
--    return nil
--  end
end

function world:hit()
  local avatar = self.avatar
  local occurred = false
  iterate(avatar, self.foes, function(ax, ay, bx, by)
      if overlap(ax, ay, bx, by) then
        occurred = true
        return false
      else
        return true
      end
    end)
  return occurred
end

function world:calculate_danger()
  local avatar = self.avatar
  local min_distance = math.huge
  iterate(avatar, self.foes, function(ax, ay, bx, by)
      local dx, dy = ax - bx, ay - by
      local distance = math.sqrt(dx * dx + dy * dy)
      if min_distance > distance then
        min_distance = distance
      end
      return true
    end)
  min_distance = math.min(10, min_distance)
  return 1 - (min_distance / 10)
end

function world:draw()
  if config.debug.shadows then
    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = self:to_screen(x, y)
        local tint = _tints[color]
        local alpha = math.min(math.floor(255 * energy), 255)
        tint[4] = alpha
        love.graphics.setColor(tint)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)

    local danger = self:calculate_danger()
--love.graphics.print(string.format('%.2f', danger), 0, 0)
    love.graphics.setColor(255, 0, 0, math.floor(danger * 127))
    love.graphics.rectangle('fill', 0, 0,
      constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT)
  else
    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = self:to_screen(x, y)
        local tint = cell and 63 or 15
        love.graphics.setColor(tint, tint, tint)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)

    self.maze:scan(function(x, y, color, cell, energy)
        local sx, sy = self:to_screen(x, y)
        local alpha = math.min(math.floor(255 * energy), 255)
        love.graphics.setColor(alpha, alpha, alpha, 127)
        love.graphics.rectangle('fill', sx, sy,
          constants.CELL_WIDTH, constants.CELL_HEIGHT)
      end)
  end

  for _, flare in pairs(self.flares) do -- draw the flares
    local x, y = flare.position.x, flare.position.y
    local energy = self.maze:energy_at(x, y)
    local alpha = math.min(math.floor(255 * energy), 255)
    local sx, sy = self:to_screen(x, y)
    local tint = _tints['flare']
    tint[4] = alpha
    love.graphics.setColor(tint)
    love.graphics.rectangle('fill', sx, sy,
      constants.CELL_WIDTH, constants.CELL_HEIGHT)
  end

  for _, key in pairs(self.keys) do -- draw the keys
    if key.visible then
      local x, y = key.position.x, key.position.y
      local energy = self.maze:energy_at(x, y)
      local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
      local sx, sy = self:to_screen(x, y)
      love.graphics.setColor(127, 255, 127, alpha)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end
  end

  local avatar = self.avatar
  if true then
    local x, y = avatar.position.x, avatar.position.y
    local sx, sy = self:to_screen(x, y)
    love.graphics.setColor(127, 255, 255, 255)
    love.graphics.rectangle('fill', sx, sy,
      constants.CELL_WIDTH, constants.CELL_HEIGHT)
  end

  if avatar.keys == #self.keys then
    local door = self.door
    if door.visible then
      local x, y = door.position.x, door.position.y
      local energy = self.maze:energy_at(x, y)
      local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
      local sx, sy = self:to_screen(x, y)
      love.graphics.setColor(127, 255, 127, alpha)
      love.graphics.rectangle('fill', sx, sy,
        constants.CELL_WIDTH, constants.CELL_HEIGHT)
    end
  end

  for _, foe in pairs(self.foes) do
    foe:draw()
  end

  -- HUD
  -- Compute the angle/distance from the current target (key, door, etc)
  -- and display a compass.
  -- http://stackoverflow.com/questions/1437790/how-to-snap-a-directional-2d-vector-to-a-compass-n-ne-e-se-s-sw-w-nw
  local target = avatar.keys < #self.keys and self.keys[avatar.keys + 1] or self.door
  local dx, dy = target.position.x - avatar.position.x, target.position.y - avatar.position.y -- FIXME: delta?
  local compass = compass(dx, dy)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(string.format('D: %d | H: %d | F: %d | A: %s', avatar.duration, avatar.health, avatar.flares, compass), 0, 0)

  love.graphics.setColor(255, 255, 255)
end

local _level = 4

function world:generate()
  self.maze:generate()

  local keys = _level / 5
  local foes = _level % 5

  -- divide the maze into nine sectors
  --   123
  --   456
  --   789
  -- randomize avatar position (from a random corner, each time)
  --   1, 3, 7, 9
  -- randomize foes, near the cross-center of the screen
  --   2, 4, 6, 8
  -- randomize the items, almost everywhere but near the avatar

  -- the player has tree flares
  -- if dropped the foes will move to it
  
  -- levelling
  -- start with 1 foe and only the door
  -- then increase the amount of foes and a number of keys to be fetched prior entering the door
  -- (1 foe, 0 to 4 keys, then 2 foes
  for _ = 1, foes do
    local foe = Foe.new()
    foe:initialize(self, 22, 22)
    self.foes[#self.foes + 1] = foe
  end

  self.maze:spawn_emitter('avatar', 2, 2, 5, 3)
end

function world:to_screen(x, y)
  return (x - 1) * constants.CELL_WIDTH, (y - 1) * constants.CELL_WIDTH
end

function world:move(point, dx, dy) -- Maze:move_to()
  local x, y = point.x, point.y
  local nx, ny = x + dx, y + dy
  if self.maze:is_walkable(nx, ny) then
    point.x = nx
    point.y = ny
  elseif self.maze:is_walkable(x, ny) then
    point.y = ny
  elseif self.maze:is_walkable(nx, y) then
    point.x = nx
  end
  return point.x ~= x or point.y ~= y
end

function world:is_visible(a, b, c, d)
  return self.maze:is_visible(a, b, c, d)
end

-- END OF MODULE -------------------------------------------------------------

return world

-- END OF FILE ---------------------------------------------------------------

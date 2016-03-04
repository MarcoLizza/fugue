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
local Foe = require('game.foe')
local graphics = require('lib.graphics')
local utils = require('lib.utils')

-- MODULE DECLARATION ----------------------------------------------------------

local Entities = {
  world = nil,
  avatar = nil,
  door = nil,
  keys = { },
  foes = {},
  flares = {}
}

-- MODULE OBJECT CONSTRUCTOR ---------------------------------------------------

Entities.__index = Entities

function Entities.new()
  local self = setmetatable({}, Entities)
  return self
end

-- LOCAL FUNCTIONS -------------------------------------------------------------

local function iterate(object, table, callback)
  local ax, ay = object.position.x, object.position.y
  for _, other in ipairs(table) do
    local bx, by = other.position.x, other.position.y
    if not callback(ax, ay, bx, by) then
      break
    end
  end
end

local function randomize_position()
  return love.math.random(constants.MAZE_WIDTH), love.math.random(constants.MAZE_HEIGHT)
end

-- MODULE FUNCTIONS ------------------------------------------------------------

function Entities:initialize(world)
  self.world = world
end

function Entities:generate(level)
  local world = self.world
  local maze = world.maze

  -- We are cyclically incrementing the foes count, the restart and increase the
  -- number of keys to be found.
  local keys = level % 5
  local foes = level / 3

  -- The avatar is placed on a fixed position at a different corner each level.
  -- Please note that we are safe in assuming that the corner position is always
  -- walkable.
  local avatar = { position = nil, health = 10, keys = 0, flares = 3, duration = 60 }
  self.avatar = avatar
  
  local turn = level % 4
  if turn == 0 then
    avatar.position = { x = 2, y = 2 }
  elseif turn == 1 then
    avatar.position = { x = maze.width - 1, y = 2 }
  elseif turn == 2 then
    avatar.position = { x = maze.width - 1, y = maze.height - 1 }
  else
    avatar.position = { x = 2, y = maze.height - 1 }
  end
  
  -- Pick a random position for the door. It need to be far from the player.
  -- Initially, the door is not visible.
  while true do
    local x, y = randomize_position()
    local distance = utils.distance(avatar.position.x, avatar.position.y, x, y)
    if maze:is_walkable(x, y) and distance >= 35 then
      local door = { position = { x = x, y = y }, visible = false, unlocked = false }
      self.door = door
      break
    end
  end

  -- Generate the keys. Each key need to be "far enough" from the avatar, so
  -- we are cycling util we find some reasonable positions.
  self.keys = {}
  while #self.keys < keys do
    local x, y = randomize_position()
    local distance = utils.distance(avatar.position.x, avatar.position.y, x, y)
    if maze:is_walkable(x, y) and distance >= 20 then
      local key = { position = { x = x, y = y }, visible = true }
      self.keys[#self.keys + 1] = key
    end
  end

  -- TODO: divide the maze into nine sectors
  --   123
  --   456
  --   789
  -- randomize foes, near the cross-center of the screen
  --   2, 4, 6, 8
  self.foes = {}
  while #self.foes < foes do
    local x, y = randomize_position()
    local distance = utils.distance(math.floor(maze.width / 2), math.floor(maze.height / 2), x, y)
    if maze:is_walkable(x, y) and distance < 15 then
      local foe = Foe.new()
      foe:initialize(self.world, x, y)
      self.foes[#self.foes + 1] = foe
    end
  end

  -- Empty the flares list.
  self.flares = {}
end

function Entities:events(keys)
  local dx, dy = 0, 0 -- find the delta movement
  local drop_flare = false
  if keys.pressed['up'] then
    dy = dy - 1
  end
  if keys.pressed['down'] then
    dy = dy + 1
  end
  if keys.pressed['left'] then
    dx = dx - 1
  end
  if keys.pressed['right'] then
    dx = dx + 1
  end
  if keys.pressed['x'] then
    drop_flare = true
  end

  --
  local avatar = self.avatar

  -- Compute the new position by checking the map walkability. Note that we
  -- don't need to check the boundaries since the map features a non-walkable
  -- border that force the player *inside* the map itself.
  local position = avatar.position
  local _ = self.world:move(position, dx, dy)
  self.world.maze:move_emitter('avatar', math.floor(position.x), math.floor(position.y))

  -- If the player requested a flare drop, leave it at the current player
  -- position
  if drop_flare and avatar.flares > 0 then
    local flare_id = string.format('flare-%d', avatar.flares)
    local flare = { position = { x = position.x, y = position.y } }
    self.flares[flare_id] = flare
    self.world.maze:spawn_emitter(flare_id, position.x, position.y, 7, 3, 30)
    avatar.flares = avatar.flares - 1
  end
end

function Entities:update(dt)
  -- Update and advance the foes.
  for _, foe in pairs(self.foes) do
    foe:update(dt)
  end

  -- Check for player collision (i.e. fetch) of a key. It all the keys
  -- have been fetched, we check for door collision.
  local avatar = self.avatar

  if avatar.keys < #self.keys then
    for _, key in ipairs(self.keys) do
      if key.visible and utils.overlap(avatar.position, key.position) then
        avatar.keys = avatar.keys + 1
        key.visible = false
      end
    end
  else
    local door = self.door
    door.visible = true
    if utils.overlap(avatar.position, door.position) then
      door.visible = false
      door.unlocked = true
    end
  end
  
  -- The player duration decreases during the normal gameplay by a constant rate.
  -- This rate is higher when a foe is colliding with the player.
  local decay = 0.10
  if self:is_avatar_hit() then
    decay = 10
    if avatar.health > 0 then
      avatar.health = avatar.health - 2 * dt
    end
  end
  avatar.duration = avatar.duration - (decay * dt)
end

function Entities:draw()
  local world = self.world
  local maze = world.maze
  local avatar = self.avatar
  
  -- FIXME: Flares will dim according to their energy value.
  for _, flare in pairs(self.flares) do -- draw the flares
    local x, y = flare.position.x, flare.position.y
    local energy = maze:energy_at(x, y) --  maze:get_entity(flare_id):energy_at(x, y)
    local alpha = math.min(math.floor(255 * energy), 255)
    graphics.draw(x, y, 'yellow', alpha)
  end

  -- Keys are visible according to the global energy level on their spot.
  for _, key in pairs(self.keys) do -- draw the keys
    if key.visible then
      local x, y = key.position.x, key.position.y
      local energy = maze:energy_at(x, y)
      local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
      graphics.draw(x, y, 'teal', alpha)
    end
  end

  -- The avatar is always visible. It need to be visible over flares
  -- and keys.
  local x, y = avatar.position.x, avatar.position.y
  graphics.draw(x, y, 'cyan')

  -- Display the door, if visible (e.g. the player has fetched all
  -- the keys).
  local door = self.door
  if door.visible then
    local x, y = door.position.x, door.position.y
    local energy = maze:energy_at(x, y)
    local alpha = config.debug.cheat and 255 or math.min(math.floor(255 * energy), 255)
    graphics.draw(x, y, 'green', alpha)
  end

  for _, foe in pairs(self.foes) do
    foe:draw()
  end
end

function Entities:is_avatar_hit()
  local avatar = self.avatar
  
  local occurred = false
  iterate(avatar, self.foes, function(ax, ay, bx, by)
      if utils.overlap(ax, ay, bx, by) then
        occurred = true
        return false
      else
        return true
      end
    end)
  return occurred
end

function Entities:danger_level()
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


-- END OF MODULE ---------------------------------------------------------------

return Entities

-- END OF FILE -----------------------------------------------------------------

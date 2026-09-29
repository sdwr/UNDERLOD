local SpawnerHatch = Object:extend()
SpawnerHatch:implement(GameObject)

function SpawnerHatch:init(args)
  self:init_game_object(args)
  if self.unit and not self.unit.dead and self.unit.state == unit_states['casting'] then
    self.unit:spawn_brood()
  end
  self.dead = true
end

function SpawnerHatch:update(dt) end
function SpawnerHatch:draw() end

local fns = {}
fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.class = 'special_enemy'
  self.maxSummons = 12
  self.brood_wave_size = 6
  self.holds_position = true
  self.knockback_immune = true
  self.baseIdleTimer = 0
  self.baseActionTimer = 30
  local arena = main.current.current_arena
  local ox, oy = arena and arena.offset_x or 0, arena and arena.offset_y or 0
  local margin = 55
  self.park_point = {
    x = math.clamp(self.x, ox + margin, ox + gw - margin),
    y = math.clamp(self.y, oy + margin, oy + gh - margin),
  }
  self.custom_action_selector = function(self, viable_attacks)
    if not self.parked then return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE end
    if #viable_attacks > 0 then return 'attack', viable_attacks[1] end
    return 'retry', nil
  end
  self.summons = 0
  self.brood = {}
  self.stopChasingInRange = true
  self.attack_range = 120
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)
  self.attack_options = {{
    name = 'hatch_brood',
    viable = function() return self.parked and self:count_brood() <= self.maxSummons - self.brood_wave_size end,
    oncast = function() end,
    cast_length = 1,
    cancel_on_range = false,
    cancel_no_target = false,
    instantspell = true,
    spellclass = SpawnerHatch,
    spelldata = {group = main.current.main},
  }}
end

fns['acquire_target_seek_to_range'] = function(self)
  self.target_location = self.park_point
  return true
end

fns['update_move_seek_to_range'] = function(self)
  local p = self.park_point
  if self:distance_to_point(p.x, p.y) <= 4 then
    self:set_velocity(0, 0)
    self.parked = true
    if self.body then self.body:setType('static') end
    return false
  end
  self:seek_point(p.x, p.y, SEEK_DECELERATION, SEEK_WEIGHT)
  self:rotate_towards_velocity(0.5)
  return true
end

fns['count_brood'] = function(self)
  for i = #self.brood, 1, -1 do
    if self.brood[i].dead then table.remove(self.brood, i) end
  end
  self.summons = #self.brood
  return self.summons
end

fns['spawn_brood'] = function(self)
  if self.dead or not self.parked then return end
  local count = self.brood_wave_size
  if self.maxSummons - self:count_brood() < count then return end
  local spawned = 0
  for i = 1, count do
    local angle = (self.r or 0) + (i - 1) * 2 * math.pi / count
    local x, y = self.x + 18 * math.cos(angle), self.y + 18 * math.sin(angle)
    if Can_Spawn(4, {x = x, y = y}) then
      local child = Enemy{
        type = 'swarmer', size = 'critter', mini_swarmer = true,
        group = self.group or main.current.main, x = x, y = y, r = angle,
        level = self.level, parent = self, data = {},
        _counted_for_quota = true,
      }
      if not child.dead then
        table.insert(self.brood, child)
        spawned = spawned + 1
      end
    end
  end
  self.summons = #self.brood
  if spawned > 0 then
    self.hfx:use('hit', 0.3, 200, 10, 0.2)
    pop2:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  end
end

fns['draw_body'] = function(self, color, grow, line_width)
  local x, y, g = self.x, self.y, grow or 0
  graphics.polygon({x-12-g,y, x-6-g,y-11-g, x+6+g,y-11-g,
    x+12+g,y, x+6+g,y+11+g, x-6-g,y+11+g}, color, line_width)
  if line_width then return end
  graphics.polygon({x-8,y, x-4,y-7, x+4,y-7, x+8,y, x+4,y+7, x-4,y+7}, bg[0])
  for _, offset in ipairs({{-3,-3}, {3,-3}, {-3,3}, {3,3}}) do
    local cx, cy = x + offset[1], y + offset[2]
    graphics.polygon({cx+2,cy, cx,cy+1.5, cx-2,cy, cx,cy-1.5}, color)
  end
end

fns['draw_enemy'] = function(self)
  self:draw_fallback_animation()
end

enemy_to_class['spawner'] = fns

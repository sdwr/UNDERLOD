-- Mortar: walks straight at the closest troop like the tank and lobs a
-- 3-shell volley every few seconds without breaking stride. The volley is a
-- timer-driven spell (no cast, spell_duration 0) so it never channels.
MORTAR_SHOTS = 3
MORTAR_SHOT_INTERVAL = 1.2
MORTAR_TARGET_OFFSET = 35   -- shells scatter within +-this of the troop

local fns = {}
fns['init_enemy'] = function(self)
  self.data = self.data or {}

  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Tank-style approach: knockback immune, no stop in range, closest troop.
  self.knockback_immune = true
  self.stopChasingInRange = false
  self.haltOnPlayerContact = true
  self.baseIdleTimer = 0
  self.baseActionTimer = 1
  self.attack_options = {}
  self.acquire_target_seek = function(self)
    self.target = Helper.Target:get_closest_enemy(self)
    return self.target ~= nil
  end

  local cadence = enemy_attack_cooldowns['mortar']
  self.t:after(cadence * 0.5, function()
    self:fire_volley()
    self.t:every(cadence, function() self:fire_volley() end)
  end)
end

fns['fire_volley'] = function(self)
  if self.dead then return end
  local target = Helper.Target:get_random_enemy(self)
  if not target or target.dead then return end
  Mortar_Spell{
    group = main.current.main,
    unit = self,
    target = target,
    spell_duration = 0,
    num_shots = MORTAR_SHOTS,
    shot_interval = MORTAR_SHOT_INTERVAL,
    damage = self.dmg,
    rs = 25,
    target_offset = MORTAR_TARGET_OFFSET,
    parent = self,
  }
end


fns['draw_body'] = function(self, color, grow, line_width)
  local x, y, g = self.x, self.y, grow or 0
  graphics.polygon({x-12-g,y-5-g, x-5-g,y-12-g, x+5+g,y-12-g, x+12+g,y-5-g,
    x+12+g,y+5+g, x+5+g,y+12+g, x-5-g,y+12+g, x-12-g,y+5+g}, color, line_width)
  if line_width then return end
  graphics.polygon({x-7,y-3, x-3,y-7, x+3,y-7, x+7,y-3,
    x+7,y+3, x+3,y+7, x-3,y+7, x-7,y+3}, bg[0])
  graphics.rectangle(x+6, y, 13, 8, 0, 0, color)
  graphics.rectangle(x+8, y, 8, 3, 0, 0, bg[0])
end

fns['draw_enemy'] = function(self)
  self:draw_fallback_animation()
end

enemy_to_class['mortar'] = fns
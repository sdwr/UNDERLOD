-- Tank: a slow, durable siege body that heads for the level orb. It seeks
-- the nearest troop in arenas without an orb and is immune to knockback.

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'tank'

  self.color = red[3]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Hard knockback immunity, like slime/roach. calculate_stats only touches
  -- knockback_resistance (which caps at 0.8), so this flag survives intact
  -- and short-circuits both Helper.Unit:apply_knockback paths.
  self.knockback_immune = true

  -- Keep the slow siege advance steady instead of wandering between neighbors.
  self.seek_wander_mult = 0
  self.separation_mult = 0.15
  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.baseIdleTimer = 0
  self.baseActionTimer = 1

  -- No spells/projectiles; reaching the objective is the threat.
  self.attack_options = {}

  -- Prioritize the orb; boss arenas without one retain nearest-troop seeking.
  self.acquire_target_seek = function(self)
    if self.group and self.group.level_orb then return Enemy.acquire_target_seek(self) end
    self.target = Helper.Target:get_closest_enemy(self)
    return self.target ~= nil
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['tank'] = fns

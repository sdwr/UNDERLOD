-- Tank: a tanky rounded-square melee approacher with no attacks. T2 levels
-- swap it in for the occasional swarmer clump (see basic_pool.replace_type
-- in spawnmanager). Reduced (not full) knockback so it still flinches on
-- big hits but holds its line through normal fire.

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

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.baseIdleTimer = 0
  self.baseActionTimer = 1

  -- No spells/projectiles - the tank is purely a body that walks at you.
  self.attack_options = {}

  -- Override the default SEEK target picker (30% closest / 70% random) so
  -- the tank always commits to the closest troop. Without this it picks a
  -- random troop each re-acquisition and bobs between targets, which reads
  -- as "moving obliquely" instead of bearing down on the player.
  self.acquire_target_seek = function(self)
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

-- Slime: a special enemy that crosses the arena center on a straight path and
-- leaves a purple slime (poison) trail behind it. It has no ranged attack - the
-- lingering trail is its only threat.

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}

  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  -- No dedicated sprite yet; falls back to colored shape via draw_fallback_animation.
  self.icon = 'slime'

  -- Slimes don't get knocked around. They're a big blob that holds its line.
  self.knockback_immune = true

  self.baseIdleTimer = 0.4
  self.baseActionTimer = 2.0

  -- Slime walks straight through the arena center.
  self.movement_options = {MOVEMENT_TYPE_PATH_ACROSS}

  -- No attacks: the slime's only threat is the poison trail it leaves behind.
  self.attack_options = {}

  -- Purple slime trail: drop a poison floor pool behind the slime every ~0.4s.
  -- Visually identical to the purple swarmer's poison (same Area_Spell config),
  -- with a 30s decay so pools linger through more of the level.
  self.t:every(0.4, function()
    if self.dead then return end
    local effect_color_outline = purple[0]:clone()
    effect_color_outline.a = 0.5
    Area_Spell{
      group = main.current.effects,
      unit = self,
      is_troop = false,
      x = self.x,
      y = self.y,
      damage = function() return self.dmg * 0.1 end,
      damage_ticks = true,
      hit_only_once = false,
      radius = 0,
      max_radius = 11,
      expand_duration = 0.4,
      color = effect_color_outline,
      opacity = 0.3,
      line_width = 0,
      tick_rate = 0.5,
      duration = 30,
      pick_shape = 'circle',
      parent = self,
      floor_effect = 'poison',
      -- Area_Spell hits troops via Helper.Damage:chained_hit, which skips the
      -- Troop:hit() audio path. Play the player-hit sound here so trail ticks
      -- aren't silent.
      on_hit_callback = function(spell, target, from)
        if target and target.is_troop and not target.dead then
          table.random({player_hit1, player_hit2}):play{pitch = random:float(0.95, 1.05), volume = 0.9}
        end
      end,
    }
  end)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['slime'] = fns

-- Small Archer: the first "small-special" — a squishy ranged poke unit. Spawns
-- offscreen, makes one approach toward the perimeter (SEEK_TO_RANGE at a large
-- radius so it posts up near the edge rather than in the player's face), then
-- becomes a stationary turret firing a single aimed projectile every few
-- seconds. Cast animation windup, no targeting line, medium-slow projectile.
-- Modeled on orb.lua (approach-then-turret) + archer.lua (single aimed shot).

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'archer'

  self.color = green[3]:clone()
  Set_Enemy_Shape(self, self.size)

  -- Physics/stats machinery rides on special_enemy; the separate spawn-budget
  -- identity (its own cap, independent of specials) is the category tag below.
  self.class = 'special_enemy'
  self.spawn_category = 'small_special'

  -- Positional turret: getting punted ruins the "post up and shoot" role.
  self.knockback_immune = true
  self.stopChasingInRange = true

  -- Drives its own approach to a fixed park point near its spawn, so it must
  -- not be force-seeked toward the player (see Unit:pick_action holds_position).
  self.holds_position = true

  -- Long action timer so the single approach runs uninterrupted until arrival
  -- (update_move_seek_to_range returns false on arrival, flipping to idle), and
  -- no idle gap so it starts moving the instant it spawns.
  self.baseActionTimer = 30
  self.baseIdleTimer = 0
  self.move_option_weight = 0

  self.attack_range = attack_ranges['big-archer']
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  -- Park point: spawn position pulled just inside the arena edge it came from,
  -- so it posts up close to where it spawned rather than charging the player.
  local margin = 45
  self.park_point = {
    x = math.clamp(self.x, margin, gw - margin),
    y = math.clamp(self.y, margin, gh - margin),
  }
  -- Make the SEEK_TO_RANGE approach target the fixed park point instead of a
  -- player-relative range.
  self.acquire_target_seek_to_range = function(self)
    self.target_location = self.park_point
    return true
  end

  -- One positioning move, then nothing but attacks (stationary turret).
  self.moves_left = 1
  self.custom_action_selector = function(self, viable_attacks, viable_movements)
    if self.attack_cooldown_timer > 0 then return 'retry', nil end
    if self.moves_left > 0 then
      self.moves_left = self.moves_left - 1
      return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE
    else
      return 'attack', random:table(viable_attacks)
    end
  end

  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    oncast = function()
      self.target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies)
    end,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = SingleProjectile,
    spelldata = {
      group = main.current.main,
      color = green[3],
      width = 16,
      height = 4,
      damage = function() return self.dmg end,
      v = 70,  -- medium-slow
      unit = self,
      source = 'small_archer',
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['small_archer'] = fns

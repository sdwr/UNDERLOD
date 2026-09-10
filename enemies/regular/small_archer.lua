-- Small Archer: the first "small-special" — a squishy ranged poke unit. Spawns
-- offscreen, makes one approach toward the perimeter (SEEK_TO_RANGE at a large
-- radius so it posts up near the edge rather than in the player's face), then
-- fires a single aimed projectile every few seconds, stepping toward the arena
-- middle between shots until it reaches an inner ring. Cast animation windup,
-- no targeting line, medium-slow projectile.
-- Modeled on orb.lua (approach-then-turret) + archer.lua (single aimed shot).

-- Between-shot hop: distance stepped toward the arena center after each shot,
-- and how close to the center the archer will creep before holding.
SMALL_ARCHER_HOP_STEP = 30
SMALL_ARCHER_MIN_CENTER_DIST = 70
-- Cap on a hop so a blocked archer still shoots on cooldown.
SMALL_ARCHER_HOP_TIMER = 2.5

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

  -- Next park point one hop toward the arena center, stopping on the inner
  -- ring. nil when already there.
  self.next_hop_point = function(self)
    local cx, cy = gw / 2, gh / 2
    local dist = math.distance(self.x, self.y, cx, cy)
    if dist <= SMALL_ARCHER_MIN_CENTER_DIST + DISTANCE_TO_TARGET_FOR_IDLE then return nil end
    local step = math.min(SMALL_ARCHER_HOP_STEP, dist - SMALL_ARCHER_MIN_CENTER_DIST)
    local angle = math.atan2(cy - self.y, cx - self.x)
    return {
      x = math.clamp(self.x + math.cos(angle) * step, margin, gw - margin),
      y = math.clamp(self.y + math.sin(angle) * step, margin, gh - margin),
    }
  end

  -- One positioning move, then alternate: shoot, hop toward the middle while
  -- the shot cools down, shoot again.
  self.moves_left = 1
  self.hop_pending = false
  self.custom_action_selector = function(self, viable_attacks, viable_movements)
    if self.attack_cooldown_timer > 0 then
      if self.hop_pending then
        self.hop_pending = false
        local hop = self:next_hop_point()
        if hop then
          self.park_point = hop
          self.baseActionTimer = SMALL_ARCHER_HOP_TIMER
          return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE
        end
      end
      return 'retry', nil
    end
    if self.moves_left > 0 then
      self.moves_left = self.moves_left - 1
      return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE
    elseif #viable_attacks > 0 then
      self.hop_pending = true
      return 'attack', random:table(viable_attacks)
    end
    return 'retry', nil
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

-- Pulsar: miniboss-style special. A big yellow circle with orbs rotating
-- around it that walks onscreen, parks, and fires 4-projectile volleys along
-- fixed compass axes - cardinals, then diagonals, alternating. Reuses orb's
-- OrbBurst: with projectile_count = 4 each burst advances spin_angle by pi/4,
-- which IS the cardinal/diagonal alternation. 4x tank hp (see
-- enemy_type_to_stats). One spawns per configured level via a scheduled
-- special event (see LEVEL_SPAWN_POOLS).

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'pulsar'

  self.color = yellow[5]:clone()
  Set_Enemy_Shape(self, self.size, 'circle')

  self.class = 'special_enemy'
  self.baseActionTimer = 30
  self.baseIdleTimer = 0
  self.move_option_weight = 0
  self.stopChasingInRange = true

  -- A miniboss-weight body shouldn't get punted around.
  self.knockback_immune = true

  -- Drives its own approach to a fixed park point near its spawn (see
  -- small_archer); must not be force-seeked toward the player.
  self.holds_position = true

  self.attack_range = 400
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  -- Park point: spawn position pulled well inside the arena edge it came
  -- from - one walk onscreen, then it never moves again.
  local margin = 100
  self.park_point = {
    x = math.clamp(self.x, margin, gw - margin),
    y = math.clamp(self.y, margin, gh - margin),
  }
  self.acquire_target_seek_to_range = function(self)
    self.target_location = self.park_point
    return true
  end

  -- Once the approach finishes, freeze the body solid: a static collider
  -- can't be shoved by collisions or launched by anything.
  self.state_always_run_functions['always_run'] = function(self)
    if not self.parked and self.moves_left == 0 and self.state ~= unit_states['moving'] then
      self.parked = true
      if self.body then self.body:setType('static') end
    end
  end

  -- spin_angle starts at 0 so the first volley is exactly N/E/S/W; OrbBurst
  -- advances it pi/4 per volley (cardinals <-> diagonals). cosmetic_spin is
  -- visual only and never touches the firing angles.
  self.spin_angle = 0
  self.spin_speed = math.pi * 0.4

  -- One positioning move, then stationary compass turret (same as orb).
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
  local volley = {
    name = 'volley',
    viable = function() return Helper.Target:get_random_enemy(self) end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = OrbBurst,
    spelldata = {
      group = main.current.main,
      color = yellow[5],
      damage = function() return self.dmg end,
      speed = 75,
      projectile_count = 4,
      width = 14,
      height = 5,
      max_distance = 600,
      unit = self,
      source = 'pulsar',
    },
  }
  table.insert(self.attack_options, volley)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Orbiting dots spin continuously, walking or parked.
  local dt = love.timer.getDelta and love.timer.getDelta() or 0
  self.cosmetic_spin = (self.cosmetic_spin or 0) + (self.spin_speed or 0) * dt

  -- Eight perimeter orbs (twice the orb's four - it's the bigger sibling).
  local body_size = (self.shape and self.shape.w or 30) / 2
  local r = body_size + 5
  for i = 0, 7 do
    local a = (self.spin_angle or 0) + (self.cosmetic_spin or 0) + (i * math.pi / 4)
    local px = self.x + math.cos(a) * r
    local py = self.y + math.sin(a) * r
    graphics.circle(px, py, 2, yellow[5])
  end
end

enemy_to_class['pulsar'] = fns

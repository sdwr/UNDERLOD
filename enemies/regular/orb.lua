local fns = {}

-- Burst spell that fires N evenly-spaced projectiles around the orb. Reads
-- the unit's spin_angle so consecutive bursts paint a rotating sunburst.
-- Defined at file scope so the attack_options table can reference the class.
OrbBurst = Object:extend()
OrbBurst.__class_name = 'OrbBurst'
OrbBurst:implement(GameObject)
function OrbBurst:init(args)
  self:init_game_object(args)
  self.projectile_count = self.projectile_count or 8
  local base = (self.unit and self.unit.spin_angle) or 0
  local step = 2 * math.pi / self.projectile_count
  for i = 0, self.projectile_count - 1 do
    local angle = base + (i * step)
    EnemyProjectile{
      group = self.group,
      x = self.x, y = self.y,
      r = angle,
      v = self.speed,
      damage = self.damage,
      color = self.color,
      width = self.width or 12,
      height = self.height or 4,
      max_distance = self.max_distance,
      unit = self.unit,
      source = 'orb',
    }
  end
  -- Rotate the next burst by half a sector so consecutive shots fill in the
  -- gaps between the previous ones - "rotating turret" effect.
  if self.unit then
    self.unit.spin_angle = (self.unit.spin_angle or 0) + step * 0.5
  end
  self:die()
end
function OrbBurst:update(dt) end
function OrbBurst:draw() end
function OrbBurst:die() self.dead = true end


fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'orb'

  self.color = yellow[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  -- Long action timer so the approach SEEK_TO_RANGE runs uninterrupted until
  -- the orb actually arrives (update_move_seek_to_range returns false at
  -- arrival, which still flips to idle naturally).
  self.baseActionTimer = 30
  -- No idle gap between picking actions: orb starts moving the instant it
  -- spawns instead of standing still for the default 0.3s.
  self.baseIdleTimer = 0
  self.move_option_weight = 0
  self.stopChasingInRange = true

  -- No knockback - orb is a positional threat; getting punted ruins the
  -- "approach then become a turret" pattern.
  self.knockback_immune = true

  -- Long attack range so the 8-direction burst can sweep most of the arena.
  -- seek_to_range_radius parks the orb just inside the arena rather than
  -- right next to the player so its radial pattern has good coverage.
  self.attack_range = 400
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)
  self.seek_to_range_radius = 220

  -- Visible rotation: increments while alive (purely cosmetic) AND bumps each
  -- burst's angle by half a sector so consecutive bursts interleave.
  self.spin_angle = 0
  self.spin_speed = math.pi * 0.6

  -- Approach pattern: one positioning move, then nothing but attacks. After
  -- arrival the orb becomes a stationary radial turret.
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
  local burst = {
    name = 'burst',
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
      speed = 90,
      projectile_count = 8,
      width = 12,
      height = 4,
      max_distance = 500,
      unit = self,
      source = 'orb',
    },
  }
  table.insert(self.attack_options, burst)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Continuous cosmetic spin only while stationary (idle / stopped / casting
  -- / channeling). During movement the dots are frozen so it reads as
  -- "approaching" vs "winding up another burst".
  if self.state ~= unit_states['moving'] then
    local dt = love.timer.getDelta and love.timer.getDelta() or 0
    self.cosmetic_spin = (self.cosmetic_spin or 0) + (self.spin_speed or 0) * dt
  end

  -- Four perimeter dots. Base angle = spin_angle (the burst angle, which
  -- only jumps by exactly half a sector per OrbBurst so consecutive bursts
  -- bisect the previous ones cleanly). cosmetic_spin adds visible rotation
  -- without affecting where the next burst fires.
  local body_size = (self.shape and self.shape.w or 18) / 2
  local r = body_size + 4
  for i = 0, 3 do
    local a = (self.spin_angle or 0) + (self.cosmetic_spin or 0) + (i * math.pi / 2)
    local px = self.x + math.cos(a) * r
    local py = self.y + math.sin(a) * r
    graphics.circle(px, py, 1.6, yellow[5])
  end
  -- Windup ring is drawn by the shared Unit:draw_cast_timer.
end

enemy_to_class['orb'] = fns

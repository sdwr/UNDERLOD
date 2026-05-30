-- Slime: a special enemy that crosses the arena center on a straight path,
-- leaves a purple slime trail behind, and stops periodically while fully
-- on-screen to fire an 8-way projectile pulse. Projectiles fade out over
-- their 125-unit travel and then vanish.

-- ============================================================================
-- SlimeBullet: a single radial projectile from the slime pulse. Fades alpha
-- linearly across its 125-unit lifetime and dies on impact or at max range.
-- ============================================================================
SlimeBullet = Object:extend()
SlimeBullet.__class_name = 'SlimeBullet'
SlimeBullet:implement(GameObject)
SlimeBullet:implement(Physics)
function SlimeBullet:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 4
  self.shape = Circle(self.x, self.y, self.radius)

  self.base_alpha = 0.85
  self.color = (self.color or purple[0]):clone()
  self.color.a = self.base_alpha

  self.damage = get_dmg_value(self.damage)

  self.start_distance = self.distance or 125
  self.distance = self.start_distance
  self.speed = self.speed or 50
  self.r = self.r or 0
  self:set_angle(self.r)
end

function SlimeBullet:update(dt)
  self:update_game_object(dt)
  self:check_hits()

  local prev_x, prev_y = self.x, self.y
  self.x = self.x + self.speed * math.cos(self.r) * dt
  self.y = self.y + self.speed * math.sin(self.r) * dt
  self.shape:move_to(self.x, self.y)

  local moved = math.sqrt((self.x - prev_x)^2 + (self.y - prev_y)^2)
  self.distance = self.distance - moved

  -- Linear fade from base_alpha down to 0 across the full travel.
  local t = math.max(0, self.distance / self.start_distance)
  self.color.a = self.base_alpha * t

  if self.distance <= 0 then
    self:die()
  end
  if self.x < 0 or self.x > gw or self.y < 0 or self.y > gh then
    self:die()
  end
end

function SlimeBullet:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  if #friendlies > 0 then
    friendlies[1]:hit(self.damage, self.unit, nil, true, true)
    self:die()
  end
end

function SlimeBullet:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  graphics.circle(self.x, self.y, self.shape.rs, self.color)
  graphics.pop()
end

function SlimeBullet:die()
  self.dead = true
end


-- ============================================================================
-- SlimePulse: an instant-cast "spell" that fires 8 SlimeBullets in a radial
-- pattern from the slime's location, then dies. Used as the slime's
-- attack_options spellclass so it slots into the regular cast/cooldown system.
-- ============================================================================
SlimePulse = Object:extend()
SlimePulse.__class_name = 'SlimePulse'
SlimePulse:implement(GameObject)
function SlimePulse:init(args)
  self:init_game_object(args)

  local num_pieces = 8
  local angle_between = 2 * math.pi / num_pieces
  for i = 1, num_pieces do
    local angle = (i - 1) * angle_between
    SlimeBullet{
      group = self.group,
      color = purple[0],
      x = self.x,
      y = self.y,
      r = angle,
      speed = 50,
      distance = 125,
      damage = self.damage,
      unit = self.unit,
    }
  end

  -- Audible feedback. wizard1 is the existing "pulse" sound used by swarmer
  -- poison; works well for a slime/sludge theme too.
  if wizard1 then
    wizard1:play{pitch = random:float(0.85, 1.0), volume = 0.4}
  end

  self.dead = true
end

function SlimePulse:update(dt) end
function SlimePulse:draw() end


-- ============================================================================
-- Slime enemy
-- ============================================================================
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

  -- Re-pick actions a little less often than the default so the slime spends
  -- meaningful time moving between pulses, but not so long that it feels idle.
  self.baseIdleTimer = 0.4
  self.baseActionTimer = 2.0

  -- Slime walks straight through the arena center. Set explicitly so the
  -- default action picker offers path-across without seek-fallbacks.
  self.movement_options = {MOVEMENT_TYPE_PATH_ACROSS}

  -- 8-way pulse, only while fully on-screen. The casting state freezes the
  -- slime (Enemy:update zeros velocity for casting/channeling/stopped) which
  -- gives us the "stops to pulse" beat for free.
  self.attack_options = {
    {
      name = 'slime_pulse',
      viable = function(unit) return unit.fully_onscreen end,
      oncast = function(unit) end,
      instantspell = true,
      spellclass = SlimePulse,
      spelldata = {
        group = main.current.main,
        damage = function() return self.dmg end,
        parent = self,
      },
      rotation_lock = true,
    },
  }

  -- Purple slime trail: drop a poison floor pool behind the slime every ~0.4s.
  -- Visually identical to the purple swarmer's poison (same Area_Spell config),
  -- with a slightly smaller radius than before and a 15s decay so pools linger
  -- through more of the level.
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
      duration = 15,
      pick_shape = 'circle',
      parent = self,
      floor_effect = 'poison',
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

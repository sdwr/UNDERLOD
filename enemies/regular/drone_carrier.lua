-- Drone Carrier: drifts around the arena and periodically deploys 1-2
-- short-lived homing drones that seek the nearest troop. Distinct from
-- spawner (which spawns persistent critters) and turret (which fires
-- straight projectiles) — drones home with a limited turn rate, so they
-- feel like a soft area-denial threat rather than a sniper bullet.

-- ============================================================================
-- HomingDrone: a slow seeking projectile with limited turn rate and a fixed
-- lifetime. Hits a troop on contact, then pops. Coded after SlimeBullet
-- (slime.lua) but with target tracking instead of straight-line travel.
-- ============================================================================
HomingDrone = Object:extend()
HomingDrone.__class_name = 'HomingDrone'
HomingDrone:implement(GameObject)
HomingDrone:implement(Physics)
function HomingDrone:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 3.5
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = (self.color or blue[5]):clone()
  self.color.a = 0.95

  self.damage = get_dmg_value(self.damage)

  self.speed = self.speed or 80
  -- Lifetime instead of max-distance — homing path length is unpredictable.
  self.lifetime = self.lifetime or 4
  self.turn_rate = self.turn_rate or 2.4 -- radians/sec; slow enough to dodge

  -- Initial heading: toward the target if we have one, else random.
  if self.target and self.target.x and self.target.y then
    self.r = math.atan2(self.target.y - self.y, self.target.x - self.x)
  else
    self.r = self.r or random:float(0, 2 * math.pi)
  end
  self:set_angle(self.r)
end

function HomingDrone:update(dt)
  self:update_game_object(dt)

  -- Re-pick target if ours died — keeps the drone useful through the run.
  -- Helper.Target:get_closest_enemy filters by fully_onscreen which troops
  -- never set (see helper_target.lua), so use get_random_enemy instead.
  if (not self.target or self.target.dead) and self.unit and not self.unit.dead then
    self.target = Helper.Target:get_random_enemy(self.unit)
  end

  -- Turn toward target with a capped rate so the player can sidestep.
  if self.target and not self.target.dead then
    local desired = math.atan2(self.target.y - self.y, self.target.x - self.x)
    local diff = desired - self.r
    while diff > math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    local max_step = self.turn_rate * dt
    if diff > max_step then diff = max_step
    elseif diff < -max_step then diff = -max_step end
    self.r = self.r + diff
  end

  self.x = self.x + self.speed * math.cos(self.r) * dt
  self.y = self.y + self.speed * math.sin(self.r) * dt
  self.shape:move_to(self.x, self.y)

  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then self:die() end
  if self.x < -10 or self.x > gw + 10 or self.y < -10 or self.y > gh + 10 then
    self:die()
  end

  self:check_hits()
end

function HomingDrone:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  if #friendlies > 0 then
    local t = friendlies[1]
    t:hit(self.damage, self.unit, nil, true, true)
    if t.push and not t.dead then
      t:push(LAUNCH_PUSH_FORCE_ENEMY, self.r, nil, KNOCKBACK_DURATION_ENEMY)
    end
    self:die()
  end
end

function HomingDrone:draw()
  graphics.push(self.x, self.y, self.r)
  graphics.circle(self.x, self.y, self.shape.rs, self.color)
  -- Small trail tail for "drone" feel.
  local tail = self.color:clone()
  tail.a = 0.4
  graphics.circle(self.x - math.cos(self.r) * 4, self.y - math.sin(self.r) * 4, self.shape.rs * 0.6, tail)
  graphics.pop()
end

function HomingDrone:die()
  if self.dead then return end
  self.dead = true
end


-- ============================================================================
-- DroneDeploy: spawns 2 HomingDrones from the carrier's current location,
-- one per side, so the deploy reads as a "release" not a single shot.
-- ============================================================================
DroneDeploy = Object:extend()
DroneDeploy.__class_name = 'DroneDeploy'
DroneDeploy:implement(GameObject)
function DroneDeploy:init(args)
  self:init_game_object(args)
  local n = args.count or 2
  for i = 1, n do
    local side_angle = (i - 1) * (2 * math.pi / n) + random:float(-0.2, 0.2)
    local ox, oy = math.cos(side_angle) * 6, math.sin(side_angle) * 6
    HomingDrone{
      group = self.group,
      x = self.x + ox,
      y = self.y + oy,
      target = self.target,
      damage = self.damage,
      unit = self.unit,
      speed = 80,
      lifetime = 4,
    }
  end
  if scout1 then
    scout1:play{pitch = random:float(1.05, 1.2), volume = 0.5}
  end
  self.dead = true
end

function DroneDeploy:update(dt) end
function DroneDeploy:draw() end


-- ============================================================================
-- Drone Carrier enemy
-- ============================================================================
local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'goblin'

  self.color = blue[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Keeps a steady pace while deploying; bumping it out of position is fine
  -- (unlike sniper/pulse_walker) because drones use the target at fire time.
  self.baseIdleTimer = 0.4
  self.baseActionTimer = 2.5
  self.move_option_weight = 0.6
  self.stopChasingInRange = true

  -- Long sensor — the carrier doesn't need to be close; the drones close
  -- the distance. 450 covers most of the arena.
  self.attack_range = 450
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  self.attack_options = {}

  local deploy = {
    name = 'deploy_drones',
    viable = function() return Helper.Target:get_random_enemy(self) end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = DroneDeploy,
    spelldata = {
      group = main.current.main,
      damage = function() return self.dmg * 0.7 end,
      count = 2,
      unit = self,
    },
  }
  table.insert(self.attack_options, deploy)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Cast ring during deploy windup, similar to roach but in blue.
  if self.state == unit_states['casting'] and self.castObject then
    local pct = self.castObject:get_cast_percentage() or 0
    graphics.circle(self.x, self.y, 4 + pct * 6, blue[5], 1)
  end
end

enemy_to_class['drone_carrier'] = fns

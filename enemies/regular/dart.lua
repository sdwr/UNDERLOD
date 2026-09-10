-- Dart: angular glass cannon. Seeks the nearest troop fast and straight,
-- ignoring other enemies (no separation either way), so it cuts through the
-- swarm, then explodes when it reaches a troop. Low hp so focused fire
-- deletes it first; a dart killed in flight does not explode.

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.color = orange[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  -- Other enemies don't steer away from it (see Enemy:init comparator).
  self.passes_through = true
  self.stopChasingInRange = false
  self.haltOnPlayerContact = false
  self.baseIdleTimer = 0
  self.baseActionTimer = 2

  self.attack_sensor = Circle(self.x, self.y, 500)
  self.attack_options = {}

  -- Detonate just before the bodies touch, so it never bumps the troop.
  self.trigger_radius = 22
  self.explosion_radius = 40
  self.exploded = false
  self.area_sensor = Circle(self.x, self.y, self.trigger_radius)
  self.state_always_run_functions['always_run'] = function(self)
    if self.exploded or self.dead then return end
    for _, friendly in ipairs(self:get_objects_in_shape(self.area_sensor, main.current.friendlies)) do
      if not friendly.dead then
        self:explode()
        break
      end
    end
  end
end

fns['explode'] = function(self)
  self.exploded = true
  explosion_new:play{pitch = random:float(1.1, 1.2), volume = 0.6}
  Area{
    group = main.current.effects,
    unit = self,
    x = self.x,
    y = self.y,
    r = self.explosion_radius,
    pick_shape = 'circle',
    duration = 0.15,
    dmg = self.dmg,
    is_troop = false,
    color = orange[0]
  }
  self:die()
end

-- Straight seek: no wander, no separation.
fns['update_move_seek'] = function(self)
  if not self.target then return false end
  self:seek_point(self.target.x, self.target.y, SEEK_DECELERATION, get_seek_weight_by_enemy_type(self.type))
  self:rotate_towards_velocity(1)
  return true
end

-- Elongated kite along the heading: nose ahead, short tail, narrow wings.
-- Drawn in local space; Enemy's draw push applies the single rotation.
-- grow/line_width serve the status tint and curse outline passes.
fns['draw_body'] = function(self, color, grow, line_width)
  local g = grow or 0
  local nose, tail, wing = 13 + g, 6 + g, 4 + g
  local x, y = self.x, self.y
  graphics.polygon({x + nose, y, x, y + wing, x - tail, y, x, y - wing}, color, line_width)
end

fns['draw_enemy'] = function(self)
  if not self:draw_animation() then
    self:draw_fallback_animation()
  end
end

enemy_to_class['dart'] = fns

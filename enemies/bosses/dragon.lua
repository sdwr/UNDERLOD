

local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'boss'

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --add hitbox points
  self.hitbox_points_can_rotate = true
  Helper.Unit:add_point(self, 32, 0)
  Helper.Unit:add_point(self, -15, 27)
  Helper.Unit:add_point(self, -15, -27)
  Helper.Unit:add_point(self, 23, 5)
  Helper.Unit:add_point(self, 23, -5)
  Helper.Unit:add_point(self, 16, 9)
  Helper.Unit:add_point(self, 16, -9)
  Helper.Unit:add_point(self, 10, 12)
  Helper.Unit:add_point(self, 10, -12)
  Helper.Unit:add_point(self, -9, 23)
  Helper.Unit:add_point(self, -9, -23)
  Helper.Unit:add_point(self, -3, 19)
  Helper.Unit:add_point(self, -3, -19)
  Helper.Unit:add_point(self, 3, 16)
  Helper.Unit:add_point(self, 3, -16)
  Helper.Unit:add_point(self, -16, 21)
  Helper.Unit:add_point(self, -16, -21)
  Helper.Unit:add_point(self, -16, 14)
  Helper.Unit:add_point(self, -16, -14)
  Helper.Unit:add_point(self, -16, 6)
  Helper.Unit:add_point(self, -16, -6)
  Helper.Unit:add_point(self, -16, 0)
  Helper.Unit:add_point(self, -9, 16)
  Helper.Unit:add_point(self, -9, -16)
  Helper.Unit:add_point(self, -9, 7)
  Helper.Unit:add_point(self, -9, -7)
  Helper.Unit:add_point(self, -9, 0)
  Helper.Unit:add_point(self, -2, 11)
  Helper.Unit:add_point(self, -2, -11)
  Helper.Unit:add_point(self, -2, 3)
  Helper.Unit:add_point(self, -2, -3)
  Helper.Unit:add_point(self, 5, 8)
  Helper.Unit:add_point(self, 5, -8)
  Helper.Unit:add_point(self, 5, -0)
  Helper.Unit:add_point(self, 10, 4)
  Helper.Unit:add_point(self, 10, -4)
  Helper.Unit:add_point(self, 18, -3)
  Helper.Unit:add_point(self, 18, 3)
  Helper.Unit:add_point(self, 25, 0)
  
  --set physics 
    self:set_restitution(0.1)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    self.class = 'boss'

  --set attacks
  self.fireDmg = 5
  self.fireDuration = 3
  self.fireRange = 100

  self.fireSweepRange = 200
  
  self.attack_options = {}
  local fire = {
    name = 'fire',
    viable = function() return Helper.Spell:there_is_target_in_range(self, 100) end,
    casttime = 0.5,
    oncaststart = function() turret_hit_wall2:play{volume = 0.9} end,
    cast = function()
      print('starting fire cast')
      Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
      Helper.Spell.Flame:create(Helper.Color.orange, 60, 100, self.fireDmg, self)
      self.state = unit_states['frozen']
      Helper.Spell.Flame:end_flame_after(self, self.fireDuration)
    end,
  }

  local fire_sweep = {
    name = 'fire_sweep',
    viable = function() return true end,
    casttime = 1,
    oncaststart = function() turret_hit_wall2:play{volume = 0.9} end,
    cast = function()
      print('starting fire sweep cast')
      --pick a random target, then rotate in a direction
      local target = Helper.Spell:get_random_target_in_range(self, self.fireSweepRange)
      if not target then target = Helper.Spell:get_nearest_target(self) end
      Helper.Unit:claim_target(self, target)
      Helper.Spell.Flame:create(Helper.Color.orange, 30, self.fireSweepRange, self.fireDmg, self, false)
      self.state = unit_states['frozen']
      Helper.Spell.Flame:end_flame_after(self, self.fireDuration)
    end, 
  }

  table.insert(self.attack_options, fire)
  table.insert(self.attack_options, fire_sweep)

  self.state_always_run_functions['always_run'] = function()
      self.hitbox_points_rotation = math.deg(self:get_angle())
  end

  self.state_change_functions['target_death'] = function()
  end

    self.state_change_functions['death'] = function()
      Helper.Spell.Flame:end_flame_after(self, 0)
  end
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
    graphics.polygon(points, self.color)
    graphics.pop()
end

enemy_to_class['dragon'] = fns
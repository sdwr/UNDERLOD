

local fns = {}

fns['init_enemy'] = function(self)
  --create shape
  self.color = red[0]:clone()
  self:set_as_rectangle(60, 60, 'dynamic', 'enemy')

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
  self.fireDuration = 2
  self.fireRange = 100

  self.state_always_run_functions['always_run'] = function()
      self.hitbox_points_rotation = math.deg(self:get_angle())

      if Helper.Spell:there_is_target_in_range(self, 100) 
      and Helper.Time.time - self.last_attack_finished > 1 then
          Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
          Helper.Spell.Flame:create(Helper.Color.orange, 60, 100, self.fireDmg, self)
          Helper.Spell.Flame:end_flame_after(self, self.fireDuration)
        end
      
      if self.my_target() and not Helper.Spell:target_is_in_range(self, 100) then
          Helper.Spell.Flame:end_flame_after(self, 0.25)
          Helper.Unit:unclaim_target(self)
      end
  end

  self.state_change_functions['target_death'] = function()
      Helper.Spell.Flame:end_flame_after(self, 0.25)
      Helper.Unit:unclaim_target(self)
  end

    self.state_change_functions['death'] = function()
      Helper.Spell.Flame:end_flame_after(self, 0)
      Helper.Unit:unclaim_target(self)
  end
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    local points = self:make_regular_polygon(3, (self.shape.w / 2) / 60 * 70, self:get_angle())
    graphics.polygon(points, self.color)
    graphics.pop()
end

enemy_to_class['dragon'] = fns
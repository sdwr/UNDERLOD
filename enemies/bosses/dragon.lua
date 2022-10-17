

local fns = {}

fns['init_enemy'] = function(self)

  --create shape
  self.color = red[0]:clone()
  self:set_as_rectangle(70, 70, 'dynamic', 'enemy')
  
  --set physics 
    self:set_restitution(0.1)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    self.class = 'boss'

  --set attacks
  self.fireDmg = 5
  self.fireDuration = 2
  self.fireRange = 100

  self.state_always_run_functions['always_run'] = function()
      if Helper.Spell:there_is_target_in_range(self, 100) 
      and Helper.Time.time - self.last_attack_finished > 1 then
          Helper.Unit:claim_target(self, Helper.Spell:get_nearest_target(self))
          Helper.Spell.Flame.create(Helper.Color.orange, 60, 100, self.fireDmg, self)
          Helper.Spell.Flame.end_flame_after(self, self.fireDuration)
        end
      
      if self.have_target and not Helper.Spell:claimed_target_is_in_range(self, 115) then
          Helper.Spell.Flame.end_flame_after(self, 0.25)
          Helper.Unit:unclaim_target(self)
      end
  end

  self.state_change_functions['target_death'] = function()
      Helper.Spell.Flame.end_flame_after(self, 0.25)
      Helper.Unit:unclaim_target(self)
  end

    self.state_change_functions['death'] = function()
      Helper.Spell.Flame.end_flame_after(self, 0)
      Helper.Unit:unclaim_target(self)
  end
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    local points = self:make_regular_polygon(3, self.shape.w / 2, self:get_angle())
    graphics.polygon(points, self.color)
    graphics.pop()
end

enemy_to_class['dragon'] = fns
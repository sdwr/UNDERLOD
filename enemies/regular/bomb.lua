
--needs new sound, louder
--flashing red light when triggered
-- and a speed adjustment?

--other options:
--delayed explosion after death (would need to drop a bomb object)
--stops moving when triggered, or for last second of life (easier to dodge)
--could have it move faster that way

--best is probably move faster when triggered, and explode after death
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set variables
  self.triggered = false
  self.exploded = false
  self.trigger_radius = 40
  self.time_to_explode = 3
  self.explosion_radius = 45
  self.explosion_damage = 100 
  self.area_sensor = Circle(self.x, self.y, self.trigger_radius)

  self.beep_times = {2, 1, 0.75, 0.5, 0.25}

  --explode on death
  self.state_change_functions['death'] = function()
    if not self.exploded then
      self:explode()
    end
  end

  --set bomb behavior
  self.state_always_run_functions['always_run'] = function()
    if self.triggered then
      self:try_to_beep()
      self.time_to_explode = self.time_to_explode - Helper.Time.delta_time
      if self.time_to_explode <= 0 then
        self:explode()
      end
    else
      --check for friendlies in range
      local friendlies = self:get_objects_in_shape(self.area_sensor, main.current.friendlies)
      for i, friendly in ipairs(friendlies) do
        if not friendly.dead then
          self.triggered = true
          break
        end
      end
    end
  end

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

fns['try_to_beep'] = function(self)
  if #self.beep_times > 0 and self.time_to_explode < self.beep_times[1] then
    alert1:play{pitch = random:float(0.95, 1.05), volume = 1.2}
    table.remove(self.beep_times, 1)
  end
end

fns['explode'] = function(self)
  self.exploded = true
  cannoneer2:play{pitch = random:float(0.95, 1.05), volume = 0.8}
  Helper.Spell.DamageCircle:create(self, Helper.Color.red, true,
    self.explosion_damage, self.explosion_radius, self.x, self.y)
  self:die()
end

enemy_to_class['bomb'] = fns
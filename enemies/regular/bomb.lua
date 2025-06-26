
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

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  --set variables
  self.triggered = false
  self.exploded = false
  self.trigger_radius = 40
  self.time_to_explode = 4
  self.explosion_radius = 45
  self.explosion_damage = 100 
  self.area_sensor = Circle(self.x, self.y, self.trigger_radius)

  --first beep is a different sound
  self.beep_times = {3, 2, 1.5, 1, 0.5}

  --explode on death
  self.state_change_functions['death'] = function(self)
    if not self.exploded then
      self:explode()
    end
  end

  --set bomb behavior
  self.state_always_run_functions['always_run'] = function(self)
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
          metal_click:play{pitch = random:float(0.95, 1.05), volume = 1.2}
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
    table.remove(self.beep_times, 1)
    tick_new:play{pitch = random:float(0.95, 1.05), volume = 1.2}
    --draw transparent red circle to show where it will explode
    --under the bomb (floor level)
    Area{
      group = main.current.floor,
      unit = self,
      follow_unit = true,
      x = self.x,
      y = self.y,
      r = self.explosion_radius,
      pick_shape = 'circle',
      duration = 0.15,
      dmg = 0,
      is_troop = false,
      color = red[0]
    }

    
  end
end

fns['explode'] = function(self)
  self.exploded = true
  explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.8}
  Area{
    group = main.current.effects,
    unit = self,
    x = self.x,
    y = self.y,
    r = self.explosion_radius,
    pick_shape = 'circle',
    duration = 0.15,
    dmg = self.explosion_damage,
    is_troop = false,
    color = red[0]
  }
  self:die()
end

enemy_to_class['bomb'] = fns
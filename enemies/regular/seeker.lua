
local fns = {}
fns['attack'] = function(self, area, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = color or self.color, dmg = self.area_dmg_m*self.dmg,
    character = self.character, level = self.level, parent = self}

  self.state = unit_states['frozen']

  self.t:after(0.3, function() 
    self.state = unit_states['stopped']
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() self.state = unit_states['normal'] end, 'normal')
end

fns['init_enemy'] = function(self)
  --create shape
  self.color = grey[0]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
  self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:rotate_towards_object(closest_enemy, 1)
        fns['attack'](self, 30, {x = closest_enemy.x, y = closest_enemy.y})
      end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['seeker'] = fns
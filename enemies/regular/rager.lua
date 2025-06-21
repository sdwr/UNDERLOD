

local fns = {}

fns['attack'] = function(self, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(20), color = color or self.color, dmg = self.dmg,
    character = self.character, level = self.level, parent = self}

  Helper.Unit:set_state(self, unit_states['frozen'])

  self.t:after(0.3, function() 
    Helper.Unit:set_state(self, unit_states['stopped'])
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() Helper.Unit:set_state(self, unit_states['normal']) end, 'normal')

end

fns['init_enemy'] = function(self)

  --load extra data from variables
  self.data = self.data or {}
  self.size = self.data.size or 'big'


  --create shape
  self.color = red[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  --set attacks
  self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.attack_sensor, main.current.friendlies); return targets and #targets > 0 end, function()
      local closest_enemy = self:get_closest_object_in_shape(self.attack_sensor, main.current.friendlies)
      if closest_enemy then
        self:rotate_towards_object(closest_enemy, 1)
        fns['attack'](self, {x = closest_enemy.x, y = closest_enemy.y})
      end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['rager'] = fns

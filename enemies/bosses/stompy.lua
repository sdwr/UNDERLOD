

local fns = {}

fns['attack'] = function(self, area, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(area or 64), color = color or self.color, dmg = self.dmg,
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

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'boss'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
    self:set_restitution(0.1)
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
    self.class = 'boss'

  --set sensors
    self.attack_sensor = Circle(self.x, self.y, 80)

  --add hitbox points
  local step = (self.shape.w - 4) / 5
  for x = -self.shape.w/2 + 2, self.shape.w/2 - 2, step do
    for y = -self.shape.h/2 + 2, self.shape.h/2 - 2, step do
      if x == -self.shape.w/2 + 2 and y == -self.shape.h/2 + 2 then
        Helper.Unit:add_point(self, x + 2, y + 2)
      elseif x == -self.shape.w/2 + 2 and near(y, self.shape.h/2 - 2, 0.01) then
        Helper.Unit:add_point(self, x + 2, y - 2)
      elseif near(x, self.shape.w/2 - 2, 0.01) and y == -self.shape.h/2 + 2 then
        Helper.Unit:add_point(self, x - 2, y + 2)
      elseif near(x, self.shape.w/2 - 2, 0.01) and near(y, self.shape.h/2 - 2, 0.01) then
        Helper.Unit:add_point(self, x - 2, y - 2)
      else
        Helper.Unit:add_point(self, x, y)
      end
    end
  end

  --set attacks
    self.t:cooldown(attack_speeds['ultra-slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function ()
        local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
        if target then
        self:rotate_towards_object(target, 1)
        Mortar{group = main.current.main, unit = self, team = "enemy", target = target, rs = 25, color = red[0], dmg = 30, level = self.level, parent = self}
        end
    end, nil, nil, 'shoot')
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target and self.state == unit_states['normal'] end, function()
        Stomp{group = main.current.main, unit = self, team = "enemy", x = self.x, y = self.y, rs = self.attack_sensor.rs, color = red[0], dmg = 50, level = self.level, parent = self}
    end, nil, nil, 'stomp')
    self.t:cooldown(attack_speeds['fast'], function() local targets = self:get_objects_in_shape(self.aggro_sensor, main.current.friendlies); return targets and #targets > 0 and self.state == unit_states['normal'] end, function()
        local closest_enemy = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
        self.target = closest_enemy

        if self:in_range()() then
        self:rotate_towards_object(closest_enemy, 1)
        fns['attack'](self, 20, {x = closest_enemy.x, y = closest_enemy.y})
        end
    end, nil, nil, 'attack')
end

fns['draw_enemy'] = function(self)   
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
end

enemy_to_class['stompy'] = fns
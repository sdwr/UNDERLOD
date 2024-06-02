
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = blue2[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'
  
  self.cast_time = 0

  --set attacks
    self.t:cooldown(attack_speeds['medium-slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        sniper_load:play{volume=0.9}
        Helper.Spell.SpreadMissile:create(Helper.Color.blue, 10, self.dmg, self, 25, true) 
        end
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['spread'] = fns
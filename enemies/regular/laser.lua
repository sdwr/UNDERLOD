
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'
  self.tracks = self.data.tracks or false

  --create shape
  self.color = blue[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set special attrs
  --castTime is what is used to determine the spell duration 
  -- and is set to a default if baseCast is not set
  self.baseCast = attack_speeds['medium-fast']

  --set attacks
    self.t:cooldown(attack_speeds['slow'], function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end, function ()
      local target = Helper.Spell:get_furthest_target(self)
      if target then
        self:rotate_towards_object(target, 1)
        Helper.Unit:claim_target(self, target)
        self.state = unit_states['casting']
        Helper.Spell.Laser:create(Helper.Color.blue, 7, true, self.dmg, self, nil, nil)
        end
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['laser'] = fns
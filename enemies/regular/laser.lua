
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'
  self.tracks = self.data.tracks or false

  --set mega variant
  --self.mega = self.data.mega or false
  self.mega = true

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

  self.castcooldown = attack_speeds['medium']

  self.direction_lock = true
  self.rotation_lock = false

  if self.mega then
    self.baseCast = attack_speeds['fast']
    self.castcooldown = attack_speeds['medium-fast']
    self.direction_lock = false
    self.rotation_lock = true
  end

  --set attacks

  --laser has stuff happen during the cast (in prelist)
  --so can't use the normal cast function
  --the laser helper spell has to be split into two parts
  -- so that the laser can be drawn before the cast is finished
  -- and the spell can be cancelled properly if the unit dies or is stunned
  self.attack_options = {}
  local laser = {
    name = 'laser',
    viable = function() local target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies); return target end,
    casttime = self.castTime,
    freezeduration = 0.4,
    castcooldown = self.castcooldown,
    oncaststart = function()
      local target = Helper.Spell:get_furthest_target(self)
      if target then
        self:rotate_towards_object(target, 1)
        Helper.Unit:claim_target(self, target)
        self.state = unit_states['casting']
        local args = {
          unit = self,
          direction_lock = self.direction_lock,
          rotation_lock = self.rotation_lock,
          laser_aim_width = 8,
          damage = self.dmg,
          damage_troops = true
        }
        

        Helper.Spell.Laser:create(args)
      end
    end,
    cast = function()
      if self.state == unit_states['casting'] then
        self.state = unit_states['normal']
      end
    end,
  }

  table.insert(self.attack_options, laser)
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['laser'] = fns
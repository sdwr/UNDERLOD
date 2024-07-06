
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

  self.direction_lock = false
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
    oncast = function() self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    castcooldown = self.castcooldown,
    cast_length = 0.1,
    hide_cast_timer = true,
    spellclass = Laser_Spell,
    --spell ends itself when firing, doesn't use duration
    spelldata = {
      group = main.current.main,
      unit = self,
      target = self.target,
      spell_duration = 10,
      color = blue[0],
      damage = self.dmg,
      lasermode = 'target',
      laser_aim_width = 6,
      damage_troops = true,
      damage_once = true,
      draw_spawn_circle = true,
      end_spell_on_fire = false,
      fire_follows_unit = false,
      fade_fire_draw = true,
      fade_in_aim_draw = true,
      lock_last_duration = 0.3
    },
  }

  table.insert(self.attack_options, laser)
end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['laser'] = fns
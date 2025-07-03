local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.tracks = self.data.tracks or false

  --set mega variant
  --self.mega = self.data.mega or false
  self.mega = true

  --create shape
  self.color = blue[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.single_animation = true
  self.icon = 'mech1'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set special attrs
  --castTime is what is used to determine the spell duration 
  -- and is set to a default if baseCast is not set
  self.baseCast = attack_speeds['medium']

  self.castcooldown = attack_speeds['medium-slow']

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
      damage = function() return self.dmg end,
      reduce_pierce_damage = true,
      lasermode = 'target',
      laser_aim_width = 6,
      damage_troops = true,
      damage_once = true,
      draw_spawn_circle = true,
      end_spell_on_fire = false,
      fire_follows_unit = false,
      fade_fire_draw = true,
      fade_in_aim_draw = true,
      lock_last_duration = 1.5,
      charge_duration = self.baseCast,
    },
  }

  table.insert(self.attack_options, laser)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end
 
enemy_to_class['laser'] = fns
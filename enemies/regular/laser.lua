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


  --set special attrs
  -- Attack speed now handled by base class
  
  self.direction_lock = false
  self.rotation_lock = false

  if self.mega then
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
    viable = function() return Helper.Target:get_random_enemy(self) end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,


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
      charge_duration = 1.0,
    },
  }

  table.insert(self.attack_options, laser)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['laser'] = fns

local fns = {}

fns['init_enemy'] = function(self)
  
  --set extra data from variables
  self.data = self.data or {}
  self.icon = 'slime'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'special_enemy'


  self.attack_options = {}

  local cleave = {
    name = 'cleave',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() end,
    instantspell = true,


    cast_sound = sword_swing,
    cast_volume = 1,
    backswing = 1,
    spellclass = Cleave,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      target = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
      cancel_on_death = true,
      damage = function() return self.dmg end,
      cone_radius = 50,
      cone_angle = math.pi/1.5,
      color = red[0],
      parent = self
    },
  }

  table.insert(self.attack_options, cleave)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end

end

enemy_to_class['cleaver'] = fns
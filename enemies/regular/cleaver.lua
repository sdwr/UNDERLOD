
local fns = {}

fns['init_enemy'] = function(self)
  
  --set extra data from variables
  self.data = self.data or {}
  self.size = self.data.size or 'big'
  self.icon = 'nil'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_SEEK

  self.base_mvspd = 40

  self.attack_options = {}

  local cleave = {
    name = 'cleave',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() end,
    instantspell = true,
    castcooldown = 2,
    cast_length = 0.2,
    spellclass = Cleave,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      target = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
      cancel_on_death = true,
      dmg = self.dmg or 20,
      cone_radius = 40,
      cone_angle = math.pi/3,
      color = red[0],
      parent = self
    },
  }

  table.insert(self.attack_options, cleave)

end

fns['draw_enemy'] = function(self)

  local animation_success = self:draw_animation(self.state, self.x, self.y, 0, 2, 2)

  if not animation_success then
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
  end

end

enemy_to_class['cleaver'] = fns
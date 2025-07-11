local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'ghost'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  self.baseCast = attack_speeds['medium']
  self:reset_castcooldown(self.baseCast)

  --set attacks
  self.attack_options = {}

  local snakearrows = {
    name = 'snakearrows',
    viable = function() return self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    castcooldown = self.castcooldown,
    oncast = function() self.target = self:get_random_object_in_shape(self.aggro_sensor, main.current.friendlies) end,
    freeze_rotation = true,
    rotation_lock = true,
    cast_length = GHOST_CAST_TIME,
    spellclass = SnakeArrows,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      damage = function() return self.dmg end,
      speed = 40,
      freeze_rotation = true,
      curve_depth = 25,
      curve_frequency = 1,
      arrow_interval = 1.5,
      color = purple[0],
      parent = self
    }
  }

  table.insert(self.attack_options, snakearrows)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end
 
enemy_to_class['snakearrow'] = fns 
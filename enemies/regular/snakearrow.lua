local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'ghost'


  -- Attack speed now handled by base class

  --set attacks
  self.attack_options = {}

  local snakearrows = {
    name = 'snakearrows',
    viable = function() return Helper.Target:get_random_enemy(self) end,

    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    freeze_rotation = true,
    rotation_lock = true,

    spellclass = SnakeArrows,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      num_arrows = 2,
      damage = function() return self.dmg end,
      speed = 55,
      freeze_rotation = true,
      arrow_interval = 1.1,
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
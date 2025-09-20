local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  self.class = 'special_enemy'
  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.icon = 'lich'


  -- Attack speed now handled by base class

  --set attacks

  self.attack_options = {}

  local burst = {
    name = 'burst',
    viable = function () return true end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,

    instantspell = true,

    spellclass = Burst,
    spelldata = {
      group = main.current.main,
      unit = self,
      spelltype = "targeted",
      accuracy = math.pi/4,
      target = self.target,
      x = self.x,
      y = self.y,
      color = purple[0],
      damage = function() return self.dmg end,
      speed = 70,
      num_pieces = 8,
      primary_explosion = true,
      parent = self
    }
  }

  table.insert(self.attack_options, burst)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['burst'] = fns
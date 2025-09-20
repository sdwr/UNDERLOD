local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  self.class = 'special_enemy'
  --create shape
  self.color = yellow[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.icon = 'ent'

  -- Attack speed now handled by base class

  self.stopChasingInRange = true

  --set attacks

  self.attack_options = {}

  local boomerang = {
    name = 'boomerang',
    viable = function () return true end,
    oncast = function() end,

    instantspell = true,

    spellclass = Boomerang,
    spelldata = {
      group = main.current.main,
      unit = self,
      team = "enemy",
      target = self.target,
      x = self.x,
      y = self.y,
      spelltype = "targeted",
      color = yellow[0],
      damage = function() return self.dmg end,
      speed = 75,
      distance = 300,
      parent = self
    }
  }

  table.insert(self.attack_options, boomerang)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  
  if not animation_success then
    self:draw_fallback_animation()
  end

end
 
enemy_to_class['boomerang'] = fns
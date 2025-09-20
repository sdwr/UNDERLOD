local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'rockslime'


  -- Attack speed now handled by base class

  --set attacks

  self.attack_options = {}

  local selfburst = {
    name = 'selfburst',
    viable = function () return true end,
    oncast = function() end,

    instantspell = true,

    spellclass = Burst,
    spelldata = {
      group = main.current.main,
      unit = self,
      spelltype = "not_targeted",
      x = self.x,
      y = self.y,
      color = brown[0],
      damage = function() return self.dmg end,
      speed = 0,  -- No movement speed
      distance = 0,  -- Explode immediately at own location
      duration = 1,
      num_pieces = 5,
      r = math.pi,
      primary_explosion = false,
      secondary_damage = function() return self.dmg end,
      secondary_distance = 120,
      secondary_speed = 80,
      parent = self
    }
  }

  table.insert(self.attack_options, selfburst)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['selfburst'] = fns 
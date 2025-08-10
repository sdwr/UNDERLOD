local fns = {}
fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = blue2[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'iceslime'


  --set attacks
  self.attack_options = {}

  local arcspread = {
    name = 'arcspread',
    viable = function () return true end,
    oncast = function() end,
    cast_sound = arcspread_full_sound,
    cast_sound_at_start = true,
    cast_volume = 0.8,

    instantspell = true,

    spellclass = Arcspread,
    spelldata = {
      group = main.current.main,
      unit = self,
      target = self.target,
      color = blue2[5],
      damage = function() return self.dmg end,
      pierce = 0,
      thickness = 2,
      numArcs = 4,

      speed = 40,
    }
  }

  table.insert(self.attack_options, arcspread)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end
 
enemy_to_class['arcspread'] = fns
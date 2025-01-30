
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set attacks

  self.attack_options = {}

  --spell ends after # of balls, not duration
  local plasma_barrage_straight = {
    name = 'plasma_barrage',
    viable = function () return true end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = 1,
    spellclass = Plasma_Barrage,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      cancel_on_death = true,
      spell_duration = 100,
      x = self.x,
      y = self.y,
      movement_type = 'straight',
      rotation_speed = 1,
      color = orange[-5],
      damage = 20,
      parent = self
    }
  }

  table.insert(self.attack_options, plasma_barrage_straight)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['plasma'] = fns
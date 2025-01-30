
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'small'

  --create shape
  self.color = brown[5]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics
  self.class = 'regular_enemy'

  self.maxSummons = 10
  self.summons = 0

  self.time_to_cast = 6

  self.state = unit_states['frozen']
  self.can_cast_while_frozen = true

  --set attacks
  self.attack_options = {}
  
  local summon = {
    name = 'summon',
    viable = function() return self.summons < self.maxSummons end,
    castcooldown = 3,
    oncast = function() end,
    cast_length = 0.1,
    spellclass = Summon_Spell,
    spelldata = {
      cancel_on_death = true,
      unit_dies_at_end = true,
      group = main.current.main,
      amount = 6,
      spell_duration = self.time_to_cast,
      rs = 15,
      color = brown[5],
    }
  }

  table.insert(self.attack_options, summon)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['dragonegg'] = fns


local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = purple[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set special attrs
    self.maxSummons = 2
    self.summons = 0
    self.aggro_sensor = Circle(self.x, self.y, 1)

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
      group = main.current.main,
      summonAmount = 4,
      spell_duration = 2,
      rs = 15,
      color = purple[3],
    }
  }

  table.insert(self.attack_options, summon)
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['summoner'] = fns

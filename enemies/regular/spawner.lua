
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'


  --set special attrs
  self.maxSummons = 10
  self.summons = 0

  --set attacks
  self.spawn_pos = {x = self.x, y = self.y}
  self.t:cooldown(attack_speeds['slow'], function() return self.state == 'normal' and self.summons < self.maxSummons end, function()
    Summon{group = main.current.main, team = 'enemy', type = 'enemy_critter', amount = 4, 
            x = self.x, y = self.y, rs = 15, castTime = 1, color = purple[5], level = self.level, parent = self}
  end, nil, nil, 'cast')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['spawner'] = fns

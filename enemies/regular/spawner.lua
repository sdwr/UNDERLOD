
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = purple[0]:clone()
  Set_Enemy_Shape(self, self.size)

  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  self:set_mass(SPECIAL_ENEMY_MASS)

  self.class = 'special_enemy'
  self.movementStyle = MOVEMENT_TYPE_RANDOM

  --set special attrs
  self.maxSummons = 10
  self.summons = 0
  self.aggro_sensor = Circle(self.x, self.y, 1)

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

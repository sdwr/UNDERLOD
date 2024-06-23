
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set attacks

  self.attack_options = {}

  local plasma_barrage = {
    name = 'plasma_barrage',
    viable = function () return true end,
    castcooldown = 2,
    cast = function()
      PlasmaBarrage{
        group = main.current.main,
        unit = self,
        team = "enemy",
        x = self.x,
        y = self.y,
        movement_type = 'spiral',
        rotation_speed = 1,
        color = orange[-5],
        num_balls = 10,
        damage = 20,
        parent = self
      }

    end
  }

  table.insert(self.attack_options, plasma_barrage)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['plasma'] = fns
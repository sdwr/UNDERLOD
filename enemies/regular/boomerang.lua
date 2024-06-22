
local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'big'

  --create shape
  self.color = yellow[0]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'special_enemy'

  --set attacks

  self.attack_options = {}

  local boomerang = {
    name = 'boomerang',
    viable = function () return true end,
    castcooldown = 3,
    cast = function()
      cannoneer1:play{volume=0.7}

      local r = 0
      if self.target then
        r = math.atan2(self.target.y - self.y, self.target.x - self.x)
      else
        r = math.random()*2*math.pi
      end

      local distance = 300

      Boomerang{
        group = main.current.main,
        unit = self,
        team = "enemy",
        target = self.target,
        x = self.x,
        y = self.y,
        r = r,
        color = yellow[0],
        damage = self.dmg,
        speed = 100,
        distance = distance,
        parent = self
      }
    end
  }

  table.insert(self.attack_options, boomerang)

end

fns['draw_enemy'] = function(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end
 
enemy_to_class['boomerang'] = fns
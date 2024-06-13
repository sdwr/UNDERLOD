

local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'heigan'

  --create shape
  self.color = orange[-2]:clone()
  Set_Enemy_Shape(self, self.size)
  
  --set physics 
  self:set_restitution(0.1)
  self:set_as_steerable(self.v, 1000, 2*math.pi, 2)
  self.class = 'boss'

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 80)

  --set attacks
  self.attack_options = {}

  local safety_dance = {
    name = 'safety_dance',
    viable = function () return true end,
    casttime = 1,
    cast = function()
      Helper.Spell.SafetyDance:create_all(self, orange[-5], true, 'one_safe', 4, 25)
    end
  }

  local laser_ball = {
    name = 'laser_ball',
    viable = function () return true end,
    casttime = 1,
    cast = function()
      LaserBall{
        group = main.current.main,
        unit = self,
        team = "enemy",
        x = self.x,
        y = self.y,
        color = orange[-5],
        damage = 20,
        parent = self
      }
    end
  }

  local quick_stomp = {
    name = 'quick_stomp',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    casttime = 1,
    cast = function()
      Stomp{
        group = main.current.main,
        unit = self,
        team = "enemy",
        x = self.x,
        y = self.y,
        color = orange[-5],
        rs = self.attack_sensor.rs,
        dmg = 50,
        parent = self,
      }
    end
  }

  table.insert(self.attack_options, safety_dance)
  table.insert(self.attack_options, laser_ball)
  table.insert(self.attack_options, quick_stomp)
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
end

enemy_to_class['heigan'] = fns
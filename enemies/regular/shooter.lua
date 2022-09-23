

local fns = {}

fns['shoot'] = function(self, r, mods)
  mods = mods or {}
  local t = {group = main.current.main, x = self.x, y = self.y, v = 175, r = r, color = self.color, dmg = self.dmg}
  self.hfx:use('shoot', 0.25)
  self.state = unit_states['frozen']

  self.t:after(0.4, function()
    self.state = unit_states['stopped']
    HitCircle{group = main.current.effects, x = self.x , y = self.y, rs = 6, duration = 0.1}
    EnemyProjectile(table.merge(t, mods or {}))
    
    end, 'stopped')
  self.t:after(0.4 + .4, function() self.state = unit_states['normal'] end, 'normal')

end

fns['init_enemy'] = function(self)

  --create shape
  self.color = grey[0]:clone()
  self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
  
  --set physics 
  self:set_restitution(0.5)
  self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  self.class = 'regular_enemy'

  --set attacks
    self.attack_sensor = Circle(self.x, self.y, 100)
    self.t:cooldown(attack_speeds['medium'], function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end, function ()
      local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies)
      if target then
        self:rotate_towards_object(target, 1)
        fns['shoot'](self, self:angle_to_object(target))
      end
    end, nil, nil, 'shoot')
end

fns['draw_enemy'] = function(self)   
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

enemy_to_class['shooter'] = fns


EnemyProjectile = Object:extend()
EnemyProjectile:implement(GameObject)
EnemyProjectile:implement(Physics)
function EnemyProjectile:init(args)
  self:init_game_object(args)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(10, 4, 'dynamic', 'enemy_projectile')
end


function EnemyProjectile:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
end


function EnemyProjectile:draw()
  graphics.push(self.x, self.y, self.r)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
  graphics.pop()
end


function EnemyProjectile:die(x, y, r, n)
  if self.dead then return end
  x = x or self.x
  y = y or self.y
  n = n or random:int(3, 4)
  for i = 1, n do HitParticle{group = main.current.effects, x = x, y = y, r = random:float(0, 2*math.pi), color = self.color} end
  HitCircle{group = main.current.effects, x = x, y = y}:scale_down()
  self.dead = true
  proj_hit_wall1:play{pitch = random:float(0.9, 1.1), volume = 0.05}
end


function EnemyProjectile:on_collision_enter(other, contact)
  local x, y = contact:getPositions()
  local nx, ny = contact:getNormal()
  local r = 0
  if nx == 0 and ny == -1 then r = -math.pi/2
  elseif nx == 0 and ny == 1 then r = math.pi/2
  elseif nx == -1 and ny == 0 then r = math.pi
  else r = 0 end

  if other:is(Wall) then
    self:die(x, y, r, random:int(2, 3))
  end
end


function EnemyProjectile:on_trigger_enter(other, contact)
  if other:is(Player) or other:is(Troop) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg)

  elseif other:is(Critter) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.dmg)

  elseif other:is(Enemy) or other:is(EnemyCritter) then
    if self.source == 'shooter' then
      self:die(self.x, self.y, nil, random:int(2, 3))
      other:hit(0.5*self.dmg, nil, nil, true)
    end
  end
end

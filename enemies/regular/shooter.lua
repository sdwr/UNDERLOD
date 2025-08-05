local fns = {}


fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'regular_enemy'
  self.icon = 'goblin'
  self.attack_sensor = Circle(self.x, self.y, attack_ranges['medium-long'])

  self.baseCooldown = attack_speeds['medium']
  self.cooldownTime = self.baseCooldown

  self.stopChasingInRange = true

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() local target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies); return target end,
    oncast = function() self.target = self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    cast_length = GOBLIN_CAST_TIME,
    castcooldown = self.cooldownTime,
    cancel_on_range = false,
    cancel_range = self.attack_sensor.rs * 1.1,
    instantspell = true,
    cast_sound = scout1,
    spellclass = ArrowProjectile,
    spelldata = {
      group = main.current.effects,
      color = blue[0],
      damage = function() return self.dmg end,
      bullet_size = 3,
      is_troop = false,
      speed = 120,
    },
  }
  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)   
  local animation_success = self:draw_animation()

  if not animation_success then
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    graphics.pop()
  end
end

enemy_to_class['shooter'] = fns


EnemyProjectile = Object:extend()
EnemyProjectile:implement(GameObject)
EnemyProjectile:implement(Physics)
function EnemyProjectile:init(args)
  self:init_game_object(args)

  self.width = args.width or 10
  self.height = args.height or 4

  self.damage = get_dmg_value(self.damage)
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  self:set_as_rectangle(self.width, self.height, 'dynamic', 'enemy_projectile')
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
  if other:is(Player) or other.is_troop then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.damage, self.unit)

  elseif other:is(Critter) then
    self:die(self.x, self.y, nil, random:int(2, 3))
    other:hit(self.damage, self.unit)

  elseif other:is(Enemy) or other:is(EnemyCritter) then
    if self.source == 'shooter' then
      self:die(self.x, self.y, nil, random:int(2, 3))
      other:hit(0.5*self.damage, self.unit)
    end
  end
end

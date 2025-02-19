function Get_Angle_For_Target(self)
  local target = self.target
  if not target and self.unit then
    target = self.unit:my_target()
  end

  if target then
    return math.atan2(self.target.y - self.y, self.target.x - self.x)
  else
    return math.random()*2*math.pi
  end
end

function Get_Distance_To_Target(self)
  local target = self.target
  if not target and self.unit then
    target = self.unit:my_target()
  end

  if target then
    return math.sqrt((self.target.y - self.y)^2 + (self.target.x - self.x)^2)
  else
    return 100
  end
end

Arrow = Object:extend()
Arrow:implement(GameObject)
Arrow:implement(Physics)
function Arrow:init(args)
  self:init_game_object(args)

  self.shape = Rectangle(self.x, self.y, self.r, self.r)
  
  self.damage = self.damage or 10
  self.speed = 400
  self.color = self.color or blue[0]
  self.unit = self.unit
  self.target = self.target
  self.x = self.unit.x
  self.y = self.unit.y
  
  self.r = self.bullet_size or 2
  
  alert1:play{volume=0.9}
end

function Arrow:update(dt)
  self:update_game_object(dt)
  
  if not self.target or self.target.dead or self.dead then
    self:die()
    return
  end

  local xdist = self.target.x - self.x
  local ydist = self.target.y - self.y
  local angle = math.atan2(ydist, xdist)
  self.x = self.x + math.cos(angle) * self.speed * dt
  self.y = self.y + math.sin(angle) * self.speed * dt


  self.shape:move_to(self.x, self.y)


  if math.distance(self.x, self.y, self.target.x, self.target.y) < 10 then
    hit2:play{volume=0.7}
    self.target:hit(self.damage, self.unit)
    self:die()
  end
end

function Arrow:draw()
  graphics.circle(self.x, self.y, self.r, self.color)
end

function Arrow:die()
  self.dead = true
end


Arcspread = Object:extend()
Arcspread:implement(GameObject)
Arcspread:implement(Physics)
function Arcspread:init(args)
  self:init_game_object(args)
  
  self.color = self.color or blue[2]

  self.damage = self.damage or 30
  self.pierce = self.pierce
  self.thickness = self.thickness or 1
  self.numArcs = self.numArcs or 4

  self.duration = self.spell_duration or 10

  self.width = self.width or math.pi/4
  self.speed = self.speed or 100
  self.radius = self.radius or 20
  self.duration = self.duration or 10

  self.grow = true
  
  
  self.angle = math.random(2*math.pi)


  self:create_arcs()
  self:die()
end

function Arcspread:create_arcs()
  for i = 1, self.numArcs do
    self.angle = self.angle + (2*math.pi / self.numArcs)
    for j = 0, self.thickness-1 do
      DamageArc{
        group = main.current.effects, 
        unit = self.unit,
        x = self.x, 
        y = self.y, 
        color = self.color, 
        pierce = self.pierce,
        damage = self.damage, 
        width = self.width, 
        angle = self.angle, 
        speed = self.speed, 
        radius = self.radius - (j*4),
        duration = self.duration,
        grow = self.grow,
      }
    end
  end
end

function Arcspread:update(dt)
end

function Arcspread:draw()
end

function Arcspread:die()
  self.dead = true
end

DamageArc = Object:extend()
DamageArc:implement(GameObject)
DamageArc:implement(Physics)
function DamageArc:init(args)
  self:init_game_object(args)
  self.color = self.color or red[0]

  self.damage = self.damage or 30

  self.pierce = self.pierce or 0
  self.angle = self.angle or 0
  self.width = self.width or math.pi/4
  self.speed = self.speed or 100
  self.radius = self.radius or 20
  self.duration = self.duration or 10

  self.grow = self.grow

  --memory
  self.elapsed = 0
  self.targets_hit = {}

  self.x, self.y = Helper.Geometry:move_point_radians(self.x, self.y, 
  self.angle + math.pi, self.radius / 2)

  self.t:after(self.duration, function() self:die() end)
end

function DamageArc:update(dt)
  self:move(dt)
  self:try_damage()
  self:delete()
end

function DamageArc:move(dt)
  local movement = dt * self.speed
  if self.grow then
    self.radius = self.radius + movement
  else
    self.x, self.y = Helper.Geometry:move_point_radians(self.x, self.y, 
    self.angle, movement)
  end
end

function DamageArc:get_line()
  local x1, y1 = Helper.Geometry:move_point(self.x, self.y, self.angle, self.radius)
  local x2, y2 = Helper.Geometry:move_point(self.x, self.y, self.angle + self.width, self.radius)

  return x1, y1, x2, y2

end

function DamageArc:try_damage()
  local x1, y1, x2, y2  = self:get_line()
  local line = Line(x1, y1, x2, y2)
  
  local targets = main.current.main:get_objects_in_shape(line, friendly_classes, self.targets_hit)

  for _, target in ipairs(targets) do
    dot1:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    target:hit(self.damage, self.unit)
    table.insert(self.targets_hit, target)

  end

  if #self.targets_hit > self.pierce then
    self:die()
  end
end

function DamageArc:delete()
  if Helper.Geometry:is_off_screen(self.x, self.y, self.angle, self.radius + 20) then
    self:die()
  end
end

function DamageArc:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.arc( 'open', self.x, self.y, self.radius, self.angle, self.angle + self.width, self.color, 1)
  graphics.pop()
end

function DamageArc:die()
  self.dead = true
end

Avalanche = Object:extend()
Avalanche:implement(GameObject)
Avalanche:implement(Physics)
function Avalanche:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  self.color = grey[0]
  self.rs = self.rs or 25
  self.dmg = self.dmg or 30

  self.timesToCast = 15


  self.t:every(0.7, function()
    if not self.unit then self:die(); return end
    if self.unit and self.unit.dead then self:die(); return end
    local x, y = math.random(self.rs, gw - self.rs), math.random(self.rs, gh - self.rs)
    Stomp{group = main.current.main, unit = self.unit, team = self.team, x = x, y = y,
      rs = self.rs, color = self.color, dmg = self.dmg, chargeTime = 1.5, knockback = true, 
      parent = self}
  end, self.timesToCast, function() self:die() end, 'avalanche')

  self.unit.state = unit_states['normal']
end

function Avalanche:update(dt)
  self:update_game_object(dt)
end

function Avalanche:draw()
end

function Avalanche:die()
  self.dead = true
  self.t:cancel('avalanche')
end

----------------------------------------------

--need to tweak so it returns to unit, not to original position
Boomerang = Object:extend()
Boomerang:implement(GameObject)
Boomerang:implement(Physics)
function Boomerang:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 8
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = yellow[0] or self.color
  self.color = self.color:clone()
  self.color.a = 0.7

  self.damage = self.damage or 30

  self.speed = self.speed or 125

  if self.spelltype == "targeted" then
    self.r = Get_Angle_For_Target(self)
  else
    self.r = self.r or 0
  end
  
  self:set_angle(self.r)
  self.twirl_speed = self.twirl_speed or 3
  self.twirl_facing = 0

  self.distance = self.distance or 100

  self.duration = self.distance / self.speed
  self.halfway_duration = self.duration / 2
  self.turned_around = false

  self.already_damaged = {}

  self.elapsed = 0
  cannoneer1:play{volume=0.7}

end

function Boomerang:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self.elapsed = self.elapsed + dt
  self.twirl_facing = self.twirl_facing + self.twirl_speed * dt

  local x = self.x
  local y = self.y

  if not self.turned_around then
    self.x = self.x + self.speed * math.cos(self.r) * dt
    self.y = self.y + self.speed * math.sin(self.r) * dt
  else
    --return to unit
    if not self.unit or self.unit.dead then self:die() end
    if self:distance_to_object(self.unit) < 10 then self:die() end
    self.x = self.x + self.speed * math.cos(self:angle_to_object(self.unit)) * dt
    self.y = self.y + self.speed * math.sin(self:angle_to_object(self.unit)) * dt
  end


  if self.elapsed > self.halfway_duration and not self.turned_around then
    self.r = self.r + math.pi
    self.turned_around = true
    self.already_damaged = {}
  end
  if self.elapsed > self.duration then
    self:die()
  end

  self.shape:move_to(self.x, self.y)
end

function Boomerang:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  for _, friendly in ipairs(friendlies) do
    if not table.contains(self.already_damaged, friendly) then
      friendly:hit(self.damage, self.unit)
      table.insert(self.already_damaged, friendly)
    end
  end
end

function Boomerang:draw()

  local circle = function()
    graphics.circle(self.x, self.y, self.shape.rs, self.color)
  end
  local mask_circle = function()
    graphics.circle(self.x + 2, self.y + 2, self.shape.rs, self.color, 2)
  end

  graphics.push(self.x, self.y, self.twirl_facing, self.spring.x, self.spring.x)
    graphics.draw_with_mask(circle, mask_circle)
  graphics.pop()
end

function Boomerang:die()
  self.dead = true
end

----------------------------------------------

Burst = Object:extend()
Burst:implement(GameObject)
Burst:implement(Physics)
function Burst:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 8
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = red[0] or self.color
  self.color = self.color:clone()
  self.color.a = 0.7

  self.damage = self.damage or 30
  self.num_pieces = self.num_pieces or 10
  
  self.speed = self.speed or 100

  if self.spelltype == "targeted" then
    self.r = Get_Angle_For_Target(self)
    self.distance = Get_Distance_To_Target(self)
    self.distance = math.random(self.distance - 50, self.distance + 50)
    self.distance = math.max(self.distance, 100)
    self.distance = math.min(self.distance, 250)
  else
    self.r = self.r or 0
    self.distance = self.distance or math.random(100, 250)
  end  
  self.secondary_damage = self.secondary_damage or 10
  self.secondary_distance = self.secondary_distance or 50
  self.secondary_speed = self.secondary_speed or 100
  

  self.already_damaged = {}
  
  self:set_angle(self.r)

  self.duration = self.duration or 12
  self.elapsed = 0
  cannoneer1:play{volume=0.7}
  self.t:after(self.duration, function() self:die() end)
end

function Burst:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  for _, friendly in ipairs(friendlies) do
    if not table.contains(self.already_damaged, friendly) then
      friendly:hit(self.damage, self.unit)
      table.insert(self.already_damaged, friendly)
    end
  end
end

function Burst:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self.elapsed = self.elapsed + dt

  local x = self.x
  local y = self.y
  self.x = self.x + self.speed * math.cos(self.r) * dt
  self.y = self.y + self.speed * math.sin(self.r) * dt

  local distance = math.sqrt((self.x - x)^2 + (self.y - y)^2)
  self.distance = self.distance - distance
  if self.distance <= 0 then
    self:explode()
  end
  self.shape:move_to(self.x, self.y)
  if Outside_Arena(self) then
    self:explode()
  end
end

function Burst:explode()
  if not self.dead then
    explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.3}

    local angle_between = 2*math.pi / self.num_pieces
    local angle = 0
    for i = 1, self.num_pieces do
      angle = angle + angle_between
      BurstBullet{
        group = self.group,
        x = self.x,
        y = self.y,
        r = angle,
        speed = self.secondary_speed,
        distance = self.secondary_distance,
        damage = self.secondary_damage,
        color = self.color,
        unit = self.unit,
      }
      
    end
    self:die()
  end
end

function Burst:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color)
  graphics.pop()
end

function Burst:die()
  self.dead = true
end

BurstBullet = Object:extend()
BurstBullet:implement(GameObject)
BurstBullet:implement(Physics)
function BurstBullet:init(args)
  self:init_game_object(args)
  self.radius = self.radius or 4
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = red[0] or self.color
  self.color = self.color:clone()
  self.color.a = 0.7

  self.damage = self.damage or 20

  self.distance = self.distance or 50
  self.speed = self.speed or 100
  self.r = self.r or 0
  self:set_angle(self.r)

  self.duration = self.duration or 12
  self.elapsed = 0
  self.t:after(self.duration, function() self:die() end)
end

function BurstBullet:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self.elapsed = self.elapsed + dt

  local x = self.x
  local y = self.y

  self.x = self.x + self.speed * math.cos(self.r) * dt
  self.y = self.y + self.speed * math.sin(self.r) * dt
  self.shape:move_to(self.x, self.y)

  local distance = math.sqrt((self.x - x)^2 + (self.y - y)^2)
  self.distance = self.distance - distance
  if self.distance <= 0 then
    self:die()
  end
  self.shape:move_to(self.x, self.y)
  if self.x < 0 or self.x > gw or self.y < 0 or self.y > gh then
    self:die()
  end
end

function BurstBullet:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  if #friendlies > 0 then
    friendlies[1]:hit(self.damage, self.unit)
    self:die()
  end
end

function BurstBullet:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color)
  graphics.pop()
end

function BurstBullet:die()
  self.dead = true
end

-----------------------------------------------------------

ChainLightning = Object:extend()
ChainLightning:implement(GameObject)
ChainLightning:implement(Physics)
function ChainLightning:init(args)
  self:init_game_object(args)
  if not self.group.world then self.dead = true; return end
  self.dmg = args.dmg or 5
  self.damageType = args.damageType or DAMAGE_TYPE_LIGHTNING

  self.attack_sensor = Circle(self.target.x, self.target.y, self.rs)
  local total_targets = args.chain or 3

  local target_classes = nil
  if self.team == "enemy" then
    target_classes = main.current.friendlies
  else
    target_classes = main.current.enemies
  end
  
  self.targets = {self.target}
  self.i = 0

  local bounce = function()
    self.i = self.i + 1
    if #self.targets >= self.i then
      local target = self.targets[self.i]
      if not target then return end
      target:hit(self.dmg, self.parent, self.damageType)
      spark2:play{pitch = random:float(0.8, 1.2), volume = 0.7}

      local lastTarget = nil
      local currentTarget = nil
      if self.i == 1 then
        lastTarget = self.parent
        currentTarget = self.targets[self.i]
      else
        lastTarget = self.targets[self.i-1]
        currentTarget = self.targets[self.i]
      end

      if lastTarget and currentTarget then
        LightningLine{group = main.current.effects, src = lastTarget, dst = currentTarget, color = self.color}
      end
    end
  end


  local targets_in_range = self:get_objects_in_shape(self.attack_sensor, target_classes)
  for _, target in ipairs(targets_in_range) do
    if target.id ~= self.target.id and #self.targets < total_targets then
      table.insert(self.targets, target)
    end
  end

  
  bounce()
  self.t:every(0.2, bounce, total_targets, function() self.dead = true end)

end

function ChainLightning:update(dt)
  self:update_game_object(dt)
end

function ChainLightning:draw()
end

--------------------------

FireWall = Object:extend()
FireWall:implement(GameObject)
FireWall:implement(Physics)
function FireWall:init(args)
  self:init_game_object(args)
  
  fire1:play{volume = 0.7}
  self.color = red[0]:clone()
  self.color.a = 0.6
  
  self.dmg = self.dmg or 50
  --starts on one side of the screen and moves to the other
  self.speed = 60
  self.direction = self.direction or -1
  
  if self.direction == -1 then
    self.start_x = gw
  else
    self.start_x = 0
  end
  self.x = self.start_x

  --hole in the wall
  self.wall_type = self.wall_type or 'segments'
  self.num_segments = self.num_segments or 4
  self.num_holes = self.num_holes or 1
  
  

  self:create_hole_indexes()

  self:create_segments()

  --can only damage a unit once
  --maybe change to once per second, by keeping 2 lists of damaged units
  -- and swapping them out every second (otherwise you could get hit twice in a row on the overlap)
  self.damaged_units = {}

end

function FireWall:try_damage(unit)
  if not table.contains(self.damaged_units, unit) then
    table.insert(self.damaged_units, unit)
    unit:hit(self.dmg, self.unit)
  end
end

function FireWall:create_hole_indexes()
  self.hole_indexes = {}
  local all_indexes = {}
  for i = 1, self.num_segments do
    table.insert(all_indexes, i)
  end
  for i = 1, self.num_holes do
    local index = random:table_remove(all_indexes)
    table.insert(self.hole_indexes, index)
  end
end

function FireWall:create_segments()
  self.segments = {}
  if self.wall_type == 'segments' then
    self:create_segmented_wall()
  elseif self.wall_type == 'half' then
    self:create_half_wall()
  end
end

function FireWall:create_segmented_wall()
  local segment_width = 10
  local segment_height = gh / self.num_segments

  for i = 1, self.num_segments do
    if not table.contains(self.hole_indexes, i) then
      local segment = FireSegment{
          group = main.current.effects, 
          x = self.x,
          y = (segment_height / 2) + ((i - 1) * segment_height),
          w = segment_width,
          h = segment_height,
          speed = self.speed,
          direction = self.direction,
          color = self.color,
          dmg = self.dmg,
          parent = self}
      table.insert(self.segments, segment)
    end
  end
end

function FireWall:create_half_wall()
  local segment_width = 10
  local segment_height = gh / 2

  local possible_y = {
    segment_height / 2,
    segment_height,
    segment_height + (segment_height / 2)
  }
  local y = random:table(possible_y)

  local segment = FireSegment{
      group = main.current.effects, 
      x = self.x,
      y = y,
      w = segment_width,
      h = segment_height,
      speed = self.speed,
      direction = self.direction,
      color = self.color,
      dmg = self.dmg,
      parent = self}
  table.insert(self.segments, segment)
end

function FireWall:update(dt)
  self:update_game_object(dt)
end

function FireWall:draw()
end

function FireWall:die()
  self.dead = true
  for _, segment in ipairs(self.segments) do
    segment.dead = true
  end
end

FireSegment = Object:extend()
FireSegment:implement(GameObject)
FireSegment:implement(Physics)
function FireSegment:init(args)
  self:init_game_object(args)

  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.currentTime = 0
  self.speed = self.speed or 100
  self.dmg = self.dmg or 50

  self.particle_interval = 0.1
  self.particle_elapsed = 0
end

function FireSegment:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self:add_particles()

  self.currentTime = self.currentTime + dt
  self.particle_elapsed = self.particle_elapsed + dt

  self.x = self.x + self.speed * self.direction * dt
  self.shape:move_to(self.x, self.y)
  if self.x < 0 or self.x > gw then self:die() end
end

function FireSegment:add_particles()
  if self.particle_elapsed > self.particle_interval then
    self.particle_elapsed = 0
    for i = 1, 5 do
      local x = self.x + random:float(-self.w/2, self.w/2)
      local y = self.y + random:float(-self.h/2, self.h/2)
      HitParticle{group = main.current.effects, 
        x = x, y = y, 
        color = self.color,
        v = random:float(30, 60)
      }
    end
  end
end

function FireSegment:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
  graphics.pop()
end

function FireSegment:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  for _, troop in ipairs(friendlies) do
    self.parent:try_damage(troop)
  end
end

function FireSegment:die()
  self.dead = true
end

------------------------------------------------

LaserBall = Object:extend()
LaserBall:implement(GameObject)
LaserBall:implement(Physics)
function LaserBall:init(args)
  --init game object, physics shape + body, world tag
  self:init_game_object(args)
  self.radius = 8
  self:set_as_circle(self.radius, 'dynamic', 'ghost')
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = red[0]

  --boss state
  self.parent.state = 'frozen'
  self.t:after(1, function()
    if self.parent and self.parent.state == 'frozen' then self.parent.state = 'normal' end
  end)

  --set the velocity and rotation speed
  self.rotation_speed = 0.5
  self.speed = 100

  self.damage = 20

  self.r = math.random(2*math.pi)
  self:set_angle(self.r)


  --set the duration, laser firing
  self.duration = 12
  self.elapsed = 0
  
  self.duration_init = 2
  self.duration_prefire = 1
  self.duration_fire = args.duration_fire or 1
  self.duration_wait = 2
  
  self.nextLaser = self.duration_init
  --play init sound
  illusion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
end

function LaserBall:update(dt)
  if self.parent and self.parent.dead then self.dead = true; return end

  self:update_game_object(dt)
  
  --get velocity based on rotation and speed
  local vx = math.cos(self.r) * self.speed
  local vy = math.sin(self.r) * self.speed
  self:set_velocity(vx, vy)
  self:set_angular_velocity(self.rotation_speed)


  self.duration = self.duration - dt
  if self.duration < 0 then self.dead = true end
  self.elapsed = self.elapsed + dt
  self:update_fire()
end

function LaserBall:update_fire()
  -- create the laser beams here
  if self.elapsed > self.nextLaser then
    self.nextLaser = self.nextLaser + self.duration_prefire + self.duration_fire + self.duration_wait
    self:fire_lasers()
  end
end

function LaserBall:fire_lasers()
  for i = 0, 3 do
    --Laser{group = main.current.effects, parent = self, color = self.color, initial_rotation = (i-1)*math.pi/2}
    local args = {
      group = main.current.main,
      unit = self,
      spell_duration = 10,
      name = 'laser',
      rotation_lock = true,
      rotation_offset = i * (math.pi / 2),
      laser_aim_width = 2,
      damage = self.damage,
      lasermode = 'rotate',
      damage_troops = true,
      damage_once = true,
      
      charge_duration = self.duration_prefire,
      fire_duration = self.duration_fire,
      end_spell_on_fire = false,
      fire_follows_unit = true,
      fade_in_aim_draw = true,
      fade_fire_draw = false,
    }
    Laser_Spell(args)
  end
end

function LaserBall:draw()
  graphics.push(self.x, self.y, self:get_angle(), self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color, 2)
    --draw a cross in the middle of the circle
    graphics.line(self.x - 5, self.y, self.x + 5, self.y, self.color, 2)
    graphics.line(self.x, self.y - 5, self.x, self.y + 5, self.color, 2)
  graphics.pop()
end

function LaserBall:on_collision_enter(other, contact)
  self:bounce(contact:getNormal())
end

function LaserBall:bounce(nx, ny)
  local vx, vy = self:get_velocity()
  if nx == 0 then
    self:set_velocity(vx, -vy)
    self.r = 2*math.pi - self.r
  end
  if ny == 0 then
    self:set_velocity(-vx, vy)
    self.r = math.pi - self.r
  end
  return self.r
end
-----------------------------------------

GoldItem = Object:extend()
GoldItem:implement(GameObject)
GoldItem:implement(Physics)
function GoldItem:init(args)
  self:init_game_object(args)
  self.radius = 3
  self:set_as_circle(self.radius, 'dynamic', 'ghost')
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = yellow[0]

  self.amount = args.amount or 1
  self.pickup_radius = 15

  self.aggro_sensor = Circle(self.x, self.y, self.pickup_radius)

  self.r = math.random(2*math.pi)
  self:set_angle(self.r)

  self.duration = 10
  self.elapsed = 0
end

function GoldItem:update(dt)
  if self.dead then return end

  self:update_game_object(dt)
  self.elapsed = self.elapsed + dt
  if self.elapsed > self.duration then self.dead = true end
  self.aggro_sensor:move_to(self.x, self.y)

  local friendlies = main.current.main:get_objects_in_shape(self.aggro_sensor, main.current.friendlies)
  if #friendlies > 0 then
    self.dead = true
    gold1:play{pitch = random:float(0.8, 1.2), volume = 0.9}
    if main.current then
      if main.current.gold_picked_up then
        main.current.gold_picked_up = main.current.gold_picked_up + self.amount
      else
        main.current.gold_picked_up = self.amount
      end
    end
    
  end
end

function GoldItem:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.circle(self.x, self.y, self.shape.rs, self.color)
  graphics.pop()
end
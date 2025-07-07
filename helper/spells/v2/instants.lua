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
  
  self.damage = get_dmg_value(self.damage)
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
    hit2:play{volume=0.5}
    -- Use primary hit for the exact target hit by the arrow
    Helper.Damage:primary_hit(self.target, self.damage, self.unit, nil, true)
    self:die()
  end
end

function Arrow:draw()
  graphics.circle(self.x, self.y, self.r, self.color)
end

function Arrow:die()
  self.dead = true
end

ArrowProjectile = Object:extend()
ArrowProjectile:implement(GameObject)
ArrowProjectile:implement(Physics)
function ArrowProjectile:init(args)
  self:init_game_object(args)

  -- Create a rectangular hitbox for the arrow
  self.height = self.bullet_size or 3
  self.width = self.height * 2
  self.shape = Rectangle(self.x, self.y, self.width, self.height)
  
  self.damage = get_dmg_value(self.damage)
  self.speed = self.speed or 140
  self.color = self.color or blue[0]
  self.unit = self.unit
  self.target = self.target
  self.x = self.unit.x
  self.y = self.unit.y
  
  -- Calculate max distance as 1.2x attack range
  self.max_distance = (self.unit.attack_sensor and self.unit.attack_sensor.rs or 50) * 1.5
  self.start_x = self.x
  self.start_y = self.y
  
  -- Calculate direction to target
  local xdist = self.target.x - self.x
  local ydist = self.target.y - self.y
  self.angle = math.atan2(ydist, xdist)
  
  -- Set the arrow's rotation to match its direction
  self.r = self.angle
  
  alert1:play{volume=0.9}
end

function ArrowProjectile:update(dt)
  self:update_game_object(dt)
  
  if self.dead then
    return
  end

  -- Move the arrow forward
  self.x = self.x + math.cos(self.angle) * self.speed * dt
  self.y = self.y + math.sin(self.angle) * self.speed * dt

  -- Update the hitbox position
  self.shape:move_to(self.x, self.y)

  -- Check if we've traveled the max distance
  local distance_traveled = math.distance(self.start_x, self.start_y, self.x, self.y)
  if distance_traveled >= self.max_distance then
    self:die()
    return
  end

  -- Check for collisions with enemies
  local target_classes = self.is_troop and main.current.enemies or main.current.friendlies
  local targets = main.current.main:get_objects_in_shape(self.shape, target_classes)
  if #targets > 0 then
    hit2:play{volume=0.5}
    -- Use primary hit for the exact target hit by the projectile
    Helper.Damage:primary_hit(targets[1], self.damage, self.unit, nil, true)
    self:die()
    return
  end
end

function ArrowProjectile:draw()
  -- Draw an arrow shape
  graphics.push(self.x, self.y, self.r, 1, 1)
  
  -- Arrow body (rectangle)
  graphics.rectangle(self.x, self.y, self.width, self.height, 2, 2, self.color)
  
  -- Arrow head (triangle)
  --arrow head Center
  -- local head_center_x = self.x + self.width/2
  -- local head_center_y = self.y + self.height/2
  -- local head_width = 6
  -- local head_height = 8
  -- graphics.triangle(
  --   head_center_x, head_center_y, head_width, head_height, self.color
  -- )
  
  graphics.pop()
end

function ArrowProjectile:die()
  self.dead = true
end


Arcspread = Object:extend()
Arcspread:implement(GameObject)
Arcspread:implement(Physics)
function Arcspread:init(args)
  self:init_game_object(args)
  
  self.color = self.color or blue[2]

  self.damage = get_dmg_value(self.damage)
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

  self.damage = get_dmg_value(self.damage)

  self.pierce = self.pierce or 0
  self.angle = self.angle or 0
  self.width = self.width or math.pi/4
  self.speed = self.speed or 100
  self.radius = self.radius or 20
  self.duration = self.duration or 10

  self.grow = self.grow

  self.flash_duration = self.flash_duration or 0.3
  --memory
  self.elapsed = 0
  self.targets_hit = {}

  self.in_death_flash = false

  self.x, self.y = Helper.Geometry:move_point_radians(self.x, self.y, 
  self.angle + math.pi, self.radius / 2)

  self.t:after(self.duration, function() self:die() end)
end

function DamageArc:update(dt)
  self:update_game_object(dt)
  
  if not self.in_death_flash then
    self:move(dt)
    self:try_damage()
  end
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
    target:hit(self.damage, self.unit, nil, true, true)
    table.insert(self.targets_hit, target)

  end

  if #self.targets_hit > self.pierce then
    self:die_on_hit()
  end
end

function DamageArc:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  graphics.arc( 'open', self.x, self.y, self.radius, self.angle, self.angle + self.width, self.color, 1)
  graphics.pop()
end

function DamageArc:die_on_hit()
  self.in_death_flash = true
  
  -- Store original color and create white flash color
  self.original_color = self.color:clone()
  self.flash_color = white[0]:clone()
  
  -- Flash to white and back twice
  self.t:after(self.flash_duration * 0.25, function() 
    self.color = self.flash_color 
  end)
  self.t:after(self.flash_duration * 0.5, function() 
    self.color = self.original_color 
  end)
  self.t:after(self.flash_duration * 0.75, function() 
    self.color = self.flash_color 
  end)
  self.t:after(self.flash_duration, function() 
    self.color = self.original_color
    self:die() 
  end)
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
  self.damage = get_dmg_value(self.damage)

  self.timesToCast = 15


  self.t:every(0.7, function()
    if not self.unit then self:die(); return end
    if self.unit and self.unit.dead then self:die(); return end
    local x, y = math.random(self.rs, gw - self.rs), math.random(self.rs, gh - self.rs)
    Stomp{group = main.current.main, unit = self.unit, team = self.team, x = x, y = y,
      rs = self.rs, color = self.color, damage = self.damage, chargeTime = 1.5, knockback = true, 
      parent = self}
  end, self.timesToCast, function() self:die() end, 'avalanche')

  Helper.Unit:set_state(self.unit, unit_states['idle'])
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

  self.damage = get_dmg_value(self.damage)

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
  self.continue_anyway = false

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


  if self.elapsed > self.halfway_duration 
    and not self.turned_around 
    and self.unit and not self.unit.dead then
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
      friendly:hit(self.damage, self.unit, nil, true, true)
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
  self.radius = self.radius or 6
  self.shape = Circle(self.x, self.y, self.radius)

  self.color = self.color or red[0]
  self.color = self.color:clone()
  self.color.a = 0.7

  -- NEW: A separate, brighter, more opaque color for the internal blobs
  self.blob_color = self.color:clone()
  self.blob_color.a = 0.95
  self.blob_color.r = math.min(1, self.color.r * 1.5)
  self.blob_color.g = math.min(1, self.color.g * 1.5)
  self.blob_color.b = math.min(1, self.color.b * 1.5)

  self.damage = get_dmg_value(self.damage)
  self.num_pieces = self.num_pieces or 10
  
  self.speed = self.speed or 70

  if self.spelltype == "targeted" then
    self.r = Get_Angle_For_Target(self)
    self.distance = Get_Distance_To_Target(self)
    self.distance = math.random(self.distance - 100, self.distance + 100)
    self.distance = math.max(self.distance, 100)
    self.distance = math.min(self.distance, 250)
  else
    self.r = self.r or 0
    self.distance = self.distance or math.random(100, 250)
  end  
  self.secondary_damage = get_dmg_value(self.secondary_damage) or 10
  self.secondary_distance = self.secondary_distance or 50
  self.secondary_speed = self.secondary_speed or 100
  

  self.already_damaged = {}
  
  self:set_angle(self.r)

  self.duration = self.duration or 12
  self.elapsed = 0
  cannoneer1:play{volume=0.7}
  self.t:after(self.duration, function() self:die() end)

  -- Create the data for our internal swirling blobs
  self.blobs = {}
  local num_blobs = random:int(3, 5)
  for i = 1, num_blobs do
      table.insert(self.blobs, {
          -- Lava lamp style movement - blobs have their own paths
          x = random:float(-self.radius * 0.5, self.radius * 0.5),
          y = random:float(-self.radius * 0.5, self.radius * 0.5),
          vx = random:float(-20, 20),
          vy = random:float(-20, 20),
          rs = random:float(self.radius * 0.2, self.radius * 0.4),
          -- Slower, more organic movement
          speed = random:float(0.1, 0.3),
          -- Add some randomness to movement
          wobble = random:float(0, 2 * math.pi),
          wobble_speed = random:float(1, 3)
      })
  end

end

function Burst:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  if #friendlies > 0 then
    self:explode()
  end
end

function Burst:update(dt)
  self:update_game_object(dt)
  local hit_target = self:check_hits()
  self.elapsed = self.elapsed + dt

  -- Update blob positions for lava lamp movement
  for _, blob in ipairs(self.blobs) do
    -- Update blob position
    blob.x = blob.x + blob.vx * dt * blob.speed
    blob.y = blob.y + blob.vy * dt * blob.speed
    
    -- Add wobble to movement
    local wobble_x = math.sin(self.elapsed * blob.wobble_speed) * 2
    local wobble_y = math.cos(self.elapsed * blob.wobble_speed) * 2
    blob.x = blob.x + wobble_x * dt
    blob.y = blob.y + wobble_y * dt
    
    -- Bounce off the edges of the burst (lava lamp effect)
    local distance_from_center = math.sqrt(blob.x * blob.x + blob.y * blob.y)
    local max_distance = self.radius - blob.rs
    
    if distance_from_center > max_distance then
      -- Bounce back towards center
      local angle = math.atan2(blob.y, blob.x)
      blob.x = math.cos(angle) * max_distance
      blob.y = math.sin(angle) * max_distance
      
      -- Reverse velocity with some randomness
      blob.vx = -blob.vx * 0.8 + random:float(-10, 10)
      blob.vy = -blob.vy * 0.8 + random:float(-10, 10)
    end
  end

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
    
    if self.primary_explosion then
      Area{
        group = main.current.effects,
        unit = self.unit,
        is_troop = false,
        x = self.x,
        y = self.y,
        r = self.radius * 2,
        pick_shape = 'circle',
        duration = 0.15,
        damage = self.damage,
        color = self.color,
        parent = self,
      }
    end

    local angle_between = 2*math.pi / self.num_pieces
    local angle = 0
    for i = 1, self.num_pieces do
      angle = angle + angle_between
      BurstBullet{
        group = self.group,
        color = self.color,
        x = self.x,
        y = self.y,
        r = angle,
        speed = self.secondary_speed,
        distance = self.secondary_distance,
        damage = self.secondary_damage,
        unit = self.unit,
      }
      
    end
    self:die()
  end
end


function Burst:draw()
  -- 1. Define the mask action: draw all the blobs.
  -- This creates the "holes" in our stencil.
  local mask_action = function()
      for _, blob in ipairs(self.blobs) do
          local blob_x = self.x + blob.x
          local blob_y = self.y + blob.y
          graphics.circle(blob_x, blob_y, blob.rs)
      end
  end

  -- 2. Define the main drawing action: draw the semi-transparent main orb.
  local orb_action = function()
      graphics.circle(self.x, self.y, self.radius, self.color)
  end

  -- 3. Draw the lighter blobs first, so they appear underneath.
  for _, blob in ipairs(self.blobs) do
      local blob_x = self.x + blob.x
      local blob_y = self.y + blob.y
      graphics.circle(blob_x, blob_y, blob.rs, self.blob_color)
  end

  -- 4. Use the inverted mask to draw the main orb *around* the blobs.
  -- The third argument 'true' inverts the mask.
  graphics.draw_with_mask(orb_action, mask_action, true)
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

  self.color = self.color or red[0]
  self.color = self.color:clone()
  self.color.a = 0.7

  self.damage = get_dmg_value(self.damage)

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
    friendlies[1]:hit(self.damage, self.unit, nil, true, true)
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




--------------------------

FireWall = Object:extend()
FireWall:implement(GameObject)
FireWall:implement(Physics)
function FireWall:init(args)
  self:init_game_object(args)
  
  fire1:play{volume = 0.7}
  self.color = red[0]:clone()
  self.color.a = 0.6
  
  self.damage = get_dmg_value(self.damage)
  --starts on one side of the screen and moves to the other
  self.speed = 60
  self.direction = self.direction or -1
  
  if self.direction == -1 then
    self.start_x = gw
  else
    self.start_x = 0
  end
  self.x = self.start_x

  self.angle = 0
  if self.direction == -1 then
    self.angle = math.pi
  end

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
    player_hit1:play{pitch = random:float(0.95, 1.05), volume = 1.2}

    local push_angle = self.angle
    local knockback_duration = KNOCKBACK_DURATION_ENEMY
    local knockback_force = LAUNCH_PUSH_FORCE_SPECIAL_ENEMY
    
    unit:push(knockback_force, push_angle, nil, knockback_duration)

    unit:hit(self.damage, self.unit, nil, true, true)
    
    return true
  else
    return false
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
          damage = self.damage,
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
      damage = self.damage,
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
  self.damage = get_dmg_value(self.damage)

  self.particle_interval = 0.1
  self.particle_elapsed = 0

  
  self.shader = love.graphics.newShader("helper/spells/v2/shaders/firewall.frag")
  self.flash_amount = 0
  self.flash_duration = 0.2
  self.flash_timer = 0

end

function FireSegment:update(dt)
  self:update_game_object(dt)
  self:check_hits()
  self:add_particles()

  self.currentTime = self.currentTime + dt
  self.particle_elapsed = self.particle_elapsed + dt

  -- Update the flash timer
  if self.flash_timer > 0 then
    self.flash_timer = self.flash_timer - dt
    -- Create a fade-out effect for the flash
    self.flash_amount = self.flash_timer / self.flash_duration
  else
      self.flash_amount = 0
  end
  
  self.shader:send("time", self.currentTime)
  self.shader:send("flash_amount", self.flash_amount)

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
  love.graphics.setShader(self.shader)

  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.color)
  graphics.pop()
  
  love.graphics.setShader()
end

function FireSegment:check_hits()
  local friendlies = main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)
  for _, troop in ipairs(friendlies) do
    if self.parent:try_damage(troop) then
      self:flash()
    end
  end
end

-- Add this new function to the FireSegment object
function FireSegment:flash()
  -- This resets the flash timer, which is then handled in update()
  self.flash_timer = self.flash_duration
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
  Helper.Unit:set_state(self.parent, unit_states['frozen'])
  self.t:after(1, function()
    if self.parent and self.parent.state == 'frozen' then Helper.Unit:set_state(self.parent, unit_states['idle']) end
  end)

  --set the velocity and rotation speed
  self.rotation_speed = 0.5
  self.speed = 100

  self.damage = get_dmg_value(self.damage)

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

-- ====================================================================
-- LightningBall Class
-- A projectile that travels in a random direction, periodically
-- zapping nearby enemies with lightning.
-- ====================================================================

LightningBall = Object:extend()
LightningBall:implement(GameObject)
LightningBall:implement(Physics)

function LightningBall:init(args)
    self:init_game_object(args)
    
    -- Core Properties
    self.radius = self.radius or 8
    self:set_as_circle(self.radius, 'dynamic', 'effect')
    self.shape = Circle(self.x, self.y, self.radius)

    -- Visuals
    self.color = self.color or yellow[0]
    self.color = self.color:clone()
    self.color.a = 0.5
    self.core_color = white[0]:clone()
    self.core_color.a = 0.8
    self.sparks = {}
    self:create_sparks()

    -- Behavior Properties
    self.damage = self.damage or 15
    self.shock_duration = self.shock_duration or 3
    self.speed = self.speed or 30
    self.duration = self.duration or 4
    self.tick_rate = self.tick_rate or 1.5
    self.num_targets = self.num_targets or 3
    self.max_target_distance = self.max_target_distance or 75

    -- Movement
    self.r = random:float(0, 2 * math.pi)
    self:set_angle(self.r)
    local vx = math.cos(self.r) * self.speed
    local vy = math.sin(self.r) * self.speed
    self:set_velocity(vx, vy)

    -- Timers and State
    self.elapsed = 0
    self.next_tick = self.tick_rate
    self.recently_shocked = {}
end

function LightningBall:update(dt)
    self:update_game_object(dt)
    self.elapsed = self.elapsed + dt
    self.next_tick = self.next_tick - dt

    -- Expire after duration
    if self.elapsed >= self.duration then
        self:die()
        return
    end

    -- Check if it's time to shock targets
    if self.next_tick <= 0 then
        self:find_and_shock_targets()
        self.next_tick = self.tick_rate
    end
    
    -- Update the visual effect
    self:update_sparks(dt)
end

function LightningBall:find_and_shock_targets()
    -- Find all potential targets (assuming this gets all enemy units)
    local potential_targets = Helper.Unit:get_list(false)
    
    -- Sort targets by distance to find the closest ones
    table.sort(potential_targets, function(a, b)
        return self:distance_to_object(a) < self:distance_to_object(b)
    end)

    local targets_shocked_this_tick = 0
    for _, target in ipairs(potential_targets) do
        if self:distance_to_object(target) > self.max_target_distance then
            break
        end

        if targets_shocked_this_tick >= self.num_targets then
            break
        end

        -- Shock the target
        target:hit(self.damage, nil, DAMAGE_TYPE_LIGHTNING, false, true) -- Assuming units have an apply_shock method

        -- Create the lightning visual effect
        LightningLine{
            group = main.current.effects,
            src = self,
            dst = target,
            color = self.color,
            generations = 4,
            max_offset = 12
        }
        
        targets_shocked_this_tick = targets_shocked_this_tick + 1
    end
    
    if targets_shocked_this_tick > 0 then
      spark2:play{pitch = random:float(0.8, 1.2), volume = 0.4}
    end
end

-- Visual effect logic
function LightningBall:create_sparks()
    for i = 1, 5 do
        table.insert(self.sparks, {
            angle = random:float(0, 2 * math.pi),
            dist = random:float(self.radius * 0.5, self.radius * 1.2),
            speed = random:float(2, 4),
            size = random:float(1, 3)
        })
    end
end

function LightningBall:update_sparks(dt)
    for _, spark in ipairs(self.sparks) do
        spark.angle = (spark.angle + spark.speed * dt) % (2 * math.pi)
    end
end

function LightningBall:draw()
    -- Draw the crackling sparks
    for _, spark in ipairs(self.sparks) do
        local spark_x = self.x + math.cos(spark.angle) * spark.dist
        local spark_y = self.y + math.sin(spark.angle) * spark.dist
        graphics.circle(spark_x, spark_y, spark.size, self.color)
    end

    -- Draw the solid white core
    graphics.circle(self.x, self.y, self.radius * 0.6, self.core_color)
end

function LightningBall:die()
    self.dead = true
end


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
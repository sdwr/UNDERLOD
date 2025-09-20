local fns = {}

fns['init_enemy'] = function(self)
  --set extra variables from data
  self.data = self.data or {}

  -- Set class before shape so Set_Enemy_Shape knows it's a special enemy
  self.class = 'special_enemy'

  --create shape
  self.color = red[0]:clone()
  Set_Enemy_Shape(self, self.size)
  self.icon = 'goblin'
  self.name = 'turret'

  --set attacks
  self.attack_options = {}

      local multi_shot = {
      name = 'multi_shot',
      viable = function() return true end,
      oncast = function()
        -- Rotate randomly (about 1/5th of a circle)
        self.target = Helper.Target:get_random_enemy(self)
      end,
  

      cancel_on_range = false,
      instantspell = true,
      cast_sound = scout1,
      spellclass = MultiProjectile,
      unit = self,
      spelldata = {
        group = main.current.main,
        color = red[0],
        damage = function() return self.dmg end,
        bullet_size = 4,
        is_troop = false,
        speed = 100,
        projectile_count = 5,
        spread_angle = math.pi/12, -- 15 degrees spread
        delay_between = 0, -- 0 seconds between projectiles
        duration = 1.2, -- projectile duration
        x = self.x,
        y = self.y,
      },
    }
  table.insert(self.attack_options, multi_shot)
end

fns['draw_enemy'] = function(self)   
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['turret'] = fns

-- Multi-projectile spell class
MultiProjectile = Object:extend()
MultiProjectile.__class_name = 'MultiProjectile'
MultiProjectile:implement(GameObject)
MultiProjectile:implement(Physics)
function MultiProjectile:init(args)
  self:init_game_object(args)

  self.damage = get_dmg_value(self.damage)
  self.angle_offset = random:float(-math.pi/12, math.pi/12)
  self.projectile_count = self.projectile_count or 3
  self.spread_angle = self.spread_angle or math.pi/12
  self.delay_between = self.delay_between or 0.1
  self.duration = self.duration or 10

  if self.target then
    local xdist = self.target.x - self.x
    local ydist = self.target.y - self.y
    self.angle = math.atan2(ydist, xdist) + self.angle_offset
  else
    self.angle = random:float(0, 2*math.pi)
  end
  
  if tostring(self.x) == tostring(0/0) or tostring(self.y) == tostring(0/0) then self.dead = true; return end
  
  -- Create the first projectile immediately
  self:create_projectile(0)
  
  -- Schedule the remaining projectiles
  for i = 1, self.projectile_count - 1 do
    self.t:after(i * self.delay_between, function()
      self:create_projectile(i)
    end)
  end
end

function MultiProjectile:create_projectile(index)
  -- Calculate spread angle for this projectile
  local angle_offset = random:float(-self.spread_angle/2, self.spread_angle/2)
  local projectile_angle = self.angle + angle_offset
  
  projectile_angle = projectile_angle + angle_offset

  -- Create the actual projectile
  local projectile = EnemyProjectile{
    group = self.group,
    x = self.x,
    y = self.y,
    r = projectile_angle,
    speed = self.speed,
    damage = self.damage,
    color = self.color,
    radius = self.bullet_size,
    is_troop = self.is_troop,
    duration = self.duration,
    source = 'turret'
  }
end

function MultiProjectile:update(dt)
  self:update_game_object(dt)
  -- This object just schedules projectiles, so we can die after a short time
  if self.timer and self.timer > self.projectile_count * self.delay_between + 0.1 then
    self:die()
  end
end

function MultiProjectile:draw()
  -- This object doesn't need to draw anything
end

function MultiProjectile:die()
  self.dead = true
end

-- SingleProjectile wrapper class for EnemyProjectile
-- Converts target-based spells to angle-based EnemyProjectile
SingleProjectile = Object:extend()
SingleProjectile.__class_name = 'SingleProjectile'
SingleProjectile:implement(GameObject)
function SingleProjectile:init(args)
  self:init_game_object(args)

  self.width = args.width or 10
  self.height = args.height or 4

  -- Calculate angle to target
  local angle = 0
  if self.target then
    local dx = self.target.x - self.x
    local dy = self.target.y - self.y
    angle = math.atan2(dy, dx)
  else
    angle = random:float(0, 2 * math.pi)
  end
  
  -- Create the actual EnemyProjectile
  EnemyProjectile{
    group = self.group,
    x = self.x,
    y = self.y,
    r = angle,
    speed = self.v or 120,  -- Convert v to speed for EnemyProjectile
    radius = math.max(self.width or 10, self.height or 4) / 2,  -- Convert width/height to radius
    damage = self.damage,
    color = self.color,
    unit = self.unit,
    source = self.source or 'single_projectile'
  }
  
  -- This wrapper object is done
  self:die()
end

function SingleProjectile:update(dt)
  -- This object just creates the projectile and dies
end

function SingleProjectile:draw()
  -- This object doesn't need to draw anything
end

function SingleProjectile:die()
  self.dead = true
end 
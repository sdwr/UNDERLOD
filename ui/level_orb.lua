LevelOrb = Object:extend()
LevelOrb.__class_name = 'LevelOrb'
LevelOrb:implement(GameObject)
LevelOrb:implement(Physics)

function LevelOrb:init(args)
  self:init_game_object(args)
  
  -- Position and basic properties
  self.x = args.x or gw/2
  self.y = args.y or gh/2
  self.group = args.group or main.current.main
  
  -- Physical properties
  self.radius = args.radius or 25
  self.visible_radius = 0

  self:set_as_circle(self.radius, 'static', 'projectile')
  
  -- Health properties
  self.max_hp = args.max_hp or 100
  self.hp = self.max_hp
  
  -- Visual properties
  self.color = args.color or blue[0]:clone()
  self.base_color = self.color:clone()
  self.hurt_color = red[0]:clone()
  self.hurt_flash_color = red[5]:clone()
  
  -- Animation properties
  self.pulse_timer = 0
  self.pulse_speed = 1.5
  self.scale = 1.0
  self.hurt_flash_timer = 0
  self.hurt_flash_duration = 0.2
  
  -- Faction - make it targetable by enemies
  self.faction = 'friendly'
  self.is_level_orb = true
    
  -- Damage resistance
  self.damage_reduction = 0 -- Percentage of damage to reduce (0 = no reduction)

end

function LevelOrb:spawn()
  self.t:tween(0.5, self, {visible_radius = self.radius}, math.ease_in_out_cubic)
  self.t:after(0.5, function()
    level_up1:play{pitch = random:float(0.9, 1.1), volume = 1}
  end)
end

function LevelOrb:update(dt)
  self:update_game_object(dt)
  
  -- Update pulse animation
  self.pulse_timer = self.pulse_timer + dt * self.pulse_speed
  self.scale = 1.0 + 0.1 * math.sin(self.pulse_timer)
  
  -- Update hurt flash
  if self.hurt_flash_timer > 0 then
    self.hurt_flash_timer = self.hurt_flash_timer - dt
    if self.hurt_flash_timer <= 0 then
      self.color = self.base_color:clone()
    end
  end
  
  -- Update collision shape position
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
end

function LevelOrb:on_collision_enter(other)
  if not other:is(Enemy) then return end

  local enemy_round_power = enemy_to_round_power[other.type] or 10

  self:hit(enemy_round_power / 50, other, DAMAGE_TYPE_PHYSICAL)
  local duration = KNOCKBACK_DURATION_ENEMY
  local push_force = LAUNCH_PUSH_FORCE_ENEMY
  other:die(1000, nil, DAMAGE_TYPE_PHYSICAL, true, true)
end

function LevelOrb:hit(damage, from, damage_type)
  if self.dead then return end
  
  -- Apply damage reduction
  local actual_damage = damage * (1 - self.damage_reduction)
  
  -- Take damage
  self.hp = self.hp - actual_damage
  
  -- Visual feedback
  self:flash_hurt()
  
  -- Play hit sound
  hit1:play{pitch = random:float(0.9, 1.1), volume = 1}
  
  -- Check if destroyed
  if self.hp <= 0 then
    self:die()
  end
end

function LevelOrb:flash_hurt()
  self.hurt_flash_timer = self.hurt_flash_duration
  self.color = self.hurt_color:clone()
end

function LevelOrb:get_hp_percentage()
  if self.max_hp <= 0 then return 1 end
  return math.clamp(self.hp / self.max_hp, 0, 1)
end

function LevelOrb:draw()
  if self.dead then return end
  
  graphics.push(self.x, self.y, 0, self.scale, self.scale)
  
  -- Draw main orb background (grey)
  graphics.circle(self.x, self.y, self.visible_radius, bg[5]:clone())
  
  -- Draw health portion (colored from bottom)
  local hp_percentage = self:get_hp_percentage()
  if hp_percentage > 0 then
    local fill_height = self.visible_radius * 2 * hp_percentage
    local fill_y = self.y + self.visible_radius - (fill_height /2) 
    
    -- Create a clipping mask for the health portion
    love.graphics.stencil(function()
      graphics.rectangle(self.x, fill_y, self.visible_radius * 2, fill_height, 0, 0, white[0])
    end, "replace", 1)
    
    love.graphics.setStencilTest("greater", 0)
    
    -- Draw the colored health portion
    local health_color = self.color
    if self.hurt_flash_timer > 0 then
      health_color = self.hurt_flash_color
    end
    graphics.circle(self.x, self.y, self.visible_radius, health_color)
    
    love.graphics.setStencilTest()
  end
  
  -- Draw border
  local border_color = white[0]
  if self.hurt_flash_timer > 0 then
    border_color = red[5]
  end
  graphics.circle(self.x, self.y, self.visible_radius, border_color, 2)
  
  graphics.pop()
end

function LevelOrb:die()
  if self.dead then return end
  self.dead = true
  
  -- Play destruction sound
  explosion1:play{pitch = random:float(0.8, 1.2), volume = 0.5}
  
  -- Trigger level failure or other consequences
  if self.parent and self.parent.on_level_orb_destroyed then
    self.parent:on_level_orb_destroyed()
  end
end

function LevelOrb:heal(amount)
  if self.dead then return end
  
  self.hp = math.min(self.max_hp, self.hp + amount)
  
  -- Visual feedback for healing
  self:flash_heal()
end

function LevelOrb:flash_heal()
  -- Flash green briefly
  self.hurt_flash_timer = self.hurt_flash_duration
  self.color = green[0]:clone()
end
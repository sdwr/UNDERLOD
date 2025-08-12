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
  self:set_as_circle(self.radius, 'static', 'projectile')
  
  -- Health properties
  self.max_hp = args.max_hp or 100
  self.hp = self.max_hp
  
  -- Visual properties
  self.color = args.color or blue[0]:clone()
  self.base_color = self.color:clone()
  self.hurt_color = red[0]:clone()
  
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
  player_hit1:play{pitch = random:float(0.9, 1.1), volume = 0.3}
  
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
  
  -- Draw main orb
  graphics.circle(self.x, self.y, self.radius, self.color)
  
  -- Draw border
  local border_color = white[0]
  if self.hurt_flash_timer > 0 then
    border_color = red[5]
  end
  graphics.circle(self.x, self.y, self.radius, border_color, 2)
  
  -- Draw health indicator
  local hp_percentage = self:get_hp_percentage()
  if hp_percentage < 1.0 then
    -- Draw health bar background
    local bar_width = self.radius * 2
    local bar_height = 6
    local bar_y = self.y - self.radius - 10
    
    graphics.rectangle(self.x, bar_y, bar_width, bar_height, 0, 0, bg[5]:clone())
    
    -- Draw health bar fill
    local fill_width = bar_width * hp_percentage
    local health_color = hp_percentage > 0.5 and green[0]:clone() or (hp_percentage > 0.25 and yellow[0]:clone() or red[0]:clone())
    graphics.rectangle(self.x - (bar_width - fill_width) / 2, bar_y, fill_width, bar_height, 0, 0, health_color)
    
    -- Draw health text
    local hp_text = math.ceil(self.hp) .. "/" .. self.max_hp
    graphics.print(hp_text, fat_font, self.x, bar_y - 15, 0, 1, 1, 0, 0, white[0]:clone())
  end
  
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
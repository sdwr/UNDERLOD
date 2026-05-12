SwordWeapon = Weapon:extend()

function SwordWeapon:init(data)
  self.weapon_name = 'sword'
  self.base_attack_range = 50
  SwordWeapon.super.init(self, data)

  self.facing = 0
  self.sword_angle = math.pi
  self.is_swinging = false
  self.swing_progress = 0
  self.swing_duration = 0.2
  self.swing_half_angle = math.pi / 3  -- 60° each side = 120° total arc
  self.swing_hit_enemies = {}
  self.mouse_was_down = false
  self.swing_cooldown = 0
end

function SwordWeapon:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
end

function SwordWeapon:setup_cast(cast_target)
  -- no-op: sword uses click-to-swing, not auto-fire
end

function SwordWeapon:update(dt)
  SwordWeapon.super.update(self, dt)
  self.attack_sensor:move_to(self.x, self.y)
  self.attack_sensor.rs = self.attack_range

  if self.player_cursor and self.player_cursor.movement_angle then
    self.facing = self.player_cursor.movement_angle
  end

  if self.swing_cooldown > 0 then
    self.swing_cooldown = self.swing_cooldown - dt
  end

  local mouse_down = love.mouse.isDown(1)
  local clicked = mouse_down and not self.mouse_was_down
  self.mouse_was_down = mouse_down

  if self.is_swinging then
    self.swing_progress = self.swing_progress + dt / self.swing_duration
    self.sword_angle = self.facing - self.swing_half_angle + 2 * self.swing_half_angle * math.min(self.swing_progress, 1)
    self:do_swing_damage()
    if self.swing_progress >= 1 then
      self.is_swinging = false
      self.swing_cooldown = self.attack_cooldown
      self.swing_hit_enemies = {}
    end
  else
    self.sword_angle = self.facing + math.pi
    if clicked and self.swing_cooldown <= 0 then
      self.is_swinging = true
      self.swing_progress = 0
      self.swing_hit_enemies = {}
    end
  end
end

function SwordWeapon:do_swing_damage()
  if not main.current then return end
  local enemies = main.current.main:get_objects_in_shape(self.attack_sensor, main.current.enemies)
  for _, enemy in ipairs(enemies) do
    if enemy and not enemy.dead and not self.swing_hit_enemies[enemy] then
      local angle_to = math.atan2(enemy.y - self.y, enemy.x - self.x)
      local diff = ((angle_to - self.facing + 3 * math.pi) % (2 * math.pi)) - math.pi
      if math.abs(diff) <= self.swing_half_angle then
        self.swing_hit_enemies[enemy] = true
        enemy:hit(self.dmg, self, nil, true)
        if self.onAttackCallbacks then
          self:onAttackCallbacks(enemy)
        end
      end
    end
  end
end

function SwordWeapon:draw()
  if not self.is_swinging and self.swing_cooldown > 0 then return end

  local cx, cy = self.x, self.y
  local blade_length = self.attack_range or self.base_attack_range
  local blade_color = white[0]
  local hilt_color = white[-6]

  graphics.push(cx, cy, self.sword_angle)

  -- pommel
  graphics.circle(cx - 3, cy, 1.8, hilt_color)
  -- handle
  graphics.rectangle2(cx - 3, cy - 1.5, 9, 3, nil, nil, hilt_color)
  -- crossguard
  graphics.rectangle2(cx + 4.5, cy - 5, 2.5, 10, nil, nil, hilt_color)
  -- tapered blade
  graphics.polygon({
    cx + 7, cy - 2.5,
    cx + 7, cy + 2.5,
    cx + blade_length, cy
  }, blade_color)

  graphics.pop()
end

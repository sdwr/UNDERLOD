local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = blue[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'sorcerer'

  self.baseIdleTimer = 0

  self.rotation_speed = 0.4  -- Radians per second
  self:set_fixed_rotation(true)  -- Prevent physics-based rotation from collisions

  --set attacks
  self.attack_options = {}

  local crossfire = {
    name = 'crossfire',
    viable = function () return true end,
    oncast = function() 
      -- No specific target needed, we'll shoot in all 4 directions
    end,

    instantspell = true,

    spellclass = CrossfireAttack,
    spelldata = {
      group = main.current.main,
      unit = self,
      x = self.x,
      y = self.y,
      color = blue[0]:clone(),
      damage = function() return self.dmg end,
      speed = 80,
      parent = self
    }
  }

  table.insert(self.attack_options, crossfire)

end

fns['update_enemy'] = function(self, dt)
  self:set_angular_velocity(self.rotation_speed)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

fns['draw_fallback_custom'] = function(self)
  local base_color = self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color

  graphics.push(self.x, self.y, self.r or 0, self.hfx.hit.x, self.hfx.hit.x)

  -- Draw base rounded rectangle
  local corner_radius = get_enemy_corner_radius(self)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, corner_radius, corner_radius, base_color)

  -- Draw cardinal direction notches
  local notch_length = 6
  local notch_offset = self.shape.w/2 - 2

  -- Draw notches at fixed positions (they'll rotate with the enemy due to graphics.push using self.r)
  -- Right notch
  graphics.line(self.x + notch_offset, self.y, self.x + notch_offset + notch_length, self.y, base_color, 2)
  -- Bottom notch
  graphics.line(self.x, self.y + notch_offset, self.x, self.y + notch_offset + notch_length, base_color, 2)
  -- Left notch
  graphics.line(self.x - notch_offset, self.y, self.x - notch_offset - notch_length, self.y, base_color, 2)
  -- Top notch
  graphics.line(self.x, self.y - notch_offset, self.x, self.y - notch_offset - notch_length, base_color, 2)

  graphics.pop()
end

enemy_to_class['crossfire'] = fns

-- Custom spell class for shooting in 4 cardinal directions
CrossfireAttack = Spell:extend()
CrossfireAttack:implement(GameObject)
CrossfireAttack:implement(Physics)

function CrossfireAttack:init(args)
  self:init_game_object(args)
  
  self.damage = get_dmg_value(self.damage)
  self.projectiles = {}
  
  -- Get the base rotation from the enemy
  local base_angle = self.parent.r or 0
  
  -- Create projectiles in 4 directions relative to enemy's rotation
  local angle_offsets = {
    0,           -- Forward
    math.pi/2,   -- Right
    math.pi,     -- Back
    3*math.pi/2  -- Left
  }
  
  for _, offset in ipairs(angle_offsets) do
    local angle = base_angle + offset
    local projectile = PlasmaBall{
      group = self.group,
      unit = self.unit,
      team = self.team,
      x = self.x,
      y = self.y,
      r = angle,
      speed = self.speed,
      rotation_speed = 0,  -- No rotation for straight movement
      movement_type = 'straight',
      duration = 10,  -- Long duration so it goes off screen
      color = self.color,
      radius = 5,  -- Smaller projectile (default is 8)
      explosion_radius = 10,  -- Smaller explosion (was 15)
      damage = self.damage,
    }
    table.insert(self.projectiles, projectile)
  end
  
  -- Play sound effect
  shoot2:play{pitch = random:float(0.95, 1.05), volume = 1}
  
  -- Die immediately after creating projectiles
  self:die()
end
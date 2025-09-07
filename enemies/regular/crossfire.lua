local fns = {}
fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}

  --create shape
  self.color = blue[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'
  self.icon = 'sorcerer'

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
      speed = 100,
      parent = self
    }
  }

  table.insert(self.attack_options, crossfire)

end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
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
  
  -- Create projectiles in all 4 cardinal directions
  local directions = {
    0,           -- Right
    math.pi/2,   -- Down
    math.pi,     -- Left
    3*math.pi/2  -- Up
  }
  
  for _, angle in ipairs(directions) do
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
      explosion_radius = 15,
      damage = self.damage,
    }
    table.insert(self.projectiles, projectile)
  end
  
  -- Play sound effect
  shoot1:play{pitch = random:float(0.8, 1.2), volume = 0.3}
  
  -- Die immediately after creating projectiles
  self:die()
end
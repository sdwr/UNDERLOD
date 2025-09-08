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

  self.stopChasingInRange = true

  --set attacks
  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() 
      local cursor = main.current.current_arena and main.current.current_arena.player_cursor
      if cursor and not cursor.dead then
        local dist = math.distance(self.x, self.y, cursor.x, cursor.y)
        return dist <= self.attack_sensor.rs
      end
      return false
    end,
    oncast = function() 
      self.target = main.current.current_arena and main.current.current_arena.player_cursor
    end,

    cancel_on_range = false,
    cancel_range = self.attack_sensor.rs * 1.1,
    instantspell = true,
    cast_sound = scout1,
    spellclass = EnemyProjectile,
    spelldata = {
      group = main.current.effects,
      color = blue[0],
      damage = function() return self.dmg end,
      radius = 3,  -- EnemyProjectile uses radius, not bullet_size
      team = 'enemy',
      speed = 120,
    },
  }
  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)   
  local animation_success = self:draw_animation()

  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['shooter'] = fns

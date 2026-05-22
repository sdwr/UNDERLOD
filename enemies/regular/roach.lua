local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'roach'

  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  self.baseActionTimer = 1.25

  self.move_option_weight = 0
  self.stopChasingInRange = true

  self.attack_range = 80
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)
  -- SEEK_TO_RANGE positions the enemy at this distance from the player; keep
  -- it under attack_range so the roach is in range to shoot once it arrives.
  self.seek_to_range_radius = self.attack_range - 10

  -- Move-attack-reposition cadence. After firing, attacks_left hits 0 which
  -- queues NUM_MOVES of MOVEMENT_TYPE_SEEK_TO_RANGE, so the roach repositions
  -- if the target drifted out of attack_range before shooting again.
  self.NUM_ATTACKS = 1
  self.NUM_MOVES = 1
  self.attacks_left = 0
  self.moves_left = self.NUM_MOVES

  self.custom_action_selector = function(self, viable_attacks, viable_movements)
    if self.attack_cooldown_timer > 0 then
      return 'retry', nil
    end
    if self.moves_left > 0 then
      self.moves_left = self.moves_left - 1
      if self.moves_left == 0 then
        self.attacks_left = self.NUM_ATTACKS
      end
      return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE
    else
      self.attacks_left = self.attacks_left - 1
      if self.attacks_left == 0 then
        self.moves_left = self.NUM_MOVES
      end
      return 'attack', random:table(viable_attacks)
    end
  end

  self.attack_options = {}

  local shoot = {
    name = 'shoot',
    viable = function() return Helper.Target:get_random_enemy(self) end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = SingleProjectile,
    spelldata = {
      group = main.current.main,
      color = orange[0],
      damage = function() return self.dmg end,
      v = 100,
      max_distance = self.attack_range * 1.5,
      unit = self,
      source = 'roach',
    },
  }

  table.insert(self.attack_options, shoot)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Visible windup ring while casting
  if self.state == unit_states['casting'] and self.castObject then
    local pct = self.castObject:get_cast_percentage() or 0
    graphics.circle(self.x, self.y, 6 + pct * 8, orange[5], 1)
  end
end

enemy_to_class['roach'] = fns

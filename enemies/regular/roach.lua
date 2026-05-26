local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'roach'

  self.color = orange[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Lock body rotation at the physics level. self.freezerotation gets reset
  -- to false by Unit:end_cast, so it can't be used to permanently freeze the
  -- visual angle - set_fixed_rotation locks it for good. Projectile angles
  -- are computed at fire time from unit->target, so the roach's body angle
  -- is purely visual anyway.
  self:set_fixed_rotation(true)

  -- Roaches don't take knockback. knockback_resistance caps at 0.8 in
  -- calculate_stats so the hard-immune flag is required to fully ignore it.
  -- Both Helper.Unit:apply_knockback and apply_knockback_enemy honor this.
  self.knockback_immune = true


  self.baseActionTimer = 1.25
  self.baseIdleTimer = 0.1

  self.move_option_weight = 0
  self.stopChasingInRange = true

  self.attack_range = 80
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)
  -- SEEK_TO_RANGE positions the enemy at this distance from the player; keep
  -- it under attack_range so the roach is in range to shoot once it arrives.
  self.seek_to_range_radius = self.attack_range - 10

  -- Chase-and-shoot: if any troop is inside attack_range right now, fire;
  -- otherwise close the gap via SEEK_TO_RANGE. No fixed alternation, so once
  -- the roach is in range it spams attacks (gated by attack_cooldown) instead
  -- of always inserting a reposition move between shots.
  self.custom_action_selector = function(self, viable_attacks, viable_movements)
    if self.attack_cooldown_timer > 0 then
      return 'retry', nil
    end
    local target = Helper.Target:get_random_enemy(self)
    if target and self:in_range_of(target) then
      return 'attack', random:table(viable_attacks)
    else
      return 'movement', MOVEMENT_TYPE_SEEK_TO_RANGE
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
      v = 55,
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

  -- Visible windup ring while casting (small - just enough to telegraph)
  if self.state == unit_states['casting'] and self.castObject then
    local pct = self.castObject:get_cast_percentage() or 0
    graphics.circle(self.x, self.y, 3 + pct * 4, orange[5], 1)
  end
end

enemy_to_class['roach'] = fns

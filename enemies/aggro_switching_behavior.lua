AggroSwitchingBehavior = {}

function AggroSwitchingBehavior.apply_aggro_switching(self, config)
  config = config or {}

  self.aggro_range = config.aggro_range or 100
  self.aggro_movement_orb = config.orb_movement or MOVEMENT_TYPE_SEEK_ORB
  self.aggro_movement_player = config.player_movement or MOVEMENT_TYPE_SEEK
  self.has_aggro_switching = true

  -- Custom functions for behavior when switching states
  self.on_aggro_player = config.on_aggro_player or function(self) end
  self.on_aggro_orb = config.on_aggro_orb or function(self) end
end

function AggroSwitchingBehavior.update_aggro_switching(self)
  if not self.has_aggro_switching then return end

  local closest_troop = Helper.Target:get_closest_enemy(self)

  if closest_troop and not closest_troop.dead then
    local distance = math.distance(self.x, self.y, closest_troop.x, closest_troop.y)

    if distance <= self.aggro_range then
      -- Switch to seeking player
      if self.currentMovementAction ~= self.aggro_movement_player then
        self:set_movement_action(self.aggro_movement_player)
        self.on_aggro_player(self)
      end
    else
      -- Switch back to seeking orb
      if self.currentMovementAction ~= self.aggro_movement_orb then
        self:set_movement_action(self.aggro_movement_orb)
        self.on_aggro_orb(self)
      end
    end
  else
    -- No player units found, seek orb
    if self.currentMovementAction ~= self.aggro_movement_orb then
      self:set_movement_action(self.aggro_movement_orb)
      self.on_aggro_orb(self)
    end
  end
end

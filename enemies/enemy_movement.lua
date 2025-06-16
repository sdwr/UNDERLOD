--different ways for enemies to seek targets and move
--there will always be a possible target on screen
 

--scatter? move to a random point, or an empty area
-- and stop to attack along the way


--farthest - chase the farthest target
--good for charging enemies, or bombs, or enemies that need to be kited

--closest - chase the closest target


--how does this work with attack cooldowns?
--can we mix and match movement/targeting behavior with attack behavior?
--yes just need to set state + target appropriately

--potential new targetting functions for helper:
-- get_empty_location
-- get_target_cluster
-- get_farthest_target


--set flag on unit for behavior
--need target point for scatter
function Update_Enemy(self, dt)
  self.target_last_set = self.target_last_set or 0
  Update_Enemy_Target(self)
  Update_Enemy_Movement(self, dt)
  
end

--target
function Update_Enemy_Target(self)
  if self.target and self.target.dead then self.target = nil end

  if table.any(unit_states_can_target, function(v) return self.state == v end) then
    Set_Enemy_Target(self)
  elseif self.state == unit_states['stopped'] or self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
    if self.target and not self.target.dead then
      self:rotate_towards_object(self.target, 1)
    end
  end
end

function Set_Enemy_Target(self)
  if self.movement_style == 'chase_distant' then
    if (not self.target) or
    love.timer.getTime() - self.target_last_set > 7 then
      self.target = Helper.Unit:get_farthest_target(self)
      self.target_last_set = love.timer.getTime()
    end

  elseif self.movement_style == 'chase_closest' then
    if (not self.target) or not self:in_range()() then
      self.target = Helper.Unit:get_closest_target(self)
      self.target_last_set = love.timer.getTime()
    end
  elseif self.movement_style == 'scatter' then
    if (not self.target) or not self:in_range()() then
      self.target = Helper.Unit:get_closest_target(self)
      self.target_last_set = love.timer.getTime()
    end
  end
end

--movement

--some styles should reset target if they are out of range
--others should not
--scatter will never need to reset, because its targets are just of opportunity
--get closest will always need to reset
--get farthest should only reset periodically

--need to disentangle target from movement for scatter

function Update_Enemy_Movement(self, dt)
  if self.state == unit_states['normal'] then
    if not self:in_range()() then
      self.target = self:get_closest_object_in_shape(self.aggro_sensor, main.current.friendlies)
    end
    if self.target and self.target.dead then self.target = nil end
    if self.target then
      self:rotate_towards_object(self.target, 0.5)
    end
  elseif self.state == unit_states['stopped'] or self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
    if self.target and not self.target.dead then
      self:rotate_towards_object(self.target, 1)
    end
  end

  if self.state == unit_states['normal'] then
      if self:in_range()() then
          -- dont need to move
      elseif self.target then
          self:seek_point(self.target.x, self.target.y)
          self:rotate_towards_velocity(0.5)
      else
          -- dont need to move
      end
  elseif self.state == unit_states['frozen'] or unit_states['channeling'] then
    self:set_velocity(0,0)
  end

  self.r = self:get_angle()
  
  self.attack_sensor:move_to(self.x, self.y)
  self.aggro_sensor:move_to(self.x, self.y)

  if self.area_sensor then self.area_sensor:move_to(self.x, self.y) end
end

function Set_Enemy_Movement(self)
  if self.movement_style == 'scatter' then
    if not self.target then
      self.target = Helper.Unit:get_empty_location(self)
    end
  elseif self.movement_style == 'chase_distant' then
    if not self.target then
      self.target = Helper.Unit:get_farthest_target(self)
    end
  elseif self.movement_style == 'chase_closest' then
    if not self.target then
      self.target = Helper.Unit:get_closest_target(self)
    end
  end
end
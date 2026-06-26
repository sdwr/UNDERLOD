local fns = {}

-- Last N seconds of the windup, during which the shot angle is committed and
-- the player can dodge by moving the locked troop out of the line.
local SNIPER_AIM_LOCK_TIME = 0.75

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'sniper'

  self.color = purple[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Holds its position to aim; bullets shouldn't shove it off-aim mid-windup.
  self.knockback_immune = true

  -- Drifts around the arena randomly; doesn't need to approach since the
  -- 400-range shot covers basically the whole map.
  self.baseActionTimer = 1.5
  self.move_option_weight = 0.4
  self.stopChasingInRange = true

  self.attack_range = 400
  self.attack_sensor = Circle(self.x, self.y, self.attack_range)

  self.attack_options = {}

  local snipe = {
    name = 'snipe',
    viable = function() return Helper.Target:get_random_enemy(self) end,
    oncast = function() self.target = Helper.Target:get_random_enemy(self) end,
    cancel_on_range = false,
    instantspell = true,
    cast_sound = scout1,
    spellclass = SingleProjectile,
    spelldata = {
      group = main.current.main,
      color = purple[5],
      damage = function() return self.dmg end,
      v = 260,
      width = 22,
      height = 6,
      unit = self,
      source = 'sniper',
    },
  }

  table.insert(self.attack_options, snipe)
end

fns['draw_enemy'] = function(self)
  -- During the early part of the windup, draw the idle/normal animation; only
  -- switch to the attack/casting animation once the aim has locked (last
  -- SNIPER_AIM_LOCK_TIME seconds). The locked dashed line already telegraphs
  -- the shot - the attack pose is reserved for the imminent fire.
  local draw_state = self.state
  if self.state == unit_states['casting'] and self.castObject then
    local remaining = (self.castObject.cast_length or 0) - (self.castObject.elapsedTime or 0)
    if remaining > SNIPER_AIM_LOCK_TIME then
      draw_state = unit_states['normal']
    end
  end
  local animation_success = DrawAnimations.draw_enemy_animation(self, draw_state, self.x, self.y, 0)
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Big windup ring while charging the snipe shot
  if self.state == unit_states['casting'] and self.castObject then
    local pct = self.castObject:get_cast_percentage() or 0
    graphics.circle(self.x, self.y, 8 + pct * 14, purple[5], 1)

    -- Swap cast.target to a static snapshot so SingleProjectile (which reads
    -- target.x/y at fire time) shoots at the locked position, not the live one.
    local remaining = (self.castObject.cast_length or 0) - (self.castObject.elapsedTime or 0)
    if remaining <= SNIPER_AIM_LOCK_TIME and not self.locked_target then
      local t = self.castObject.target
      if t and t.x and t.y then
        self.locked_target = {x = t.x, y = t.y}
        self.castObject.target = self.locked_target
      end
    end

    local aim = self.locked_target or self.target
    if aim and (aim.dead == nil or not aim.dead) then
      -- Extend the aim line past the target to the screen edge so the player
      -- reads the full shot trajectory, not just sniper -> target. Project
      -- along the aim angle a distance >= the screen diagonal.
      local angle = math.atan2(aim.y - self.y, aim.x - self.x)
      local reach = math.sqrt(gw * gw + gh * gh)
      local end_x = self.x + math.cos(angle) * reach
      local end_y = self.y + math.sin(angle) * reach
      graphics.dashed_line(self.x, self.y, end_x, end_y, 4, 3, red[0], 1)
    end
  elseif self.locked_target then
    self.locked_target = nil
  end
end

enemy_to_class['sniper'] = fns

local fns = {}

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
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Big windup ring while charging the snipe shot
  if self.state == unit_states['casting'] and self.castObject then
    local pct = self.castObject:get_cast_percentage() or 0
    graphics.circle(self.x, self.y, 8 + pct * 14, purple[5], 1)

    -- Red dashed targeting line to the locked target so the player can see
    -- where the shot is going to land and reposition before it fires.
    local target = self.target
    if target and not target.dead then
      graphics.dashed_line(self.x, self.y, target.x, target.y, 4, 3, red[0], 1)
    end
  end
end

enemy_to_class['sniper'] = fns

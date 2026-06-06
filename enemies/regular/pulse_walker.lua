-- Pulse Walker: a slow melee approacher that periodically charges a
-- self-centered circular AoE and unleashes it. Each pulse plays a 0.6s
-- telegraph ring (Area at floor level, no damage) followed by the actual
-- damage Area. Walker shell follows brute/tank; pulse pattern follows the
-- bomb explosion + telegraph idea but on a recurring timer instead of a
-- trigger.

local fns = {}

PULSE_WALKER_RADIUS = 55
PULSE_WALKER_TELEGRAPH = 0.6
PULSE_WALKER_INTERVAL = 3.2

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'tank'

  self.color = yellow[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Holds its line while charging; the pulse needs to read from the body's
  -- current position so getting shoved mid-charge would dodge its own AoE.
  self.knockback_immune = true

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.baseIdleTimer = 0.3
  self.baseActionTimer = 1.5

  -- No spell-driven attacks. The pulse runs on its own timer so it doesn't
  -- compete with the chase logic in the action selector.
  self.attack_options = {}

  self.t:every(PULSE_WALKER_INTERVAL, function()
    if self.dead then return end
    self:pulse()
  end, nil, nil, 'pulse_walker_pulse')
end

fns['pulse'] = function(self)
  local telegraph_color = yellow[0]:clone()
  telegraph_color.a = 0.4
  -- Telegraph ring: zero-damage Area at floor level so it sits under the
  -- enemy sprite and reads as a warning, not a hit.
  Area{
    group = main.current.floor,
    unit = self,
    follow_unit = true,
    x = self.x,
    y = self.y,
    r = PULSE_WALKER_RADIUS,
    pick_shape = 'circle',
    duration = PULSE_WALKER_TELEGRAPH,
    dmg = 0,
    is_troop = false,
    color = telegraph_color,
  }

  -- Audible windup so it's not silent during the telegraph.
  if tick_new then
    tick_new:play{pitch = random:float(0.85, 0.95), volume = 0.8}
  end

  self.t:after(PULSE_WALKER_TELEGRAPH, function()
    if self.dead then return end
    Area{
      group = main.current.effects,
      unit = self,
      x = self.x,
      y = self.y,
      r = PULSE_WALKER_RADIUS,
      pick_shape = 'circle',
      duration = 0.18,
      dmg = self.dmg * 0.9,
      is_troop = false,
      color = yellow[0]:clone(),
    }
    if explosion_new then
      explosion_new:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    end
    camera:shake(2, 0.15)
  end)
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['pulse_walker'] = fns

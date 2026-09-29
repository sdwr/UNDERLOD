-- The central objective. Separate from troop targeting so specials keep
-- threatening the army while swarmers and tanks try to reach the orb.
LevelOrb = Object:extend()
LevelOrb.__class_name = 'LevelOrb'
LevelOrb:implement(GameObject)
LevelOrb:implement(Physics)

function LevelOrb:init(args)
  self:init_game_object(args)
  self.radius = 10
  self.max_hp = LEVEL_ORB_HP
  self.hp = self.max_hp
  self.is_level_orb = true
  self.pending_contacts = {}
  self.hurt_timer, self.pulse_timer = 0, 0
  self.color = Color('#80cdd7')
  self.dark_color = Color('#233b48')
  self.edge_color = Color('#cee9eb')
  self.hurt_color = Color('#ef7275')
  self.glow_color = Color(0.5, 0.8, 0.84, 0.12)
  self.clear_color = Color(0.5, 0.8, 0.84, 0)
  self:set_as_circle(self.radius, 'static', 'level_orb')
  self.fixture:setSensor(true)
end

function LevelOrb:is_active()
  local arena = self.parent
  return not self.dead and not arena.dead and not arena.died
    and not arena.won and not arena.level_cleared
    and arena.spawn_manager and ARENA_COMBAT_STATES[arena.spawn_manager.state]
end

function LevelOrb:on_trigger_enter(other)
  if not self:is_active() or not Targets_Level_Orb(other) or other.dead
    or other.orb_contact_pending then return end
  other.orb_contact_pending = true
  self.pending_contacts[#self.pending_contacts+1] = other
end

function LevelOrb:resolve_contacts()
  local contacts = self.pending_contacts
  self.pending_contacts = {}
  for _, enemy in ipairs(contacts) do
    enemy.orb_contact_pending = nil
    if self:is_active() and not enemy.dead then
      -- The troop-only chip-damage multiplier does not protect the objective.
      -- Wounding an attacker still softens its final impact.
      local fraction = enemy.max_hp and enemy.max_hp > 0
        and math.clamp(enemy.hp / enemy.max_hp, 0, 1) or 1
      self:hit((enemy.dmg or 0) * fraction)
      HitCircle{group = self.parent.effects, x = enemy.x, y = enemy.y,
        rs = 10, color = orange[0], duration = 0.18}
      for _ = 1, 3 do
        HitParticle{group = self.parent.effects, x = enemy.x, y = enemy.y, color = orange[0]}
      end
      enemy:die()
    end
  end
end

function LevelOrb:hit(damage)
  if not self:is_active() then return end
  local taken = math.min(self.hp, math.max(0, damage))
  if taken == 0 then return end
  self.hp = self.hp - taken
  self.parent.damage_taken = (self.parent.damage_taken or 0) + taken
  self.hurt_timer = 0.2
  hit1:play{pitch = 1, volume = 0.6}
  camera:shake(1, 0.12)
  if self.hp <= 0 then
    self.dead = true
    self.parent:die('orb')
  end
end

function LevelOrb:update(dt)
  if self.dead then return end
  self:update_game_object(dt)
  self.hurt_timer = math.max(0, self.hurt_timer - dt)
  self.pulse_timer = self.pulse_timer + dt
end

function LevelOrb:draw_ground()
  if self.dead then return end
  graphics.gradient_circle(self.x, self.y, 23, self.glow_color, self.clear_color)
end

function LevelOrb:draw()
  if self.dead then return end
  local fraction = math.clamp(self.hp / self.max_hp, 0, 1)
  local color = (self.hurt_timer > 0 or fraction <= 0.25) and self.hurt_color or self.color
  local radius = self.radius + 0.4 * math.sin(self.pulse_timer * 2)
  graphics.circle(self.x, self.y, radius+2, self.dark_color)
  -- A circular segment fills from the bottom; its flat surface is the HP
  -- level. Closed arcs clip to the circle without changing stencil state.
  if fraction >= 1 then
    graphics.circle(self.x, self.y, radius, color)
  elseif fraction > 0 then
    local angle = math.asin(1 - 2*fraction)
    graphics.arc('closed', self.x, self.y, radius, angle, math.pi-angle, color)
  end
  graphics.circle(self.x-3, self.y-3, 2, self.edge_color)
  local outline_color = self.hurt_timer > 0 and self.hurt_color or self.edge_color
  graphics.circle(self.x, self.y, radius+2, outline_color, 1)
end
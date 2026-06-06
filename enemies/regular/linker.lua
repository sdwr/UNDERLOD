-- Linker: spawns in pairs (group_size = 2 in the spawn config) with a
-- damaging beam tether between them. The two linkers drift independently,
-- so the beam swings around the arena — troops standing on the line take
-- periodic damage. When one linker dies the tether breaks and the partner
-- becomes a harmless drifter. Walker shell follows brute/tank; pair-up
-- logic runs once on the first frame; tether-damage and beam-draw run
-- every tick.

local fns = {}

LINKER_BEAM_WIDTH = 6
LINKER_TICK_RATE = 0.18
LINKER_DAMAGE_FRAC = 0.35

-- Standalone helper: minimum distance from point P to segment AB. Used
-- per-tick to decide which troops are standing on the beam.
local function point_to_segment_distance(px, py, ax, ay, bx, by)
  local abx, aby = bx - ax, by - ay
  local apx, apy = px - ax, py - ay
  local ab_len2 = abx * abx + aby * aby
  local t
  if ab_len2 > 0 then
    t = (apx * abx + apy * aby) / ab_len2
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
  else
    t = 0
  end
  local cx, cy = ax + t * abx, ay + t * aby
  local dx, dy = px - cx, py - cy
  return math.sqrt(dx * dx + dy * dy)
end

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'sniper'

  self.color = blue[5]:clone()
  Set_Enemy_Shape(self, self.size)

  self.class = 'special_enemy'

  -- Beam holds its position more cleanly if linkers don't get shoved into
  -- each other on every hit.
  self.knockback_resistance = self.knockback_resistance or 0.6

  -- No attacks of its own; the threat is the tether to its partner.
  self.attack_options = {}

  self.baseIdleTimer = 0.3
  self.baseActionTimer = 2
  self.move_option_weight = 0.5
  self.stopChasingInRange = false

  self.linker_pair = nil

  -- Pair up on the next frame. Both linkers from the same spawn group land
  -- in the arena in the same frame; deferring by 0.1s guarantees both
  -- exist before the search runs. First linker to wake up grabs the first
  -- unpaired partner it finds.
  self.t:after(0.1, function()
    if self.dead or self.linker_pair then return end
    local enemies = main.current.main:get_objects_by_classes(main.current.enemies)
    for _, e in ipairs(enemies) do
      if e ~= self and e.type == 'linker' and not e.dead and not e.linker_pair then
        self.linker_pair = e
        e.linker_pair = self
        break
      end
    end
  end)

  -- Beam tick: scan troops along the segment between self and pair and
  -- damage any within LINKER_BEAM_WIDTH. Only one linker of the pair runs
  -- the tick — gated by id ordering so we don't double up the damage.
  self.t:every(LINKER_TICK_RATE, function()
    if self.dead then return end
    local p = self.linker_pair
    if not p or p.dead then return end
    -- Deterministic owner: only the linker with the lower id ticks damage.
    if self.id and p.id and self.id > p.id then return end

    local troops = main.current.main:get_objects_by_classes(main.current.friendlies)
    for _, troop in ipairs(troops) do
      if troop and not troop.dead then
        local d = point_to_segment_distance(troop.x, troop.y, self.x, self.y, p.x, p.y)
        if d < LINKER_BEAM_WIDTH then
          troop:hit(self.dmg * LINKER_DAMAGE_FRAC, self, nil, true, true)
        end
      end
    end
  end, nil, nil, 'linker_beam_tick')

  -- Sever the tether on death so the partner stops drawing/ticking a beam
  -- to a corpse. The partner stays alive but defangs to a melee body.
  self.state_change_functions['death'] = function(self)
    if self.linker_pair and not self.linker_pair.dead then
      self.linker_pair.linker_pair = nil
    end
    self.linker_pair = nil
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end

  -- Beam render: only one linker of the pair draws it. Use the same
  -- id-ordering as the damage tick so the draw lines up with the hit zone.
  local p = self.linker_pair
  if p and not p.dead and self.id and p.id and self.id <= p.id then
    local beam_color = blue[5]:clone()
    graphics.line(self.x, self.y, p.x, p.y, beam_color, LINKER_BEAM_WIDTH)
    -- Inner bright line so the beam reads as "active" rather than decorative.
    local inner = blue[0]:clone()
    graphics.line(self.x, self.y, p.x, p.y, inner, 1)
  end
end

enemy_to_class['linker'] = fns

-- A swinging sword arc spell. Damages enemies in a cone in front of the caster
-- while drawing a sword that sweeps through the arc over the spell duration.

Sword_Swing_Spell = Area_Spell:extend()

function Sword_Swing_Spell:init(args)
  args.duration = args.duration or 0.25
  args.fade_duration = args.fade_duration or 0.05
  args.pick_shape = args.pick_shape or 'circle'
  args.damage_ticks = false
  args.area_type = nil
  args.apply_primary_hit_to_target = false

  self.swing_half_angle = args.swing_half_angle or (math.pi / 3)
  self.blade_length = args.blade_length or 50
  self.swing_start_angle = args.swing_start_angle or 0

  Sword_Swing_Spell.super.init(self, args)

  self.swing_progress = 0
  self.swing_total = self.duration
end

function Sword_Swing_Spell:apply_damage()
  if not self.unit or self.unit.dead then return {}, false end

  local target_group = self.is_troop and main.current.enemies or main.current.friendlies
  local targets_in_area = main.current.main:get_objects_in_shape(self.shape, target_group)

  local hits = {}
  local hit_success = false

  for _, target in ipairs(targets_in_area) do
    if target and not target.dead and not self.targets_hit_map[target.id] then
      local angle_to = math.atan2(target.y - self.y, target.x - self.x)
      local diff = ((angle_to - self.swing_start_angle + 3*math.pi) % (2*math.pi)) - math.pi
      if math.abs(diff) <= self.swing_half_angle then
        if self.damage > 0 then
          Helper.Damage:chained_hit(target, self.damage, self.unit, self.damage_type, true)
        end
        self.targets_hit_map[target.id] = true
        table.insert(hits, target)
        hit_success = true
      end
    end
  end
  return hits, hit_success
end

function Sword_Swing_Spell:update(dt)
  self:update_game_object(dt)
  self.current_duration = self.current_duration + dt

  -- follow caster so the arc stays in front of the unit
  if self.unit and not self.unit.dead then
    self.x, self.y = self.unit.x, self.unit.y
    self.shape:move_to(self.x, self.y)
  end

  -- damage continuously through the swing, but each enemy only once
  self:apply_damage()

  if self.current_duration > self.duration_minus_fade then
    self:fade_out()
  end
  if self.current_duration > self.duration then
    self:die()
  end
end

function Sword_Swing_Spell:draw()
  if self.hidden then return end
  if not self.unit or self.unit.dead then return end

  local t = math.clamp(self.current_duration / self.swing_total, 0, 1)
  local sword_angle = self.swing_start_angle - self.swing_half_angle + 2 * self.swing_half_angle * t

  local cx, cy = self.x, self.y
  local blade_length = self.blade_length
  local blade_color = white[0]
  local hilt_color = white[-6]

  graphics.push(cx, cy, sword_angle)

  graphics.circle(cx - 3, cy, 1.8, hilt_color)
  graphics.rectangle2(cx - 3, cy - 1.5, 9, 3, nil, nil, hilt_color)
  graphics.rectangle2(cx + 4.5, cy - 5, 2.5, 10, nil, nil, hilt_color)
  graphics.polygon({
    cx + 7, cy - 2.5,
    cx + 7, cy + 2.5,
    cx + blade_length, cy
  }, blade_color)

  graphics.pop()
end

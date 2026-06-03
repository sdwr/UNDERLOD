-- An autonomous sword-swinging troop. Visually wields the no-home-base sword,
-- but acquires targets and swings on cooldown like the other troops.

SwordWeapon_Troop = Troop:extend()

function SwordWeapon_Troop:init(data)
  self.base_attack_range = TROOP_SWORD_WEAPON_RANGE or 55
  SwordWeapon_Troop.super.init(self, data)

  self.backswing = 0.1
  self.base_attack_area = self.base_attack_range
  self.swing_half_angle = math.pi / 3
  self.swing_visual_angle = 0
end

function SwordWeapon_Troop:update(dt)
  SwordWeapon_Troop.super.update(self, dt)
  self.attack_sensor.rs = self.attack_range
end

function SwordWeapon_Troop:draw()
  SwordWeapon_Troop.super.draw(self)
  self:draw_held_sword()
end

function SwordWeapon_Troop:draw_held_sword()
  -- Only draw the resting sword when not actively swinging (the spell renders the swing)
  if self.state == unit_states['casting'] then return end

  local facing = self.r or 0
  local sword_angle = facing + math.pi

  local cx, cy = self.x, self.y
  local blade_length = (self.attack_range or self.base_attack_range) * 0.55
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

function SwordWeapon_Troop:play_attack_sound()
  if _G['swordsman1'] then
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end
end

function SwordWeapon_Troop:set_character()
  self.attack_sensor = Circle(self.x, self.y, self.base_attack_range)
  self.backswing = 0.1
  self:set_state_functions()
end

function SwordWeapon_Troop:create_spelldata(cast_target)
  local angle = math.atan2((cast_target and cast_target.y or self.y) - self.y,
                           (cast_target and cast_target.x or self.x) - self.x)
  return {
    group = main.current.effects,
    sound = self.play_attack_sound,
    damage = function() return self.dmg end,
    radius = self.base_attack_range,
    duration = 0.25,
    fade_duration = 0.05,
    damage_ticks = false,
    color = white[0],
    opacity = 0.0,
    swing_half_angle = self.swing_half_angle,
    swing_start_angle = angle,
    blade_length = self.base_attack_range,
    unit = self,
    is_troop = true,
  }
end

function SwordWeapon_Troop:setup_cast(cast_target)
  local cast_data = {
    name = 'sword_swing',
    viable = function() return Helper.Spell:target_is_in_range(self, self.attack_sensor.rs, cast_target, false) end,
    oncast = function() end,
    oncastfinish = function() self:stretch_on_attack() end,
    unit = self,
    target = cast_target,
    backswing = self.backswing,
    instantspell = true,
    spellclass = Sword_Swing_Spell,
    spelldata = self:create_spelldata(cast_target),
  }
  self.castObject = Cast(cast_data)
end

function SwordWeapon_Troop:instant_attack(cast_target, damage_multi)
  local spelldata = self:create_spelldata(cast_target)
  spelldata.on_attack_callbacks = false
  spelldata.unit = self
  spelldata.target = cast_target
  if damage_multi and damage_multi ~= 1 then
    spelldata.damage = function() return self.dmg * damage_multi end
  end
  Sword_Swing_Spell(spelldata)
end

function SwordWeapon_Troop:set_state_functions()
  self.state_always_run_functions['always_run'] = function(self) end
  self.state_change_functions['death'] = function(self)
    self:cancel_cast()
    Helper.Unit:unclaim_target(self)
  end
end

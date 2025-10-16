-- Touch behavior helper functions for enemies
-- This module provides reusable touch behavior that can be applied to different enemy types

TouchBehavior = {}

-- Apply standard touch behavior to an enemy
-- Config options:
--   touch_aoe_radius: Explosion radius when touched (default: 25)
--   touch_damage_multiplier: Damage multiplier for explosion (default: 1.5)
function TouchBehavior.apply_touch_behavior(enemy, config)
  config = config or {}

  enemy.color = green[0]:clone()
  enemy.is_green = true
  enemy.invulnerable = true
  enemy.can_be_touched = true

  enemy.touch_aoe_radius = config.touch_aoe_radius or 25
  enemy.touch_damage_multiplier = config.touch_damage_multiplier or 1.5

  enemy.rejectDamageCallback = function()
    if tink then
      tink:play{pitch = random:float(1.2, 1.4), volume = 0.3}
    end
  end
end

-- Apply touch fade behavior to an enemy (alternates between green/red states)
-- Config options: same as apply_touch_behavior, plus:
--   color_switch_interval: Time between color switches (default: 2.5)
--   fade_duration: Duration of color transition (default: 0.5)
function TouchBehavior.apply_touch_fade_behavior(enemy, config)
  config = config or {}

  enemy.color = green[0]:clone()
  enemy.is_green = true
  enemy.color_switch_timer = 0
  enemy.color_switch_interval = config.color_switch_interval or 2.5
  enemy.fade_progress = 0
  enemy.fade_duration = config.fade_duration or 0.5
  enemy.is_fading = false

  enemy.invulnerable = true
  enemy.can_be_touched = true

  enemy.touch_aoe_radius = config.touch_aoe_radius or 25
  enemy.touch_damage_multiplier = config.touch_damage_multiplier or 1.5

  enemy.green_color = green[0]:clone()
  enemy.red_color = red[0]:clone()

  enemy.rejectDamageCallback = function()
    if tink then
      tink:play{pitch = random:float(1.2, 1.4), volume = 0.3}
    end
  end
end

-- Update function for touch fade color transitions
function TouchBehavior.update_touch_fade_color(enemy, dt)
  enemy.color_switch_timer = enemy.color_switch_timer + dt

  if enemy.color_switch_timer >= enemy.color_switch_interval then
    enemy.is_fading = true
    enemy.fade_progress = 0
    enemy.color_switch_timer = 0
  end

  if enemy.is_fading then
    enemy.fade_progress = enemy.fade_progress + dt / enemy.fade_duration

    local t = math.min(enemy.fade_progress, 1)
    if enemy.is_green then
      enemy.color.r = math.lerp(t, enemy.green_color.r, enemy.red_color.r)
      enemy.color.g = math.lerp(t, enemy.green_color.g, enemy.red_color.g)
      enemy.color.b = math.lerp(t, enemy.green_color.b, enemy.red_color.b)
    else
      enemy.color.r = math.lerp(t, enemy.red_color.r, enemy.green_color.r)
      enemy.color.g = math.lerp(t, enemy.red_color.g, enemy.green_color.g)
      enemy.color.b = math.lerp(t, enemy.red_color.b, enemy.green_color.b)
    end

    if enemy.fade_progress >= 1 then
      enemy.fade_progress = 1
      enemy.is_fading = false
      enemy.is_green = not enemy.is_green
    end
  end
end

-- Draw function for touch enemies (adds pulsing visual effect)
function TouchBehavior.draw_touch_visual(enemy)
  if enemy.is_green and not enemy.is_fading then
    local pulse = math.sin(love.timer.getTime() * 4) * 0.1 + 0.9
    graphics.push(enemy.x, enemy.y, 0, pulse, pulse)
    local outline_color = green[0]:clone()
    outline_color.a = 0.3
    graphics.circle(enemy.x, enemy.y, enemy.shape.h, outline_color, 2)
    graphics.pop()
  end
end

-- Collision handler for touch enemies
function TouchBehavior.handle_touch_collision(enemy, other)
  if enemy.is_green then
    TouchBehavior.create_touch_explosion(enemy)
    enemy:die()
    return true
  end
  return false
end

-- Create explosion when touch enemy is touched
function TouchBehavior.create_touch_explosion(enemy)
  Area_Spell{
    group = main.current.effects,
    unit = enemy,
    is_troop = true,
    x = enemy.x,
    y = enemy.y,
    damage = function() return enemy.dmg * enemy.touch_damage_multiplier end,
    radius = enemy.touch_aoe_radius,
    duration = 0.2,
    pick_shape = 'circle',
    color = green[0],
    opacity = 0.08,
    line_width = 2,
  }

  gold1:play{pitch = random:float(1.1, 1.3), volume = 0.2}
end

-- Utility functions for drawing animations
-- Contains drawing functions for various game objects

DrawAnimations = {}

-- Draw enemy animation with spritesheet, buffs, and status effects
function DrawAnimations.draw_enemy_animation(enemy, state, x, y, r)
  -- Safety checks from Helper.Unit
  if not enemy.spritesheet then
    return false
  end
  if not enemy.icon then
    print('no icon for unit ' .. enemy.type)
    return false
  end

  local direction = 1
  --only update direction if not stunned
  if enemy.state ~= unit_states['stunned'] then
    direction = enemy:is_facing_left() and -1 or 1
    enemy.last_direction = direction
  else
    direction = enemy.last_direction
  end

  local sprite_size = enemy_sprite_sizes[enemy.icon]
  if not sprite_size then
    print('no sprite size for unit ' .. enemy.type)
    return false
  end

  local animation = nil
  local image = nil
  local anim_set = enemy.spritesheet[state] or enemy.spritesheet['normal']
  if anim_set then
    animation = anim_set[1]
    image = anim_set[2]
  end

  if not animation or not image then
    print('no animation or image for unit ' .. enemy.type)
    return false
  end

  local sprite_scale = enemy_sprite_scales[enemy.icon]
  if not sprite_scale then
    print('no sprite scale for unit ' .. enemy.type)
    return false
  end
  
  -- Calculate scale using global constants
  local scale_x = (enemy.shape.w / sprite_size[1]) * sprite_scale * direction
  local scale_y = (enemy.shape.h / sprite_size[2]) * sprite_scale
  
  local frame_width, frame_height = animation:getDimensions()
  local frame_center_x = frame_width / 2
  local frame_center_y = frame_height / 2

  -- Convert world coordinates to screen coordinates for full resolution canvas
  local screen_x, screen_y = world_to_screen(x, y)
  local screen_scale = math.floor(wh/gh)

  

  -- Add drawing functions to full_res_character_canvas
  table.insert(full_res_character_draws, function()

    love.graphics.setColor(1, 1, 1, 1)
    graphics.push(screen_x, screen_y, 0, enemy.hfx.hit.x, enemy.hfx.hit.x)
      animation:draw(image.image, screen_x, screen_y, r, scale_x * screen_scale, scale_y * screen_scale, frame_center_x, frame_center_y)
    graphics.pop()

    local mask_color = nil
    if enemy.buffs['freeze'] then
      mask_color = FREEZE_MASK_COLOR
    elseif enemy.buffs['stunned'] then
      mask_color = STUN_MASK_COLOR
    elseif enemy.state == unit_states['knockback'] then
      mask_color = KNOCKBACK_MASK_COLOR
    elseif enemy.buffs['burn'] then
      mask_color = BURN_MASK_COLOR
    end

    if mask_color ~= nil then
      love.graphics.setColor(mask_color.r, mask_color.g, mask_color.b, mask_color.a)
      animation:draw(image.image, screen_x, screen_y, r, scale_x * screen_scale, scale_y * screen_scale, frame_center_x, frame_center_y)
      love.graphics.setColor(1, 1, 1, 1)
    end
  end)

  return true
end 
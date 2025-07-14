-- Utility functions for drawing animations
-- Contains drawing functions for various game objects

DrawAnimations = {}

-- Calculate base scale for enemy animations
function DrawAnimations.calculate_enemy_scale(enemy)
  if not enemy or not enemy.icon then
    return 1, 1
  end
  
  local sprite_size = enemy_sprite_sizes[enemy.icon]
  local sprite_scale = enemy_sprite_scales[enemy.icon]
  
  if not sprite_size or not sprite_scale then
    return 1, 1
  end
  
  local base_scale_x = (enemy.shape.w / sprite_size[1]) * sprite_scale
  local base_scale_y = (enemy.shape.h / sprite_size[2]) * sprite_scale
  
  return base_scale_x, base_scale_y
end

-- Draw a specific animation with given parameters
function DrawAnimations.draw_specific_animation(unit, anim_set, x, y, r, scale_x, scale_y, alpha, color, useHfx, useFlash)
  -- This function no longer needs the 'use_hfx' or 'use_flash' booleans
  if not anim_set or not anim_set[1] or not anim_set[2] then
      return false
  end

  local animation = anim_set[1]
  local image = anim_set[2]
  local frame_width, frame_height = animation:getDimensions()
  local frame_center_x, frame_center_y = frame_width / 2, frame_height / 2
  local screen_x, screen_y = world_to_screen(x, y)
  local screen_scale = sx

  local outline_thickness = 2 / sx

  table.insert(full_res_character_draws, function()
      -- 1. SET UP THE SHADER
      hit_effect_shader:set()

      local is_hit = useFlash and unit.hfx and unit.hfx.hit and unit.hfx.hit.f
      local sprite_w, sprite_h = animation:getDimensions()

      -- Send all data to the shader
      --outline is only drawing on one side of the sprite, disable for now
      hit_effect_shader:send("use_outline", false)
      hit_effect_shader:send("use_flash", is_hit)
      hit_effect_shader:send("outline_color", {1.0, 1.0, 1.0, 1.0}) -- White outline
      hit_effect_shader:send("flash_color", {1.0, 1.0, 1.0, 0.2})   -- Bright white flash
      hit_effect_shader:send("outline_thickness", outline_thickness)
      hit_effect_shader:send("texture_size", {sprite_w, sprite_h})

      -- 2. DRAW THE SPRITE
      if color then
          love.graphics.setColor(color.r, color.g, color.b, alpha or color.a or 1)
      else
          love.graphics.setColor(1, 1, 1, alpha or 1)
      end

      local hfx_scale = (useHfx and unit.hfx.hit.x) or 1.0
      graphics.push(screen_x, screen_y, r or 0, hfx_scale, hfx_scale)
          animation:draw(image.image, screen_x, screen_y, 0, scale_x * screen_scale, scale_y * screen_scale, frame_center_x, frame_center_y)
      graphics.pop()

      love.graphics.setColor(1, 1, 1, 1)

      -- 3. UNSET THE SHADER
      hit_effect_shader:unset()
  end)
  return true -- Indicate success
end

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

  local anim_set = enemy.spritesheet[state] or enemy.spritesheet['normal']
  if not anim_set then
    print('no animation or image for unit ' .. enemy.type)
    return false
  end

  -- Calculate scale using the helper function
  local base_scale_x, base_scale_y = DrawAnimations.calculate_enemy_scale(enemy)
  local scale_x = base_scale_x * direction
  local scale_y = base_scale_y

  -- Draw the base animation using the helper function
  local draw_success = DrawAnimations.draw_specific_animation(enemy, anim_set, x, y, r, scale_x, scale_y, 1.0, nil, true, true)
  
  if draw_success then

    
    -- Add status effect overlays
    local mask_color = nil
    if enemy.buffs['freeze'] then
      mask_color = FREEZE_MASK_COLOR
    elseif enemy.buffs['stunned'] then
      mask_color = STUN_MASK_COLOR

    elseif enemy.buffs['burn'] then
      mask_color = BURN_MASK_COLOR
    end

    if mask_color ~= nil then
      DrawAnimations.draw_specific_animation(enemy, anim_set, x, y, r, scale_x, scale_y, mask_color.a, mask_color, true, false)
    end
  end

  return draw_success
end

-- Draw death animation with spritesheet, rotation, and scaling effects
function DrawAnimations.draw_death_animation(enemy, anim_set, x, y, rotation, scale, alpha)

  if not anim_set then
    print('no animation or image for death animation of unit ' .. enemy.type)
    return false
  end

  -- Calculate base scale using the helper function
  local base_scale_x, base_scale_y = DrawAnimations.calculate_enemy_scale(enemy)
  
  -- Apply additional scaling and rotation
  local final_scale_x = base_scale_x * scale
  local final_scale_y = base_scale_y * scale

  -- Draw the animation using the helper function
  return DrawAnimations.draw_specific_animation(enemy, anim_set, x, y, rotation, final_scale_x, final_scale_y, alpha, nil, false, false)
end

-- Create a normalized animation for a specific duration
function DrawAnimations.create_normalized_animation(enemy, state, cast_time)
  -- Safety checks
  if not enemy.spritesheet then
    return nil
  end
  
  if not enemy.spritesheet[state] then
    print('no animation for unit ' .. enemy.type)
  end

  local anim_set = enemy.spritesheet[state] or enemy.spritesheet['normal']
  if not anim_set then
    return nil
  end
  
  local original_animation = anim_set[1]
  local image = anim_set[2]
  
  if not original_animation then
    return nil
  end
  
  -- Get the original animation's frames
  local original_frames = original_animation.frames
  local frame_count = #original_frames
  
  -- Calculate the new speed to normalize to cast_time
  -- speed = cast_time / frame_count (seconds per frame)
  local new_speed = cast_time / frame_count
  
  -- Create new animation using the same frames but with normalized speed
  local normalized_animation = anim8.newAnimation(original_frames, new_speed)
  
  -- Return the normalized animation
  return normalized_animation
end
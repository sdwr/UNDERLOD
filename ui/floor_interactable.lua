FloorInteractable = Object:extend()
FloorInteractable:implement(GameObject)

function FloorInteractable:init(args)
  self:init_game_object(args)
  
  -- Required parameters
  self.x = args.x
  self.y = args.y
  self.parent = args.parent -- Arena/Level that owns this interaction
  self.main_group = args.main_group -- Group to search for units in
  
  -- Interaction configuration
  self.interaction_radius = args.interaction_radius or 35
  self.activation_duration = args.activation_duration or 2.0
  self.unit_classes = args.unit_classes or troop_classes -- What units can trigger this
  
  -- Visual configuration
  self.interaction_color = args.color or yellow[0]
  self.interaction_highlight_color = args.highlight_color or yellow[2]
  self.interaction_visual_scale = args.visual_scale or 1.0
  
  -- Audio configuration
  self.interaction_hover_sound = args.interaction_hover_sound or ui_modern_hover
  self.interaction_activation_sound = args.interaction_activation_sound or ui_modern_hover
  self.interaction_failed_sound = args.interaction_failed_sound or error1
  
  -- State flags
  self.interaction_is_active = true
  self.interaction_is_hovered = false
  self.interaction_is_charging = false
  self.interaction_is_disabled = false -- New flag for disabled state
  self.interaction_failed_activation = false
  self.interaction_spawn_protection = true
  
  -- Timers
  self.interaction_hover_timer = 0
  self.interaction_charge_timer = 0
  self.interaction_shake_timer = 0
  self.interaction_shake_duration = 2.0
  self.interaction_shake_intensity = 0

  self.interaction_particle_count = 10
  
  -- Audio
  self.interaction_hover_sound_instance = nil
  self.interaction_sound_pitch_base = 1.0
  self.interaction_hover_sound_pitch = self.interaction_sound_pitch_base
  self.interaction_hover_sound_pitch_next = 0.5
  
  -- Callbacks
  self.on_activation = args.on_activation
  self.on_failed_activation = args.on_failed_activation
  self.on_hover_start = args.on_hover_start
  self.on_hover_end = args.on_hover_end
  
  -- Custom disable function
  self.disable_interaction = args.disable_interaction
  
  -- Create collision sensor
  self.interaction_aggro_sensor = Circle(self.x, self.y, self.interaction_radius)
end

function FloorInteractable:update(dt)
  self:update_game_object(dt)
  
  -- Update timers
  if self.interaction_is_hovered and not self.interaction_is_disabled then
    self.interaction_hover_timer = self.interaction_hover_timer + dt
    self.interaction_hover_sound_pitch_next = self.interaction_hover_sound_pitch_next - dt
    if self.interaction_hover_sound_pitch_next <= 0 then
      self:interaction_hover_sound_pitch_up()
    end
    -- Start shaking immediately when unit is on it
    if self.interaction_shake_timer <= 0 then
      self:interaction_start_shake()
    end
  else
    -- Reset when unit leaves
    self.interaction_hover_timer = 0
    self.interaction_shake_timer = 0
    self.interaction_shake_intensity = 0
  end
  
  -- Update shake timer
  if self.interaction_shake_timer > 0 then
    self.interaction_shake_timer = self.interaction_shake_timer - dt
    self.interaction_shake_intensity = math.max(0, self.interaction_shake_timer / self.interaction_shake_duration)
    
    -- Activate after duration of shaking
    if self.interaction_shake_timer <= 0 then
      self:interaction_complete_activation()
    end
  end
  
  -- Check for unit collisions
  self:check_unit_collision()
end

function FloorInteractable:can_interact()
  return not self.interaction_is_disabled and not self.interaction_failed_activation
end

function FloorInteractable:currently_interacting()
  return self.interaction_is_hovered
end

function FloorInteractable:check_unit_collision()
  -- Check if interaction is disabled by custom function
  local was_disabled = self.interaction_is_disabled
  self.interaction_is_disabled = self.disable_interaction and self:disable_interaction()
  
  -- If newly disabled, clear hover state
  if self.interaction_is_disabled then
    if not was_disabled then
      self:interaction_deactivate()
    end
    return
  end

  if self.main_group then
    local objects = self.main_group:get_objects_in_shape(self.interaction_aggro_sensor, self.unit_classes)
    if #objects > 0 then
      if self:can_interact() and not self.interaction_is_hovered then
        self:interaction_activate()
      end
    else
      --clear failed activation if unit leaves
      if self.interaction_failed_activation then
        self.interaction_failed_activation = false
      end
      self:interaction_deactivate()
    end
  end
end

function FloorInteractable:interaction_start_shake()
  if self.interaction_shake_timer <= 0 then
    self.interaction_shake_timer = self.activation_duration
    self.interaction_shake_intensity = 1
  end
  if not self.interaction_hover_sound_instance then
    self.interaction_hover_sound_instance = self.interaction_hover_sound:play{pitch = self.interaction_hover_sound_pitch, volume = 1}
  end
end

function FloorInteractable:interaction_stop_shake()
  self.interaction_hover_timer = 0
  self.interaction_shake_timer = 0
  self.interaction_shake_intensity = 0
  if self.interaction_hover_sound_instance then
    self.interaction_hover_sound_instance:stop()
    self.interaction_hover_sound_instance = nil
  end
  self.interaction_hover_sound_pitch = self.interaction_sound_pitch_base
  self.interaction_hover_sound_pitch_next = 0.5
end

function FloorInteractable:interaction_hover_sound_pitch_up()
  self.interaction_hover_sound_pitch_next = 0.5
  self.interaction_hover_sound_pitch = self.interaction_hover_sound_pitch + 0.3

  if self.interaction_hover_sound_instance then
    self.interaction_hover_sound_instance:stop()
  end
  self.interaction_hover_sound_instance = self.interaction_hover_sound:play{pitch = self.interaction_hover_sound_pitch, volume = 1}
end

function FloorInteractable:interaction_complete_activation()
  if self.interaction_is_triggered then return end
  
  self.interaction_is_triggered = true
  
  -- Play activation sound
  if self.interaction_activation_sound then
    self.interaction_activation_sound:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  end
  
  -- Camera shake
  if self.interaction_camera_shake then
    camera:shake(self.interaction_camera_shake.intensity, self.interaction_camera_shake.duration)
  end
  
  -- Call activation callback
  if self.on_activation then
    local success = self:on_activation()
    if not success then
      self.interaction_failed_activation = true
      self.interaction_failed_sound:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self:interaction_deactivate()
      if self.on_failed_activation then
        self:on_failed_activation()
      end
    end
  end
end

function FloorInteractable:interaction_activate()
  self.interaction_is_hovered = true
  self.interaction_failed_activation = false
  if self.on_hover_start then
    self:on_hover_start()
  end
end

function FloorInteractable:interaction_deactivate()
  self.interaction_is_active = false
  self.interaction_is_hovered = false
  self.interaction_spawn_protection = false
  self.interaction_is_triggered = false
  self:interaction_stop_shake()

  if self.on_hover_end then
    self:on_hover_end()
  end
end

function FloorInteractable:die()
  self:interaction_deactivate()
  self.dead = true
end 
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
  self.interaction_hover_sound = args.hover_sound or ui_modern_hover
  self.interaction_activation_sound = args.activation_sound or ui_switch1
  self.interaction_sound_pitch_base = args.sound_pitch_base or 1.0
  
  -- Callback functions
  self.on_activation = args.on_activation -- Called when fully activated
  self.on_hover_start = args.on_hover_start -- Called when unit enters
  self.on_hover_end = args.on_hover_end -- Called when unit leaves
  self.on_failed_activation = args.on_failed_activation -- Called on failure
  
  -- Visual effects configuration
  self.interaction_particle_count = args.particle_count or 8
  self.interaction_camera_shake = args.camera_shake or {intensity = 3, duration = 0.5}
  self.interaction_show_tooltip = args.show_tooltip or false
  
  -- Internal state
  self.interaction_is_active = true
  self.interaction_is_triggered = false
  self.interaction_hover_timer = 0
  self.interaction_shake_timer = 0
  self.interaction_shake_intensity = 0
  self.interaction_is_hovered = false
  self.interaction_failed_activation = false
  
  -- Audio state
  self.interaction_hover_sound_instance = nil
  self.interaction_hover_sound_pitch = self.interaction_sound_pitch_base
  self.interaction_hover_sound_pitch_next = 0.5
  
  -- Detection setup
  self.interaction_aggro_sensor = Circle(self.x, self.y, self.interaction_radius)
  self.interaction_spawn_protection = true
end

function FloorInteractable:update(dt)
  self:update_game_object(dt)
  
  if self.dead then return end
  
  -- Check for unit collision
  if self.interaction_is_active and not self.interaction_is_triggered then
    self:check_unit_collision()
  end
  
  -- Update hover timer and shake
  if self.interaction_is_hovered and not self.interaction_failed_activation then
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
  
  -- Update shake
  if self.interaction_shake_timer > 0 then
    self.interaction_shake_timer = self.interaction_shake_timer - dt
    self.interaction_shake_intensity = math.max(0, self.interaction_shake_timer / self.activation_duration)
    
    -- Activate after duration of shaking
    if self.interaction_shake_timer <= 0 then
      self:interaction_complete_activation()
    end
  end
end

function FloorInteractable:check_unit_collision()
  if self.main_group then
    local objects = self.main_group:get_objects_in_shape(self.interaction_aggro_sensor, self.unit_classes)
    if #objects > 0 then
      -- Only activate if spawn protection is off
      if self.interaction_spawn_protection then
        self.interaction_is_hovered = false
      else
        if not self.interaction_is_hovered then
          self.interaction_is_hovered = true
          if self.on_hover_start then
            self:on_hover_start()
          end
        end
      end
    else
      self.interaction_spawn_protection = false
      if self.interaction_is_hovered then
        self.interaction_is_hovered = false
        self.interaction_failed_activation = false
        if self.on_hover_end then
          self:on_hover_end()
        end
      end
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
  
  -- Visual feedback
  for i = 1, self.interaction_particle_count do
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.interaction_color}
  end
  
  -- Camera shake
  if self.interaction_camera_shake then
    camera:shake(self.interaction_camera_shake.intensity, self.interaction_camera_shake.duration)
  end
  
  -- Call activation callback
  if self.on_activation then
    self:on_activation()
  end
end

function FloorInteractable:interaction_deactivate()
  self.interaction_is_active = false
  self:interaction_stop_shake()
end

function FloorInteractable:die()
  self:interaction_deactivate()
  self.dead = true
end 
-- File: Area.lua (The new version)

Area_Spell = Spell:extend()

function Area_Spell:init(args)
    self.duration = self.duration or 0.5
    Area_Spell.super.init(self, args)

    -- Define default values for the spell's properties
    self.r = math.random() * 2 * math.pi
    self.radius = self.radius or 50
    self.radius = Helper.Unit:apply_area_size_multiplier(self.unit, self.radius)
    self.fade_duration = self.fade_duration or 0.2
    self.duration_minus_fade = self.duration - self.fade_duration

    self.damage = get_dmg_value(self.damage)
    self.damage_ticks = default_to(self.damage_ticks, false)
    self.damage_type = self.damage_type or DAMAGE_TYPE_PHYSICAL
    self.hit_only_once = default_to(self.hit_only_once, not self.damage_ticks)
    self.tick_rate = self.tick_rate or 0.2
    self.is_troop = default_to(self.is_troop, false)

    self.targets_to_exclude = self.targets_to_exclude or {}

    -- Optional callback function for when targets are hit
    self.on_hit_callback = args.on_hit_callback

    if self.area_type == 'target' then
      if self.target then
        self.x, self.y = self.target.x, self.target.y
      end
    end

    if self.pick_shape == 'circle' then
      local w = self.radius
      self.shape = Circle(self.x, self.y, w)
    else
      local w = self.radius
      local h = self.radius
      self.shape = Rectangle(self.x, self.y, w, h, self.r)
    end

    self.color = self.color or fg[0]
    self.color = self.color:clone()
    self.opacity = self.opacity or 0.08
    self.color_transparent = Color(self.color.r, self.color.g, self.color.b, self.opacity)
    self.line_width = self.line_width or 1
    
    -- Add flashFactor for shimmery outline effect (like Area class)
    self.flashFactor = 0.5 -- Fixed value for consistent outline brightness

    -- Internal state
    self.targets_hit_map = {} -- Keep track of who we've hit to avoid double-damaging
    self.next_tick_time = self.tick_rate
    self.hidden = false
    self.current_duration = 0

    -- If the spell is not a Damage-over-Time (DoT), apply damage once immediately.
    if not self.damage_ticks then
        self:apply_damage()
    end
end


function Area_Spell:update(dt)
    self:update_game_object(dt)
    self.current_duration = self.current_duration + dt

    if self.current_duration > self.duration_minus_fade then
      self:fade_out()
    end

    if self.current_duration > self.duration then
      self:die()
    end

    -- If this is a DoT spell, handle the ticking logic
    if self.damage_ticks then
        self.next_tick_time = self.next_tick_time - dt
        if self.next_tick_time <= 0 then
            local _, hit_success = self:apply_damage()
            if hit_success then
                if self.on_tick_hit_sound then
                    self.on_tick_hit_sound:play{pitch = random:float(0.9, 1.1), volume = 0.2}
                end
            end
            self.next_tick_time = self.tick_rate -- Reset the timer for the next tick
        end
    end

    -- If the caster moves, the area can follow
    if self.unit and not self.unit.dead and self.follow_unit then
        self.x, self.y = self.unit.x, self.unit.y
        self.shape:move_to(self.x, self.y)
    end
end


function Area_Spell:apply_damage()
    -- Determine which group of units to target
    local target_group = self.is_troop and main.current.enemies or main.current.friendlies
    local targets_in_area = main.current.main:get_objects_in_shape(self.shape, target_group)

    local actual_targets_hit = {}
    local hit_success = false
    

    for _, target in ipairs(targets_in_area) do
        -- Only damage targets we haven't already hit in this spell's lifetime
        if not self.targets_hit_map[target.id] and not self.targets_to_exclude[target.id] then
            if self.damage > 0 then
                if self.apply_primary_hit_to_target and target == self.target then
                    Helper.Damage:primary_hit(target, self.damage, self.unit, self.damage_type, true)
                else
                    Helper.Damage:indirect_hit(target, self.damage, self.unit, self.damage_type, true)
                end
            end
            
            -- Call the on_hit_callback if provided
            if self.on_hit_callback then
                local delay = self.on_hit_delay or 0
                if delay > 0 and self.on_hit_delay_random then
                    delay = (math.random()/ 2 + 0.5) * delay
                end
                self.t:after(delay, function()
                    self.on_hit_callback(self, target, self.unit)
                end)
            end

            hit_success = true

            table.insert(actual_targets_hit, target)
            -- If it's not a DoT, mark as hit so it can't be hit again.
            -- For DoTs, we could clear this list each tick if we wanted to allow multiple hits.
            if self.hit_only_once then
                 self.targets_hit_map[target.id] = true
            end
        end
    end
    
    return actual_targets_hit, hit_success
end


function Area_Spell:draw()
    if self.hidden then return end

    if self.floor_effect then return end

    -- Draw with shimmery outline effect (like Area class)
    graphics.push(self.x, self.y, self.r)
    if self.pick_shape == 'circle' then
      graphics.circle(self.x, self.y, self.radius, self.color_transparent)
      graphics.circle(self.x, self.y, self.radius, self.color, self.line_width * self.flashFactor)
    else
      graphics.rectangle(self.x, self.y, self.radius, self.radius, 0, 0, self.color_transparent)
      graphics.rectangle(self.x, self.y, self.radius, self.radius, 0, 0, self.color, self.line_width * self.flashFactor)
    end
    graphics.pop()
end


function Area_Spell:fade_out()
    -- The "die" function now handles the fade-out animation before final destruction.
    if self.dying then return end -- Prevent die from being called multiple times
    self.dying = true

    local times_to_toggle_fade = self.fade_duration / 0.05
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, times_to_toggle_fade, 
        -- This final callback sets the object as dead, and the engine will remove it.
        function() self:die() end
    )
end

function Area_Spell:die()
    self.dead = true
end

-- =================================================================================
-- Knockback Area Spell - Now with a cool shockwave effect!
-- =================================================================================
Knockback_Area_Spell = Area_Spell:extend()
function Knockback_Area_Spell:init(args)

    Knockback_Area_Spell.super.init(self, args)

    --set default opacity before calling super.init
    self.opacity = self.opacity or 0.3

    -- Override properties for the knockback
    self.damage_ticks = false

    --[[
        NEW VISUAL EFFECT PROPERTIES
        Here we define the parameters for our concentric circle animation.
    ]]
    self.shockwaves = {} -- A table to hold all of our active shockwave circles
    self.shockwave_speed = self.radius * 4 -- How fast the circles expand (pixels per second)
    self.shockwave_interval = 0.08 -- How often a new circle is created (in seconds)
    self.shockwave_spawn_timer = 0 -- A timer to track when to spawn the next circle
end

function Knockback_Area_Spell:update(dt)
    -- We must call the parent update function! This handles the spell's lifetime,
    -- duration, fading, and eventually calls :die().
    Knockback_Area_Spell.super.update(self, dt)

    --[[
        VISUAL EFFECT UPDATE LOGIC
    ]]
    -- 1. Handle spawning new shockwaves
    self.shockwave_spawn_timer = self.shockwave_spawn_timer - dt
    if self.shockwave_spawn_timer <= 0 then
        -- Add a new shockwave to our list. It starts at the center with full opacity.
        table.insert(self.shockwaves, { radius = 0, opacity = self.opacity })
        -- Reset the timer for the next one
        self.shockwave_spawn_timer = self.shockwave_interval
    end

    -- 2. Update all existing shockwaves (we loop backwards when removing items)
    for i = #self.shockwaves, 1, -1 do
        local wave = self.shockwaves[i]

        -- Make the circle expand
        wave.radius = wave.radius + self.shockwave_speed * dt

        -- If a wave has expanded past the spell's main radius, remove it
        if wave.radius >= self.radius then
            table.remove(self.shockwaves, i)
        else
            -- Otherwise, calculate its opacity so it fades out as it expands
            wave.opacity = 1 - (wave.radius / self.radius)
        end
    end
end

function Knockback_Area_Spell:draw()
    -- We are COMPLETELY REPLACING the parent draw function, so we DO NOT call super.draw()
    if self.hidden then return end

    -- "Additive" blending makes overlapping bright circles glow, which looks great for energy effects.
    love.graphics.setBlendMode("add")
    love.graphics.setLineWidth(2)

    -- Loop through all our active shockwaves and draw them
    for _, wave in ipairs(self.shockwaves) do
        -- Set the color for this specific wave, using its calculated opacity
        love.graphics.setColor(self.color.r, self.color.g, self.color.b, wave.opacity)

        -- Draw the circle
        love.graphics.circle("line", self.x, self.y, wave.radius)
    end

    -- IMPORTANT: Reset the graphics state so we don't mess up other game rendering
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1) -- Reset to white, full opacity
    love.graphics.setLineWidth(1)
end

-- We can remove the :die() override if it only prints, but it's fine to leave it.
function Knockback_Area_Spell:die()
    Knockback_Area_Spell.super.die(self)
end

-- We no longer need to override apply_damage unless we want to change its logic.
-- This is inherited automatically from the parent class.
-- If you need the knockback logic, you must keep this function.
function Knockback_Area_Spell:apply_damage()
    local targets_hit = Knockback_Area_Spell.super.apply_damage(self)
    for _, target in ipairs(targets_hit) do
        -- Note: The original code used self.target, which might not be correct if the spell
        -- is just an area effect. This calculates the angle from the spell's center.
        local angle = math.atan2(target.y - self.y, target.x - self.x)
        target:push(self.knockback_force, angle, false, self.knockback_duration)
    end
end
-- File: Area.lua (The new version)

Area_Spell = Spell:extend()

function Area_Spell:init(args)
    Area_Spell.super.init(self, args) -- This loads all properties from spelldata onto `self`

    -- Define default values for the spell's properties
    self.r = math.random() * 2 * math.pi
    self.radius = self.radius or 50
    self.fade_duration = self.fade_duration or 0.2
    self.duration = self.duration or 0.5
    self.duration_minus_fade = self.duration - self.fade_duration

    self.dmg = self.dmg or 0
    self.damage_ticks = self.damage_ticks or false
    self.tick_rate = self.tick_rate or 0.2
    self.is_troop = self.is_troop or false

    if self.area_type == 'target' then
      if self.target then
        self.x, self.y = self.target.x, self.target.y
      end
    end

    if self.pick_shape == 'circle' then
      local w = 1.2*self.radius
      self.shape = Circle(self.x, self.y, w)
    else
      local w = 1.5*self.radius
      local h = 1.5*self.radius
      self.shape = Rectangle(self.x, self.y, w, h, self.r)
    end

    self.color = self.color or fg[0]
    self.opacity = self.opacity or 0.1
    self.color_transparent = Color(self.color.r, self.color.g, self.color.b, self.opacity)
    self.line_width = self.line_width or 1

    -- Internal state
    self.targets_hit = {} -- Keep track of who we've hit to avoid double-damaging
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
            self:apply_damage()
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

    for _, target in ipairs(targets_in_area) do
        -- Only damage targets we haven't already hit in this spell's lifetime
        if not self.targets_hit[target.id] then
            if self.dmg > 0 then
                target:hit(self.dmg, self.unit)
                self:apply_hit_effect(target)
            end
            
            -- If it's not a DoT, mark as hit so it can't be hit again.
            -- For DoTs, we could clear this list each tick if we wanted to allow multiple hits.
            if not self.damage_ticks then
                 self.targets_hit[target.id] = true
            end
        end
    end
end


function Area_Spell:apply_hit_effect(target)
    -- This function remains the same, providing visual/audio feedback
    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
    hit2:play{pitch = random:float(0.95, 1.05), volume = 0.35}
end


function Area_Spell:draw()
    if self.hidden then return end

    -- Simplified drawing, can be expanded as needed
    graphics.push(self.x, self.y, self.r)
    if self.pick_shape == 'circle' then
      graphics.circle(self.x, self.y, self.radius, self.color_transparent)
      graphics.circle(self.x, self.y, self.radius, self.color_transparent, self.line_width)
    else
      graphics.rectangle(self.x, self.y, self.radius, self.radius, 0, 0, self.color_transparent)
      graphics.rectangle(self.x, self.y, self.radius, self.radius, 0, 0, self.color_transparent, self.line_width)
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
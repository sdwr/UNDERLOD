-- ====================================================================
-- SafetyDanceSpell Class (SpellV2 Format)
-- This is a self-contained spell object that manages its own lifecycle.
-- ====================================================================
SafetyDanceSpell = Spell:extend()

function SafetyDanceSpell:init(args)
    -- The arena draws this group's ground effects before Heigan and units.
    args.group = main.current.main

    -- Call the parent Spell's init function
    SafetyDanceSpell.super.init(self, args)

    -- Spell-specific parameters from spelldata
    self.color = self.color or orange[-5]
    self.damage = self.damage or 25
    self.total_zones = self.total_zones or 4
    self.charge_duration = self.charge_duration or 3
    self.active_duration = self.active_duration or 0.37
    self.tick_rate = self.tick_rate or 0.5
    self.damage_troops = self.damage_troops == nil and true or self.damage_troops

    -- Internal state management
    self.state = 'charging' -- 'charging' -> 'active'
    self.charge_timer = 0
    self.active_timer = 0
    self.next_damage_tick = 0
    self.targets_hit_this_tick = {}

    -- This static variable ensures the safe zone changes each cast
    -- (We keep this part of the original logic's design)
    if not SafetyDanceSpell.safe_zone_index then
        SafetyDanceSpell.safe_zone_index = 1
    end

    -- Determine the safe zone and create the damage rectangles
    self.damage_zones = {}
    self:create_damage_zones()

    -- Update the safe zone index for the next time the spell is cast
    SafetyDanceSpell.safe_zone_index = (SafetyDanceSpell.safe_zone_index % self.total_zones) + 1
end

-- This function replaces the logic from the old :create_all()
function SafetyDanceSpell:create_damage_zones()
    if self.hit_busiest_lane then
        self:create_busiest_lane_zone()
        return
    end
    for i = 1, self.total_zones do
        if i ~= SafetyDanceSpell.safe_zone_index then
            local x, y, w, h = Helper.Geometry:get_arena_rect(i, self.total_zones)
            table.insert(self.damage_zones, {
                x = x, y = y, w = w, h = h,
                -- Create a physics shape for each zone for collision detection
                shape = Rectangle(x, y, w, h)
            })
        end
    end
end

-- Inverted dance: only the lane holding the most troops erupts (ties broken at
-- random), so a split team loses at most one unit's worth.
function SafetyDanceSpell:create_busiest_lane_zone()
    local best, best_count = {}, -1
    for i = 1, self.total_zones do
        local x, y, w, h = Helper.Geometry:get_arena_rect(i, self.total_zones)
        local shape = Rectangle(x, y, w, h)
        local count = #main.current.main:get_objects_in_shape(shape, main.current.friendlies)
        local zone = {x = x, y = y, w = w, h = h, shape = shape}
        if count > best_count then
            best, best_count = {zone}, count
        elseif count == best_count then
            table.insert(best, zone)
        end
    end
    table.insert(self.damage_zones, best[math.random(1, #best)])
end

function SafetyDanceSpell:update(dt)
    -- Call the parent Spell's update for timers and cancellation checks
    SafetyDanceSpell.super.update(self, dt)
    if self.dead then return end

    if self.state == 'charging' then
        self.charge_timer = self.charge_timer + dt
        if self.charge_timer >= self.charge_duration then
            self.state = 'active'
            earth1:play{volume = 0.7}
        end

    elseif self.state == 'active' then
        self.active_timer = self.active_timer + dt
        self.next_damage_tick = self.next_damage_tick - dt

        -- Check if it's time to apply damage
        if self.next_damage_tick <= 0 then
            self:apply_damage()
            self.next_damage_tick = self.tick_rate
        end

        -- Check if the spell's active duration has finished
        if self.active_timer >= self.active_duration then
            self:die()
        end
    end
end

function SafetyDanceSpell:apply_damage()
    self.targets_hit_this_tick = {} -- Reset hit targets for this Tick
    local target_classes = {Helper.Unit.troop, Helper.Unit.boss}
    if self.damage_troops then
        target_classes = main.current.friendlies
    else 
        target_classes = main.current.enemies
    end

    for _, zone in ipairs(self.damage_zones) do
        local units_in_zone = main.current.main:get_objects_in_shape(zone.shape, target_classes)
        for _, unit in ipairs(units_in_zone) do
            -- Ensure we only hit each unit once per damage tick
            if not self.targets_hit_this_tick[unit] then
                unit:hit(self.damage, self.unit, nil, true, true)
                self.targets_hit_this_tick[unit] = true

                -- Visual/Audio feedback for the hit
                HitCircle{group = main.current.effects, x = unit.x, y = unit.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = unit.x, y = unit.y, color = self.color} end
            end
        end
    end
end

function SafetyDanceSpell:draw()
    SafetyDanceSpell.super.draw(self)
end

-- Render both the warning and active hazard in the existing ground pass.
function SafetyDanceSpell:draw_ground()
    if self.state == 'charging' then
        self:draw_aiming_rects()
    elseif self.state == 'active' then
        self:draw_active_rects()
    end
end

-- Keep the texture subordinate to the boundary: the entire rectangle is unsafe,
-- including the gaps between stripes. Anchor bands in arena space so adjacent
-- zones form one continuous pattern instead of restarting at every edge.
function SafetyDanceSpell:draw_danger_zone(zone, fill_alpha, stripe_alpha, edge_alpha)
    local fill = self.color:clone()
    fill.a = fill_alpha
    local stripe = self.color:clone():lighten(0.15)
    stripe.a = stripe_alpha
    local edge = self.color:clone():lighten(0.3)
    edge.a = edge_alpha
    local shadow = self.color:clone():darken(0.25)
    shadow.a = 0.7

    local left, right = zone.x - zone.w / 2, zone.x + zone.w / 2
    local top, bottom = zone.y - zone.h / 2, zone.y + zone.h / 2
    local spacing, band_width = 24, 3
    graphics.draw_with_mask(function()
        graphics.rectangle(zone.x, zone.y, zone.w, zone.h, nil, nil, fill)
        for offset = math.floor((left + top) / spacing) * spacing, right + bottom, spacing do
            graphics.polygon({
                offset - top, top, offset - top + band_width, top,
                offset - bottom + band_width, bottom, offset - bottom, bottom
            }, stripe)
        end

        -- Inset both strokes so their outer edges match the damage rectangle
        -- without painting over the safe lane. The dark backing separates the
        -- bright boundary from both the texture and the arena background.
        graphics.rectangle(zone.x, zone.y, zone.w - 4, zone.h - 4, nil, nil, shadow, 4)
        graphics.rectangle(zone.x, zone.y, zone.w - 2, zone.h - 2, nil, nil, edge, 2)
    end, function()
        graphics.rectangle(zone.x, zone.y, zone.w, zone.h, nil, nil, fill)
    end)
end

function SafetyDanceSpell:draw_aiming_rects()
    local progress = math.min(self.charge_timer / self.charge_duration, 1)
    for _, zone in ipairs(self.damage_zones) do
        self:draw_danger_zone(zone, 0.08 + 0.10 * progress,
            0.12 + 0.12 * progress, 0.65 + 0.30 * progress)
    end
end

function SafetyDanceSpell:draw_active_rects()
    -- Brief impact accent, then hold the warning until damage actually ends.
    local impact = math.max(0, 1 - self.active_timer / 0.2)
    for _, zone in ipairs(self.damage_zones) do
        self:draw_danger_zone(zone, 0.30 + 0.12 * impact, 0.32, 1)
    end
end

-- The Spell:die() function from the parent class will handle cleanup.

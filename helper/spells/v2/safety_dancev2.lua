-- ====================================================================
-- SafetyDanceSpell Class (SpellV2 Format)
-- This is a self-contained spell object that manages its own lifecycle.
-- ====================================================================
SafetyDanceSpell = Spell:extend()

function SafetyDanceSpell:init(args)
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
                unit:hit(self.damage, self.unit)
                self.targets_hit_this_tick[unit] = true

                -- Visual/Audio feedback for the hit
                HitCircle{group = main.current.effects, x = unit.x, y = unit.y, rs = 6, color = fg[0], duration = 0.1}
                for i = 1, 1 do HitParticle{group = main.current.effects, x = unit.x, y = unit.y, color = self.color} end
            end
        end
    end
end

function SafetyDanceSpell:draw()
    if self.state == 'charging' then
        self:draw_aiming_rects()
    elseif self.state == 'active' then
        self:draw_active_rects()
    end
end

-- ===================================================================
-- NEW HELPER FUNCTION
-- This function draws a tiled hexagonal pattern inside a given rectangle.
-- ===================================================================
function SafetyDanceSpell:draw_tiled_hexagons(zone, color, mode)
    mode = mode or 'fill' -- Default to filled hexagons
    -- TWEAK: Increased the radius to make each hexagon larger, resulting in fewer hexagons overall.
    local hex_radius = 18

    -- Pre-calculate hexagon geometry constants for a pointy-topped hexagon
    local hex_height = math.sqrt(3) * hex_radius
    local hex_width = 2 * hex_radius
    
    -- Get the boundaries of the rectangular zone
    local start_x, end_x = zone.x - zone.w / 2, zone.x + zone.w / 2
    local start_y, end_y = zone.y - zone.h / 2, zone.y + zone.h / 2

    local row = 0
    -- Iterate through the vertical space of the zone
    for y = start_y - hex_height, end_y + hex_height, hex_height do
        row = row + 1
        -- TWEAK: Increased the horizontal step to create a small gap between hexagons, preventing overlap.
        local horizontal_step = hex_width * 0.8
        -- Iterate through the horizontal space of the zone
        for x = start_x - hex_width, end_x + hex_width, horizontal_step do
            -- Apply horizontal offset for every other row to create a staggered grid
            local current_x = x
            if row % 2 == 0 then
                current_x = x + horizontal_step / 2
            end

            -- Calculate the 6 vertices for a single hexagon
            local points = {}
            for i = 0, 5 do
                local angle = math.pi / 3 * i
                table.insert(points, current_x + hex_radius * math.cos(angle))
                table.insert(points, y + hex_radius * math.sin(angle))
            end

            -- Draw the hexagon using the specified mode ('fill' or 'line')
            graphics.polygon(points, color, mode == 'line' and 1 or nil)
        end
    end
end

-- ===================================================================
-- REFACTORED: draw_aiming_rects
-- Now draws a grid of hexagon outlines.
-- ===================================================================
function SafetyDanceSpell:draw_aiming_rects()
    local pctCharged = self.charge_timer / self.charge_duration
    local alpha = math.min(pctCharged * 0.4, 0.4)
    local color = self.color:clone()
    color.a = alpha

    -- Use a stencil to ensure hexagons only draw inside the zone's rectangle
    for _, zone in ipairs(self.damage_zones) do
        graphics.draw_with_mask(
            function() self:draw_tiled_hexagons(zone, color, 'line') end,
            function() graphics.rectangle(zone.x, zone.y, zone.w, zone.h, nil, nil, color) end
        )
    end
end

-- ===================================================================
-- REFACTORED: draw_active_rects
-- Now draws a solid field of filled hexagons.
-- ===================================================================
function SafetyDanceSpell:draw_active_rects()
    local color = self.color:clone()
    -- Optional: Fade out the effect as its duration ends
    local fade_pct = self.active_timer / self.active_duration
    color.a = 0.8 * (1 - fade_pct)

    -- Use a stencil to ensure hexagons only draw inside the zone's rectangle
    for _, zone in ipairs(self.damage_zones) do
        graphics.draw_with_mask(
            function() self:draw_tiled_hexagons(zone, color, 'fill') end,
            function() graphics.rectangle(zone.x, zone.y, zone.w, zone.h, nil, nil, color) end
        )
    end
end

-- The Spell:die() function from the parent class will handle cleanup.

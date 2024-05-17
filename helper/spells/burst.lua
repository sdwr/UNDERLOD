Helper.Spell.Burst = {}

Helper.Spell.Burst.list = {}

function Helper.Spell.Burst:create(color, bullet_length, damage, speed, unit, draw_over_units)
    local burst = {
        interval_id = -1,
        unit = unit,
        draw_over_units = draw_over_units or true
    }

    burst.interval_id = Helper.Time:set_interval(0.1, function()
        if unit.have_target then
            if Helper.Spell:there_is_target_in_range(unit, attack_ranges['long'] + 30) then
                Helper.Unit:claim_target(unit, Helper.Spell:get_nearest_target(unit))
                Helper.Spell.Missile:create(color, bullet_length, damage, speed, unit, true, 3)
            end
        end
    end, 6)

    table.insert(self.list, burst)
end

function Helper.Spell.Burst:stop_firing(unit)
    local i, burst = find_in_list(self.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        Helper.Time:stop_interval(burst.interval_id)
    end
end
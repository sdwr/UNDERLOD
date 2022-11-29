Helper.Spell.Burst = {}

Helper.Spell.Burst.prelist = {}
Helper.Spell.Burst.list = {}

function Helper.Spell.Burst:create(color, bullet_length, damage, speed, unit)
    local burst = {
        color = color,
        bullet_length = bullet_length,
        damage = damage,
        speed = speed,
        interval_time = interval_time or 0.1,
        number_shots = number_shots or 6,
        interval_id = -1,
        unit = unit,

        cast_time = unit.castTime or 0,
        start_aim_time = Helper.Time.time
    }

    Helper.Unit:start_casting(unit)
    table.insert(self.prelist, burst)
end

function Helper.Spell.Burst:update()
    Helper.Spell.Burst:cast()
end

function Helper.Spell.Burst:cast()
    --move to active list if ready to cast
    for i, spell in ipairs(self.prelist) do
        if Helper.Spell:can_shoot(spell) then
            table.insert(self.list, spell)
            table.remove(self.prelist, i)

            self:shoot(spell)

        end
    end
end

function Helper.Spell.Burst:shoot(spell)
    local unit = spell.unit
    spell.interval_id = Helper.Time:set_interval(spell.interval_time, function()
        if Helper.Spell:there_is_target_in_range(unit, attack_ranges['long']) then
            Helper.Unit:claim_target(unit, Helper.Spell:get_nearest_target(unit))
            Helper.Spell.Missile:create(spell.color, 
                spell.bullet_length, spell.damage, spell.speed, unit, true, 3)
        end
    end,
    spell.number_shots,
    function()
        self:stop_aiming(spell.unit) 
    end)
end

function Helper.Spell.Burst:stop_aiming(unit)
    local i, j, burst
    i, burst = find_in_list(self.list, unit, function(value) return value.unit end)
    if i ~= -1 then
        Helper.Time:stop_interval(burst.interval_id)
        table.remove(self.list, i)
    end

    burst = nil
    j, burst = find_in_list(Helper.Spell.Burst.prelist, unit, function(value) return value.unit end)
    if j ~= -1 then
        table.remove(self.prelist, j)
    end

    Helper.Unit:finish_casting(unit)
end
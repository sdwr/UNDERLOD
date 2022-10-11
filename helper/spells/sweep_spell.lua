Helper.Spell.Sweep = {}

Helper.Spell.Sweep.announce_time = 2
Helper.Spell.Sweep.sweep_speed = 3500
Helper.Spell.Sweep.sweep_width = 130
Helper.Spell.Sweep.list = {}

function Helper.Spell.Sweep.create(color, damage_troops, damage, x1, y1, x2, y2)
    local sweep = {
        damage = damage,
        damage_troops = damage_troops,
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        color = color,
        cast_time = Helper.Time.time,
        from_left = math.random(0, 1),
        particle_interval_id = -1
    }

    if sweep.from_left == 1 then
        sweep.from_left = true
    else
        sweep.from_left = false
    end

    sweep_sound:play{volume = 0.7}
    table.insert(Helper.Spell.Sweep.list, sweep)
end

function Helper.Spell.Sweep.draw()
    for i, sweep in ipairs(Helper.Spell.Sweep.list) do
        if Helper.Time.time - sweep.cast_time < Helper.Spell.Sweep.announce_time then
            Helper.Graphics.draw_dashed_rectangle(Helper.Color.set_transparency(sweep.color, 0.5), 3, 10, 5, Helper.Time.time * 80, sweep.x1, sweep.y1, sweep.x2, sweep.y2)
        else
            local t = Helper.Time.time - sweep.cast_time
            t = t - Helper.Spell.Sweep.announce_time
            local height = sweep.y2 - sweep.y1
            local width = Helper.Spell.Sweep.sweep_width * height / 100
    
            love.graphics.setColor(sweep.color.r, sweep.color.g, sweep.color.b, 1)
            if not sweep.from_left then
                love.graphics.polygon('fill', Helper.window_width + width*3/5 - Helper.Spell.Sweep.sweep_speed * t, sweep.y1, 
                                                Helper.window_width + width - Helper.Spell.Sweep.sweep_speed * t, sweep.y1, 
                                                Helper.window_width + width*2/5 - Helper.Spell.Sweep.sweep_speed * t, sweep.y2,
                                                Helper.window_width - Helper.Spell.Sweep.sweep_speed * t, sweep.y2)

                if sweep.particle_interval_id == -1 then
                    sweep.particle_interval_id = Helper.Time.set_interval(0.001, function()
                        local t = Helper.Time.time - sweep.cast_time
                        t = t - Helper.Spell.Sweep.announce_time
                        Helper.Graphics.create_particle(sweep.color, get_random(0.5, 1.5), Helper.window_width + width/2 - Helper.Spell.Sweep.sweep_speed * t,
                                                        get_random(sweep.y1, sweep.y2), get_random(30, 70), get_random(2, 5),
                                                        -1, 0, 30)
                    end)
                end
            else
                love.graphics.polygon('fill', -width + width*3/5 + Helper.Spell.Sweep.sweep_speed * t, sweep.y1, 
                                                -width + width + Helper.Spell.Sweep.sweep_speed * t, sweep.y1, 
                                                -width + width*2/5 + Helper.Spell.Sweep.sweep_speed * t, sweep.y2,
                                                -width + Helper.Spell.Sweep.sweep_speed * t, sweep.y2)

                if sweep.particle_interval_id == -1 then
                    sweep.particle_interval_id = Helper.Time.set_interval(0.001, function()
                        local t = Helper.Time.time - sweep.cast_time
                        t = t - Helper.Spell.Sweep.announce_time
                        Helper.Graphics.create_particle(sweep.color, get_random(0.5, 1.5), -width + width/2 + Helper.Spell.Sweep.sweep_speed * t,
                                                        get_random(sweep.y1, sweep.y2), get_random(30, 70), get_random(2, 5),
                                                        1, 0, 30)
                    end)
                end
            end
        end
    end
end

function Helper.Spell.Sweep.update()
    for i = #Helper.Spell.Sweep.list, 1, -1 do
        local t = Helper.Time.time - Helper.Spell.Sweep.list[i].cast_time
        t = t - Helper.Spell.Sweep.announce_time
        local height = Helper.Spell.Sweep.list[i].y2 - Helper.Spell.Sweep.list[i].y1
        local width = Helper.Spell.Sweep.sweep_width * height / 100

        if not Helper.Spell.Sweep.list[i].from_left then
            for j, target in ipairs(Helper.Unit.get_list(Helper.Spell.Sweep.list[i].damage_troops)) do
                if Helper.Time.time - target.damage_taken_at['sweep'] > 2 and Helper.Geometry.is_inside_rectangle(target.x, target.y, 
                                                                                                                    Helper.window_width - width - Helper.Spell.Sweep.sweep_speed * t, Helper.Spell.Sweep.list[i].y1,
                                                                                                                    Helper.window_width + width*2 - Helper.Spell.Sweep.sweep_speed * t, Helper.Spell.Sweep.list[i].y2) then
                    target.damage_taken_at['sweep'] = Helper.Time.time

                    target:hit(Helper.Spell.Sweep.list[i].damage)
                    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = blue[0]} end
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
                end
            end
        else
            for j, target in ipairs(Helper.Unit.get_list(Helper.Spell.Sweep.list[i].damage_troops)) do
                if Helper.Time.time - target.damage_taken_at['sweep'] > 2 and Helper.Geometry.is_inside_rectangle(target.x, target.y, 
                                                                                                                    -width*2 + width/5 + Helper.Spell.Sweep.sweep_speed * t, Helper.Spell.Sweep.list[i].y1,
                                                                                                                    width*4/5 + Helper.Spell.Sweep.sweep_speed * t, Helper.Spell.Sweep.list[i].y2) then
                    target.damage_taken_at['sweep'] = Helper.Time.time

                    target:hit(Helper.Spell.Sweep.list[i].damage)
                    HitCircle{group = main.current.effects, x = target.x, y = target.y, rs = 6, color = fg[0], duration = 0.1}
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = blue[0]} end
                    for i = 1, 1 do HitParticle{group = main.current.effects, x = target.x, y = target.y, color = target.color} end
                end
            end
        end

        if Helper.Time.time - Helper.Spell.Sweep.list[i].cast_time > Helper.Spell.Sweep.announce_time + 1 then
            Helper.Time.stop_interval(Helper.Spell.Sweep.list[i].particle_interval_id)
            table.remove(Helper.Spell.Sweep.list, 1)
        end
    end
end
Helper.Spell.Frostfield = {}

Helper.Spell.Frostfield.duration = 2
Helper.Spell.Frostfield.tick_interval = 0.25

Helper.Spell.Frostfield.chillDuration = 2
Helper.Spell.Frostfield.chillAmount = 0.3

Helper.Spell.Frostfield.list = {}

function Helper.Spell.Frostfield:create(unit, color, damage_troops, damagePerTick, radius, duration, x, y)

    local frostfield = {
        unit = unit,
        x = x,
        y = y,
        creation_time = Helper.Time.time,
        damage_troops = damage_troops,
        damagePerTick = damagePerTick,
        radius = radius,
        duration = duration or Helper.Spell.Frostfield.duration,
        color = color:clone(),
    }



    --set start time
    --don't need prelist because it's not a projectile/castable
    frostfield.next_tick = Helper.Time.time + Helper.Spell.Frostfield.tick_interval
    frostfield.can_trigger = false
    table.insert(Helper.Spell.Frostfield.list, frostfield)

end

--need to draw underneath units somehow 
--(change group? but it is not an object, just a circle)
--oh well it works
function Helper.Spell.Frostfield:draw()
    for i, frostfield in ipairs(Helper.Spell.Frostfield.list) do
        love.graphics.setColor(frostfield.color.r, frostfield.color.g, frostfield.color.b, frostfield.color.a)
        love.graphics.circle( 'fill', frostfield.x, frostfield.y, frostfield.radius )
    end
end

function Helper.Spell.Frostfield:update()
    Helper.Spell.Frostfield:delete()
    Helper.Spell.Frostfield:tick()
    Helper.Spell.Frostfield:damage()
end

function Helper.Spell.Frostfield:tick()
  for i, frostfield in ipairs(Helper.Spell.Frostfield.list) do
    if Helper.Time.time > frostfield.next_tick then
      frostfield.can_trigger = true
      frostfield.next_tick = Helper.Time.time + Helper.Spell.Frostfield.tick_interval
    end
  end
end

function Helper.Spell.Frostfield:damage()
  for i, frostfield in ipairs(Helper.Spell.Frostfield.list) do
    if frostfield.can_trigger then
      for i, unit in ipairs(Helper.Unit:get_list(frostfield.damage_troops)) do
        for j, point in ipairs(unit.points) do
          if Helper.Geometry:distance(frostfield.x, frostfield.y, unit.x + point.x, unit.y + point.y) < frostfield.radius then
            --register damage through the spell system
            Helper.Spell:register_damage_point(point, frostfield.unit, frostfield.damagePerTick)
            --and apply slow directly to the unit
            unit:chill(Helper.Spell.Frostfield.chillAmount, Helper.Spell.Frostfield.chillDuration, frostfield.unit)
          end
        end
      end
      frostfield.can_trigger = false
    end
  end
end



function Helper.Spell.Frostfield:delete()
    for i = #Helper.Spell.Frostfield.list, 1, -1 do
        if Helper.Time.time - Helper.Spell.Frostfield.list[i].creation_time > Helper.Spell.Frostfield.list[i].duration then
            table.remove(Helper.Spell.Frostfield.list, i)
        end
    end
end
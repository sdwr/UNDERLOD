-- TODO - move item info in here
-- right now the item data is stored in main.lua
-- they are added as "items" to the player object (objects.lua)
-- and implemented in combat in objects.lua in calculate_stats
-- calculate stats is run every frame, which is too much prob!

function Add_Item_Proc(unit, proc)

  --copy proc so state is wiped between units/levels
  local proc_copy = {type = proc.type, trigger = proc.trigger, every_attacks = proc.every_attacks, attacks_left = proc.every_attacks}
  table.insert(unit.procs, proc_copy)
end

function Check_On_Hit_Procs(unit, target)
  if unit.procs then
    for i, proc in ipairs(unit.procs) do
      if proc.trigger == 'on_hit' then
        proc.attacks_left = proc.attacks_left - 1
        if proc.attacks_left <= 0 then
          Proc_Proc(unit, target, proc)
          proc.attacks_left = proc.every_attacks
        end
      end
    end
  end
end

function Proc_Proc(unit, target, proc)
  if proc.type == 'lightning' then
    --cast chain lightning
    --make sure the hit doesn't reproc (maybe) (leave from blank?)
    ChainLightning{group = main.current.main, target = target, rs = 50, dmg = proc.dmg, color = blue[0], parent = nil, chain = 3}
  end
end

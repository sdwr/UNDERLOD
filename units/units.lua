require 'units/player/player_troop'
require 'units/player/laser_troop'
require 'units/player/swordsman_troop'
require 'units/player/archer_troop'

troop_classes = {
  Troop,
  Laser_Troop,
  Swordsman_Troop,
  Archer_Troop
}

friendly_classes = shallowcopy(troop_classes)
table.insert(friendly_classes, Critter)

enemy_classes = {
  Enemy,
  EnemyCritter
}

all_unit_classes = shallowcopy(troop_classes)
table.extend(all_unit_classes, enemy_classes)


--need to have procs on the control group as well as the troops
--1. one-offs (like spawn turrets or control points on battlefield)
--2. buffs that charge per unit but proc on control group (like static, bloodlust, etc)

Team = Object:extend()
function Team:init(i)
  self.troops = {}
  self.procs = {}
  self.target = nil
  self.index = i
end

function Team:add_troop(args)
  local troop = Create_Troop(args)
  troop.team = self.index
  table.insert(self.troops, troop)
end

--target functions
function Team:set_team_target(target)
  self.target = target
  for i, troop in ipairs(self.troops) do
    troop:set_assigned_target(target)
  end
  Helper.Unit:set_target_ring(target)
end

function Team:clear_team_target()
  local target = self.target
  self.target = nil
  for i, troop in ipairs(self.troops) do
    troop:clear_assigned_target()
  end
  Helper.Unit:clear_target_ring(target)
end

--buff functions
function Team:add_buff(buff)
  for i, troop in ipairs(self.troops) do
    troop:add_buff(buff)
  end
end

function Team:remove_buff(buffName)
  for i, troop in ipairs(self.troops) do
    troop:remove_buff(buffName)
  end
end

function Team:remove_and_add_buff(buff)
  local buffName = buff.name
  for i, troop in ipairs(self.troops) do
    troop:remove_buff(buffName)
    troop:add_buff(buff)
  end
end

--item functions

--needs troops to be added to team first (should be done in init?
function Team:apply_item_procs()
  --assume all items are the same between troops, so just grab the first one
  if not self.troops or #self.troops == 0 then
    print('no troops in team')
    return
  end

  --add 1 copy of 'team' procs to the team
  local team_items = self.troops[1].items

  if team_items and #team_items > 0 then
    for k,item in ipairs(team_items) do
      if item.procs then
        for _, proc in ipairs(item.procs) do
          local procname = proc
          --can fill data from item here, but defaults should be ok
          local procObj = Create_Proc(procname, nil, self)
          if procObj then
            table.insert(self.procs, procObj)
          end
        end
      end
    end
  end
end

function Team:die()
  for i, troop in ipairs(self.troops) do
    troop:die()
  end
end

-- character = name of unit (on buy screen)
-- unit = instance of unit (on buy screen)
-- unit = main unit class (troop, enemy, etc all extend, on battlefield)

-- control group = group of troops (on battlefield)
-- troop = single player-controlled unit (on battlefield)
function Create_Team(args)
  return Team(args)
end

function Create_Troop(args)
  if args.character == 'laser' then
    return Laser_Troop(args)
  elseif args.character == 'swordsman' then
    return Swordsman_Troop(args)
  elseif args.character == 'archer' then
    return Archer_Troop(args)
  else
    return Troop(args)
  end
end

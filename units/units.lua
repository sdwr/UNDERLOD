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
function Team:init(i, unit)
  self.troops = {}
  self.procs = {}
  self.target = nil
  self.rallyCircle = nil
  self.index = i
  self.unit = unit
  self.color = character_colors[unit.character]
end

function Team:add_troop(args)
  local troop = Create_Troop(args)
  troop.team = self.index
  table.insert(self.troops, troop)
end

function Team:set_troop_state(state)
  for i, troop in ipairs(self.troops) do
    troop.state = state
  end
end

--target functions
function Team:set_team_target(target)
  self.target = target
  for i, troop in ipairs(self.troops) do
    troop:set_assigned_target(target)
    troop.state = unit_states['normal']
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

--rally functions
function Team:set_rally_point(x, y)
  self.rallyCircle = RallyCircle{
    x = x,
    y = y,
    group = main.current.floor,
    team = self,
    color = self.color
  }
  for i, troop in ipairs(self.troops) do
    troop.state = unit_states['rallying']
    troop.rallying = true
    troop.target_pos = sum_vectors({x = Helper.mousex, y = Helper.mousey}, rally_offsets(i))
  end
end

function Team:clear_rally_point()
  if self.rallyCircle then
    self.rallyCircle:die()
    self.rallyCircle = nil
  end
  for i, troop in ipairs(self.troops) do
    troop.target_pos = nil
    --only clear state if rallying (might be attacking somehow)
    if troop.state == unit_states['rallying'] or troop.state == unit_states['stopped'] then
      troop.state = unit_states['normal']
    end
  end
end

--selection functions
function Team:select()
  for i, troop in ipairs(self.troops) do
    troop.selected = true
  end
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

--util functions

function Team:get_center()
  local x = 0
  local y = 0
  local count = 0
  for i, troop in ipairs(self.troops) do
    if not troop.dead then
      x = x + troop.x
      y = y + troop.y
      count = count + 1
    end
  end
  if count == 0 then
    return {x = 0, y = 0}
  else
    return {x = x / count, y = y / count}
  end

end

function Team:get_enemies_in_range(range)
  local enemies = {}
  for i, troop in ipairs(self.troops) do
    local in_range = Helper.Spell:get_all_targets_in_range(troop, range)
    combine_tables(enemies, in_range)
  end
  return enemies
end

function Team:get_allies_in_range(range)
  local allies = {}
  for i, troop in ipairs(self.troops) do
    if not troop.dead then
      local in_range = Helper.Spell:get_all_allies_in_range(troop, range)
      combine_tables(allies, in_range)
    end
  end
  return allies
end

function Team:is_first_alive_troop(troop)
  if not self.troops or #self.troops == 0 then
    return false
  end
  local aliveTroop = nil
  for i, t in ipairs(self.troops) do
    if not t.dead then
      aliveTroop = t
      break
    end
  end
  
  return troop == aliveTroop
end

function Team:get_alive_troop_count()
  local count = 0
  for i, troop in ipairs(self.troops) do
    if not troop.dead then
      count = count + 1
    end
  end
  return count
end

function Team:get_troop_index(troop)
  for i, t in ipairs(self.troops) do
    if t == troop then
      return i
    end
  end
  return -1
end

--affect all troops in team

function Team:damage_all_troops(damage, from, damageType)
  for i, troop in ipairs(self.troops) do
    troop:hit(damage, from, damageType)
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

  if team_items then
    for i = 1,6 do
      local item = team_items[i]
      if item and item.procs then
        for _, proc in ipairs(item.procs) do
          local procname = proc
          --can fill data from item here, but defaults should be ok
          local procObj = Create_Proc(procname, self, nil)
          self:add_proc(procObj)
        end
      end
    end
  end
end

function Team:add_proc(proc)
  if not proc then
    print('no proc to add to team')
    return
  end

  if proc.scope == 'team' then
    table.insert(self.procs, proc)
  elseif proc.scope == 'troop' then
    for i, troop in ipairs(self.troops) do
      Create_Proc(proc.name, nil, troop)
    end
    proc:die()
  elseif proc.scope == 'global' then
    --do global stuff
  else
    print('proc not on team or troop (in team)', self.name)
    proc:die()
  end
end

function Team:die()
  for i, troop in ipairs(self.troops) do
    troop:die()
  end
  for i, proc in ipairs(self.procs) do
    proc:die()
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

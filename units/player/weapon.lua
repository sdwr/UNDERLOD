Weapon = Unit:extend()
Weapon:implement(GameObject)
Weapon:implement(Physics)

function Weapon:init(args)
  self.class = 'weapon'
  self.faction = 'friendly'
  self.is_troop = true
  self.size = unit_size['medium-plus']
  self.is_weapon = true
  self.backswing = 0.2
  
  -- Reference to player cursor
  self.player_cursor = args.player_cursor
  self.team_index = args.team_index or 1
  
  -- Custom weapon stats (set before calculate_stats)
  self.custom_cast_time = args.custom_cast_time
  self.custom_attack_cooldown = args.custom_attack_cooldown
  self.custom_damage = args.custom_damage
  
  -- Position at cursor with offset
  if self.player_cursor then
    args.x = self.player_cursor.x
    args.y = self.player_cursor.y
  else
    args.x = args.x or gw/2
    args.y = args.y or gh/2
  end
  
  self:init_game_object(args)
  Helper.Unit:add_custom_variables_to_unit(self)
  
  -- Weapons have no collision
  self.no_collision = true
  
  self:init_unit()
  local level = self.level or 1

  self.hfx:add('attack_scale_x', 1, 50, 8) 
  self.hfx:add('attack_scale_y', 1, 50, 8)
  self.hfx:add('survivor_scale', 1, 100, 20)

  self:calculate_stats(true)

  -- Take character and items from args
  self.character = args.character
  self.items = args.items or {}
  self.passives = args.passives or {}
  
  self.color = character_colors[self.character]
  self.type = character_types[self.character]
  self.attack_sensor = self.attack_sensor or Circle(self.x, self.y, 40)
  
  self:set_character()
  
  Helper.Unit:set_state(self, unit_states['idle'])
  
  -- Weapon visual properties
  self.rotation_speed = args.rotation_speed or 0
  self.orbit_speed = args.orbit_speed or 2
end

function Weapon:stretch_on_attack()
  local stretch_factor = 0.4
  self.hfx:pull('attack_scale_y', stretch_factor)
  self.hfx:pull('attack_scale_x', - stretch_factor)
end

function Weapon:update_survivor_effect(dt)
  local survivor_boost = Helper.Unit:get_survivor_size_boost(self)
  self.hfx:animate('survivor_scale', survivor_boost)
end

function Weapon:update(dt)
  -- Essential housekeeping
  Weapon.super.update(self, dt)
  self:update_cast_cooldown(dt)
  self:onTickCallbacks(dt)
  self:update_buffs(dt)
  self:calculate_stats()
  self:update_targets()
  self:update_survivor_effect(dt)
  
  -- Follow player cursor
  if self.player_cursor and not self.player_cursor.dead then

    self.x = self.player_cursor.x
    self.y = self.player_cursor.y
    
    -- Update physics body if it exists
    if self.body then
      self.body:setPosition(self.x, self.y)
    end
    
    -- Set velocity to zero since we're manually positioning
    self:set_velocity(0, 0)
  end
  
  -- Auto-fire at enemies
  if table.contains(unit_states_can_cast, self.state) then
    if self.global_range then
      self.target = Helper.Target:get_close_enemy(self)
    else
      self.target = Helper.Target:get_closest_enemy(self)
    end
    if self.target then
      if Helper.Unit:can_cast(self, self.target) then
        self:setup_cast(self.target)
      end
    end
  end

  if self.state == unit_states['casting'] then
    if not self.target or self.target.dead then
      self:cancel_cast()
    end
  end

  -- Handle frozen state
  if self.state == unit_states['frozen'] then
    -- Do nothing while frozen
  elseif self.state == unit_states['casting'] then
    -- Continue casting
  end
  
  self.r = self:get_angle()
  self.attack_sensor:move_to(self.x, self.y)
end

function Weapon:draw()
  -- No drawing for weapons for now
  return
end

function Weapon:attack(area, mods)
  -- On attack callbacks
  if self.onAttackCallbacks then
    self:onAttackCallbacks(self.target)
  end
  mods = mods or {}
  local t = {group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = (area or 64), color = self.color, damage = function() return self.dmg end,
    character = self.character, level = self.level, parent = self, is_weapon = true, unit = self}
  Area(table.merge(t, mods))
end

function Weapon:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  -- Weapons redirect damage to player cursor
  if self.player_cursor and not self.player_cursor.dead then
    self.player_cursor:hit(damage, from, damageType, playHitEffects, cannotProcOnHit)
  end
end

function Weapon:take_damage(damage)
  -- Redirect to player cursor
  if self.player_cursor and not self.player_cursor.dead then
    self.player_cursor:take_damage(damage)
  end
end

function Weapon:die()
  Weapon.super.die(self)
  if self.dead then return end
  self.dead = true
  
  if self.parent and self.parent.summons then
    self.parent.summons = self.parent.summons - 1
  end
end

function Weapon:on_trigger_enter(other)
  -- Override in subclasses
  return
end

function Weapon:setup_cast(cast_target)
  -- Override in subclasses based on weapon type
end

function Weapon:set_character()
  -- Override in subclasses to define weapon-specific behavior
end

-- Apply item procs to this weapon
function Weapon:apply_item_procs()
  if not self.items then return end
  
  for _, item in pairs(self.items) do
    if item and item.procs then
      for _, proc in pairs(item.procs) do
        local procname = proc
        -- Create_Proc automatically adds the proc to the unit
        Create_Proc(procname, nil, self)
      end
    end
  end
  
  -- Apply passive procs
  if self.passives then
    for _, passive in pairs(self.passives) do
      if passive and passive.procs then
        for _, proc in pairs(passive.procs) do
          local procname = proc
          -- Create_Proc automatically adds the proc to the unit
          Create_Proc(procname, nil, self)
        end
      end
    end
  end
end
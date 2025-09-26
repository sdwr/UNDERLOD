require 'combat_stats/weapon_list'
require 'ui/owned_weapon_card'

OwnedWeaponDisplay = Object:extend()
OwnedWeaponDisplay.__class_name = 'OwnedWeaponDisplay'
OwnedWeaponDisplay:implement(GameObject)

function OwnedWeaponDisplay:init(args)
  self:init_game_object(args)
  
  self.weapons = args.weapons or {}
  self.parent = args.parent
  
  -- Display properties
  self.max_display = MAX_OWNED_WEAPONS

  self.CARD_WIDTH = 45
  self.CARD_SPACING = 10
  self.CARD_HEIGHT = 20
  
  -- Create weapon cards
  self.weapon_cards = {}
  self:refresh_cards()
end

function OwnedWeaponDisplay:refresh_cards()
  -- Clean up old cards
  for _, card in ipairs(self.weapon_cards) do
    card:die()
  end
  self.weapon_cards = {}

  -- Only create cards for owned weapons (skip empty slots)
  local owned_weapons = {}
  for i = 1, (MAX_OWNED_WEAPONS or 6) do
    if self.weapons[i] then
      table.insert(owned_weapons, {weapon = self.weapons[i], original_index = i})
    end
  end

  -- Calculate centering based on actual number of owned weapons
  local num_owned = #owned_weapons
  if num_owned == 0 then return end  -- No weapons to display

  local total_width = (num_owned * self.CARD_WIDTH) + (self.CARD_SPACING * (num_owned - 1))
  local start_x = self.x - total_width / 2 + self.CARD_WIDTH / 2

  -- Create cards only for owned weapons, centered
  for i, weapon_data in ipairs(owned_weapons) do
    local weapon = weapon_data.weapon
    local card = OwnedWeaponCard{
      group = self.group,
      x = start_x + (i-1) * (self.CARD_WIDTH + self.CARD_SPACING),
      y = self.y,
      w = self.CARD_WIDTH,
      h = self.CARD_HEIGHT,
      weapon_name = weapon.name,
      level = weapon.level,
      xp = weapon.xp or 0,
      weapon = weapon,
      index = weapon_data.original_index,
      is_empty = false
    }
    table.insert(self.weapon_cards, card)
  end
end

function OwnedWeaponDisplay:update(dt)
  self:update_game_object(dt)
  
  -- Update weapons from parent if available
  if self.parent and self.parent.weapons then
    local weapons_changed = false
    
    -- Check if weapons have changed (handle sparse array with nils)
    for i = 1, MAX_OWNED_WEAPONS do
      local weapon = self.weapons[i]
      local parent_weapon = self.parent.weapons[i]

      -- Check if slot changed from empty to filled or vice versa
      if (weapon == nil) ~= (parent_weapon == nil) then
        weapons_changed = true
        break
      end

      -- Check if both exist and properties changed
      if weapon and parent_weapon then
        if weapon.name ~= parent_weapon.name or
           weapon.level ~= parent_weapon.level or
           (weapon.xp or weapon.count or 0) ~= (parent_weapon.xp or parent_weapon.count or 0) then
          weapons_changed = true
          break
        end
      end
    end
    
    if weapons_changed then
      self.weapons = table.copy(self.parent.weapons)
      self:refresh_cards()
    end
  end
  
  -- Update weapon cards
  for _, card in ipairs(self.weapon_cards) do
    card:update(dt)
  end
end

function OwnedWeaponDisplay:draw()
  -- Draw weapon cards (no title)
  for _, card in ipairs(self.weapon_cards) do
    card:draw()
  end
end

function OwnedWeaponDisplay:die()
  self.dead = true

  -- Clean up cards
  for _, card in ipairs(self.weapon_cards) do
    card:die()
  end
  self.weapon_cards = {}
end
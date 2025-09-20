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

  -- Create cards for all weapon slots (owned and empty)
  local total_slots = MAX_OWNED_WEAPONS or 6
  local first_card_x_offset = (total_slots / 2 * self.CARD_WIDTH) + (self.CARD_SPACING * (total_slots - 1) / 2)

  for i = 1, total_slots do
    local weapon = self.weapons[i]  -- May be nil for empty slots
    local card = OwnedWeaponCard{
      group = self.group,
      x = self.x - first_card_x_offset + (i-1) * self.CARD_WIDTH + (i-1) * self.CARD_SPACING,
      y = self.y,
      w = self.CARD_WIDTH,
      h = self.CARD_HEIGHT,
      weapon_name = weapon and weapon.name or nil,
      level = weapon and weapon.level or nil,
      xp = weapon and (weapon.xp or 0) or nil,
      weapon = weapon,
      index = i,
      is_empty = not weapon
    }
    table.insert(self.weapon_cards, card)
  end
end

function OwnedWeaponDisplay:update(dt)
  self:update_game_object(dt)
  
  -- Update weapons from parent if available
  if self.parent and self.parent.weapons then
    local weapons_changed = false
    
    -- Check if weapons have changed
    if #self.weapons ~= #self.parent.weapons then
      weapons_changed = true
    else
      for i, weapon in ipairs(self.weapons) do
        local parent_weapon = self.parent.weapons[i]
        if not parent_weapon or 
           weapon.name ~= parent_weapon.name or 
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
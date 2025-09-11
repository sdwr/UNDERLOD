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
  
  -- Title text
  self.title_text = Text({{text = '[yellow]Owned Weapons', font = pixul_font, alignment = 'center'}}, global_text_tags)
end

function OwnedWeaponDisplay:refresh_cards()
  -- Clean up old cards
  for _, card in ipairs(self.weapon_cards) do
    card:die()
  end
  self.weapon_cards = {}
  
  -- Create new cards
  if self.weapons and #self.weapons > 0 then
    for i, weapon in ipairs(self.weapons) do
      local first_card_x_offset = (#self.weapons / 2 * self.CARD_WIDTH) + (self.CARD_SPACING * (#self.weapons - 1) / 2)
      local card = OwnedWeaponCard{
        group = self.group,
        x = self.x - first_card_x_offset + (i-1) * self.CARD_WIDTH + (i-1) * self.CARD_SPACING,
        y = self.y,
        w = self.CARD_WIDTH,
        h = self.CARD_HEIGHT,
        weapon_name = weapon.name,
        level = weapon.level,
        xp = weapon.xp or 0,  -- Support old 'count' field
        weapon = weapon,
        index = i
      }
      table.insert(self.weapon_cards, card)
    end
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
  -- Draw title
  if self.title_text then
    self.title_text:draw(self.x, self.y - 40)
  end
  
  if not self.weapons or #self.weapons == 0 then
    graphics.print('No weapons owned', pixul_font, self.x, self.y, 0, 1, 1, nil, nil, fg[-5])
    return
  end
  
  -- Draw weapon cards
  for _, card in ipairs(self.weapon_cards) do
    card:draw()
  end
  
  -- Show weapon count / max
  local count_text = #self.weapons .. '/' .. MAX_OWNED_WEAPONS .. ' weapons'
  local count_color = #self.weapons >= MAX_OWNED_WEAPONS and red[0] or fg[-3]
  graphics.print(count_text, pixul_font, self.x, self.y + 65, 0, 0.8, 0.8, nil, nil, count_color)
end

function OwnedWeaponDisplay:die()
  self.dead = true
  
  -- Clean up cards
  for _, card in ipairs(self.weapon_cards) do
    card:die()
  end
  self.weapon_cards = {}
  
  if self.title_text then
    self.title_text.dead = true
    self.title_text = nil
  end
end
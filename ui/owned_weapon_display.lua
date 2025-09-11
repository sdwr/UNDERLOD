require 'combat_stats/weapon_list'

OwnedWeaponDisplay = Object:extend()
OwnedWeaponDisplay.__class_name = 'OwnedWeaponDisplay'
OwnedWeaponDisplay:implement(GameObject)

function OwnedWeaponDisplay:init(args)
  self:init_game_object(args)
  
  self.weapons = args.weapons or {}
  self.parent = args.parent
  
  -- Display properties
  self.item_width = 80
  self.item_height = 30
  self.spacing = 10
  self.max_display = MAX_OWNED_WEAPONS
end

function OwnedWeaponDisplay:update(dt)
  self:update_game_object(dt)
  
  -- Update weapons from parent if available
  if self.parent and self.parent.weapons then
    self.weapons = self.parent.weapons
  end
end

function OwnedWeaponDisplay:draw()
  if not self.weapons or #self.weapons == 0 then
    graphics.print('No weapons owned', pixul_font, self.x, self.y, 0, 1, 1, nil, nil, fg[-5])
    return
  end
  
  -- Calculate starting position to center the display
  local total_width = #self.weapons * self.item_width + (#self.weapons - 1) * self.spacing
  local start_x = self.x - total_width / 2 + self.item_width / 2
  
  for i, weapon in ipairs(self.weapons) do
    local x = start_x + (i - 1) * (self.item_width + self.spacing)
    local y = self.y
    
    -- Background box
    graphics.rectangle(x - self.item_width/2, y - self.item_height/2, 
                       self.item_width, self.item_height, 2, 2, bg[3])
    
    -- Border
    local border_color = fg[0]
    if weapon.level >= WEAPON_MAX_LEVEL then
      border_color = yellow[5] -- Gold border for max level
    elseif weapon.count and weapon.count > 1 then
      border_color = blue[3] -- Blue border for partial upgrade
    end
    
    graphics.rectangle(x - self.item_width/2, y - self.item_height/2,
                       self.item_width, self.item_height, 2, 2, nil, 1, border_color)
    
    -- Weapon name
    local def = Get_Weapon_Definition(weapon.name)
    if def then
      local display_name = def.display_name
      -- Truncate if too long
      if #display_name > 10 then
        display_name = string.sub(display_name, 1, 8) .. '..'
      end
      graphics.print(display_name, pixul_font, x, y - 5, 0, 0.7, 0.7, nil, nil, fg[0])
    end
    
    -- Level and upgrade progress
    local level_text = 'Lv.' .. (weapon.level or 1)
    local text_color = fg[0]
    
    if weapon.level >= WEAPON_MAX_LEVEL then
      level_text = 'MAX'
      text_color = yellow[5]
    elseif weapon.count and weapon.count > 1 then
      level_text = level_text .. ' (' .. weapon.count .. '/' .. WEAPON_COPIES_TO_UPGRADE .. ')'
      text_color = blue[3]
    end
    
    graphics.print(level_text, pixul_font, x, y + 5, 0, 0.6, 0.6, nil, nil, text_color)
  end
  
  -- Show weapon count / max
  local count_text = #self.weapons .. '/' .. MAX_OWNED_WEAPONS .. ' weapons'
  local count_color = #self.weapons >= MAX_OWNED_WEAPONS and red[0] or fg[-3]
  graphics.print(count_text, pixul_font, self.x, self.y + self.item_height/2 + 10, 0, 0.8, 0.8, nil, nil, count_color)
end

function OwnedWeaponDisplay:die()
  self.dead = true
end
FloorItem = FloorInteractable:extend()
function FloorItem:init(args)
  -- Initialize floor interactable base class
  FloorItem.super.init(self, args)
  
  -- Generic properties
  self.item = args.item
  self.character = args.character -- For character selection
  self.perk = args.perk -- For perk selection
  self.is_character_selection = args.is_character_selection or false
  self.is_perk_selection = args.is_perk_selection or false
  
  if self.is_character_selection then
    -- Character selection mode
    self.cost = 0 -- Characters are free
    self.image = find_character_image(self.character)
    self.colors = character_to_color(self.character)
    self.tier_color = character_to_color(self.character)
    self.stats = {}
  elseif self.is_perk_selection then
    -- Perk selection mode
    self.cost = 0 -- Perks are free
    self.image = find_perk_image(self.perk)
    self.colors = get_rarity_color(self.perk.rarity or 'common')
    self.tier_color = get_rarity_color(self.perk.rarity or 'common')
    self.stats = {}
  else
    -- Item mode
    -- self.cost = self.item.cost
    self.cost = self.item.cost or 0
    self.image = find_item_image(self.item)
    self.colors = self.item.colors
    -- Use V2 item tier_color if available, otherwise fall back to item_to_color
    self.tier_color = item_to_color(self.item)
    self.stats = self.item.stats
    self.sets = self.item.sets
    self.name = self.item.name
  end
  
  -- Set up interaction callbacks
  self.on_activation = function()
    if self.is_character_selection then
      return self:select_character()
    elseif self.is_perk_selection then
      return self:select_perk()
    else
      return self:purchase_item()
    end
  end
  
  self.on_failed_activation = function()
    --no effect
  end

  self.can_activate_condition = function()
    if self.is_character_selection then
      return true
    elseif self.is_perk_selection then
      return true
    else
      if gold < self.cost then  
        return false
      end
      local unit, slot_index = main.current:find_available_inventory_slot(self.item)
      if not unit or not slot_index then
        return false
      end
    end
    return true
  end

  self.on_prevented_activation = function()
    if self.is_character_selection then
      return
    elseif self.is_perk_selection then
      return
    else
      if gold < self.cost then
        Create_Info_Text('not enough gold to buy item', self)
      else
        Create_Info_Text('no empty ' .. ITEM_SLOTS[self.item.slot].name .. ' slots - right click items in character menu to sell', self)
      end
    end
  end
  
  -- Mouse interaction
  self.shape = Rectangle(self.x, self.y, 60, 80)
  self.interact_with_mouse = true
  self.colliding_with_mouse = false

  if not self.is_character_selection and self.cost and self.cost > 0 then
    self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)
  end
  
  -- Create name text with wrapping
  if self.is_character_selection or self.is_perk_selection then
    self:create_name_text()
  end
  
  -- Create bottom half text (stats for items, description for perks)
  self:create_bottom_text()
  
  -- Creation effect
  self:creation_effect()
end

function FloorItem:create_name_text()
  -- Use item name if available, otherwise fall back to self.name
  local display_name = self.item and self.item.name or self.name
  -- Wrap the name text to fit within the card width (60px - 4px padding on each side = 52px)
  local wrapped_lines = self:wrap_text(display_name, 52, pixul_font)
  
  -- Create text definitions for each line
  local text_definitions = {}
  for _, line in ipairs(wrapped_lines) do
    table.insert(text_definitions, {text = '[fg]' .. line, font = pixul_font, alignment = 'center'})
  end
  
  self.name_text = Text(text_definitions, global_text_tags)
end

function FloorItem:create_bottom_text()
  if self.is_character_selection then
    self.bottom_text = nil
  elseif self.is_perk_selection then
    local name = self.perk.name or 'No perk name'
    local wrapped_lines = self:wrap_text(name, 52, pixul_font)
    local text_definitions = {}
    for _, line in ipairs(wrapped_lines) do
      table.insert(text_definitions, {text = '[fgm2]' .. line, font = pixul_font, alignment = 'center'})
    end
    self.bottom_text = Text(text_definitions, global_text_tags)
  else
    local stats_lines = {}

    if self.sets then
      for _, set_key in pairs(self.sets) do
        local set_def = ITEM_SETS[set_key]
        local color = set_def.color or 'orange'
        table.insert(stats_lines, {text = '[' .. color .. ']' .. set_def.name, font = pixul_font, alignment = 'center'})
      end
    end

    if self.stats then
      for key, val in pairs(self.stats) do
        local text = ''
        local display_name = item_stat_lookup and item_stat_lookup[key] or key
        if type(val) == 'number' then
          if key == 'gold' then
            text = '[yellow]+' .. val .. ' ' .. display_name
          elseif ITEM_STATS and ITEM_STATS[key] and ITEM_STATS[key].increment then
            text = '[yellow]+' .. val .. ' ' .. display_name
          else
            text = '[yellow]+' .. val .. ' ' .. display_name
          end
        else
          text = '[yellow]+' .. display_name
        end
        table.insert(stats_lines, {text = text, font = pixul_font, alignment = 'center'})
      end
    end
    if #stats_lines > 0 then
      self.bottom_text = Text(stats_lines, global_text_tags)
    else
      self.bottom_text = nil
    end
  end
end

function FloorItem:wrap_text(text, max_width, font)
  local lines = {}
  local current_line = ''
  -- Prevent errors if text is nil
  if not text then return {} end
  
  for word in text:gmatch("([^ ]+)") do
      local test_line = current_line == '' and word or current_line .. ' ' .. word
      
      if font:get_text_width(test_line) > max_width then
          table.insert(lines, current_line)
          current_line = word
      else
          current_line = test_line
      end
  end
  table.insert(lines, current_line)
  
  return lines
end

function FloorItem:creation_effect()
  if self.is_character_selection then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.is_perk_selection then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 5 then
    --no effect
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 10 then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 20 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 15 then
    pop1:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.4, 200, 10)
    for i = 1, 30 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  else
    gold3:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.6, 200, 10)
    for i = 1, 40 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  
  end
end

function FloorItem:update(dt)
  -- Call parent update (FloorInteractable)
  FloorInteractable.update(self, dt)
  
  if self.dead then return end
  
  -- Handle tooltip
  if self.colliding_with_mouse then
    if not self.tooltip then
      self:create_tooltip()
    end
  else
    self:remove_tooltip()
  end
  
end

function FloorItem:create_purchase_effect()
  for i = 1, 20 do
    HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color or grey[0]}
  end
end

function FloorItem:select_character()
  self.is_purchased = true

  self.parent:on_character_selected(self.character)
  
  self:create_purchase_effect()

  return true
end

function FloorItem:select_perk()
  self.is_purchased = true

  -- Add the perk to the player's perks
  local perk_key = nil
  for key, def in pairs(PERK_DEFINITIONS) do
    if def.name == self.perk.name then
      perk_key = key
      break
    end
  end
  
  if perk_key then
    local new_perk = Create_Perk(perk_key, 1) -- Start at level 1
    table.insert(main.current.perks, new_perk)
    
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    
    self:create_purchase_effect()
    
    -- Remove all perk floor items and continue to buy screen
    self.parent:remove_all_floor_items()
    
    main.current:save_run()
    return true
  end

  Create_Info_Text('perk not found', self)
  return false
end

function FloorItem:purchase_item()

  if self.item.cost and self.item.cost > 0 then
    if gold < self.item.cost then
      self:remove_tooltip()
      Create_Info_Text('not enough gold to buy item', self)
      return false
    end
  end
  
  -- Add item to first available slot
  local try_purchase = main.current:put_in_first_available_inventory_slot(self.item)
  if not try_purchase then
    self:remove_tooltip()
    Create_Info_Text('no empty ' .. ITEM_SLOTS[self.item.slot].name .. ' slots - right click items in character menu to sell', self)
    return false
  end

  self.is_purchased = true
  if self.item.cost and self.item.cost > 0 then
    gold = gold - self.item.cost
  end
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  self:die()
  
  self.parent:remove_all_floor_items()
  self.parent.items = {}

  self:create_purchase_effect()

  main.current:save_run()

  return true  
end

function FloorItem:draw()
  -- Calculate shake offset from floor interactable
  local shake_x = 0
  local shake_y = 0
  if self.interaction_shake_intensity > 0 then
    shake_x = random:float(-3, 3) * self.interaction_shake_intensity
    shake_y = random:float(-3, 3) * self.interaction_shake_intensity
  end
  
  graphics.push(self.x + shake_x, self.y + shake_y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
  
  -- Draw item background
  local width = 60
  local height = 80
  graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, bg[5])
  
  -- Draw item colors only on the top half
  if self.colors and not self.is_character_selection and not self.is_perk_selection then
    local num_colors = #self.colors
    local top_half_height = height / 2 -- Only use top half
    local color_h = top_half_height / num_colors
    for i, color_name in ipairs(self.colors) do
      local color = _G[color_name] or _G['brown']
      color = color[0]:clone()
      color.a = 0.6
      local y = (self.y - height/2) + ((i-1) * color_h) + (color_h/2)
      graphics.rectangle(self.x + shake_x, y + shake_y, width, color_h, 6, 6, color)
    end
  end
  
  -- Draw border with fallback color
  local border_color = self.tier_color or grey[0]
  graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, border_color, 2)
  
  --draw lock icon if interaction is disabled
  if self.interaction_is_disabled then
    self.locked_size = width * 0.5
    self.locked_scale_x = (self.locked_size / LOCKED_W) * LOCKED_SCALE
    self.locked_scale_y = (self.locked_size / LOCKED_H) * LOCKED_SCALE
    locked_image:draw(self.x, self.y + 10, 0, self.locked_scale_x, self.locked_scale_y, 0, 0, bg[1])
  end

  -- Draw name text at the top of the card
  if self.name_text then
    local name_y = self.y - height/2 + 8 -- Position at top with small padding
    self.name_text:draw(self.x + shake_x, name_y)
  end
  
  if self.cost_text then
    self.cost_text:draw(self.x + width/2, self.y - height/2)
  end
  
  -- Draw item image in the top half (centered in top 40px)
  if self.image then
    local image_y = self.y - height/2 + 20 -- Center in top half
    self.image:draw(self.x + shake_x, image_y, 0, 0.8, 0.8)
  end
  
  -- Draw bottom text just below the top section
  if self.bottom_text then
    local top_section_bottom = self.y + 3 -- The center of the card (boundary between top and bottom)
    local bottom_text_y = top_section_bottom + self.bottom_text.h/2-- Position just below the top section with small padding
    self.bottom_text:draw(self.x + shake_x, bottom_text_y)
  end
  
  -- Draw hover effect
  if self.interaction_is_hovered then
    local alpha = math.min(self.interaction_hover_timer / 2, 1)
    local radius = ((self.interaction_hover_timer / 2) * 20) + 10
    local color = white[0]
    color.a = alpha * 0.3
    graphics.rectangle(self.x + shake_x, self.y + shake_y, width, height, 6, 6, color)
    graphics.circle(self.x + shake_x, self.y + shake_y, radius, color)
  end
  
  graphics.pop()
end

function FloorItem:create_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end

  if self.is_character_selection then
    -- Create character tooltip
    self.tooltip = CharacterTooltip{
      group = self.parent.ui,
      character = self.character,
      x = gw/2, 
      y = gh/2 - 50,
    }
  elseif self.is_perk_selection then
    -- Create perk tooltip
    self.tooltip = PerkTooltip{
      group = self.parent.ui,
      perk = self.perk,
      x = gw/2, 
      y = gh/2 - 50,
    }
  else
    -- Create set bonus tooltip instead of item tooltip
    -- Show set bonuses for this specific item
    self.tooltip = SetBonusTooltip{
      group = self.parent.ui,
      item = self.item,
      x = gw/2, 
      y = gh/2 - 50,
    }
  end
end

function FloorItem:remove_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

function FloorItem:die()
  -- Call parent die (FloorInteractable)
  FloorInteractable.die(self)
  
  -- Ensure tooltip is removed before dying
  self:remove_tooltip()
  
  if self.name_text then
    self.name_text.dead = true
    self.name_text = nil
  end
  if self.bottom_text then
    self.bottom_text.dead = true
    self.bottom_text = nil
  end
end 
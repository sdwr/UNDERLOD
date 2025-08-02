Active_Inventory_Slot = nil
Character_Cards = {}

--still have duplicate text bug 
--hack workaround: add all card texts to a global table
--and clear them all when refreshing

--looks like it only happens after losing/restarting a run,
--where the old cards are not killed until the new ones are created

ALL_CARD_TEXTS = {}


function Refresh_All_Cards_Text()
  for i, text in ipairs(ALL_CARD_TEXTS) do
    if not text.dead then
      text.dead = true
    end
  end
  ALL_CARD_TEXTS = {}
  for i, card in ipairs(Character_Cards) do
    card:refreshText()
  end
end

function Kill_All_Cards()
  if not Character_Cards then return end
  for i, card in ipairs(Character_Cards) do
    if card.last_round_display then
      card.last_round_display:deactivate()
      card.last_round_display.dead = true
    end
    card:die()
  end
  Character_Cards = {}
  for i, text in ipairs(ALL_CARD_TEXTS) do
    text.dead = true
  end
end

CharacterCard = Object:extend()
CharacterCard:implement(GameObject)
function CharacterCard:init(args)
    Refresh_All_Cards_Text()
    self:init_game_object(args)
    self.background_color = args.background_color or bg[0]
    self.character = args.unit.character or 'none'
    self.character_color = args.unit.color or character_colors[self.character]
    self.character_color_string = character_color_strings[self.character]
    
    self.w = CHARACTER_CARD_WIDTH
    self.h = CHARACTER_CARD_HEIGHT
    self.shape = Rectangle(self.x, self.y, self.w, self.h)
    
    self.interact_with_mouse = true

    self.parts = {}
    self.items = {}
    
    --items
    self:createItemParts()

    --texts
    self:initText()

    self.set_bonus_hovered = false

    -- FIX: The call to Refresh_All_Cards_Text() has been removed from here.
    -- It should be called once, AFTER all cards have been created.
    
    if self.spawn_effect then SpawnEffect{group = main.current.world_ui, x = self.x, y = self.y, color = self.character_color} end
end

function CharacterCard:createItemParts()
    local item_x = self.x + CHARACTER_CARD_ITEM_X
    local item_y = self.y + CHARACTER_CARD_ITEM_Y

    for i = 1, MAX_ITEMS do
      if i <= UNIT_LEVEL_TO_NUMBER_OF_ITEMS[self.unit.level] then
        table.insert(self.items, ItemPart{group = self.group,
            x = item_x + (CHARACTER_CARD_ITEM_X_SPACING*((i-1) % 3)), 
            y = item_y + (i > 3 and 25 or 0),
            i = i, parent = self})
      end
    end
end

-- This now only creates the static name text.
function CharacterCard:initText()
    -- Create the refreshable UI elements
    self:createUIElements()
    
    self.proc_text = nil
end

function CharacterCard:createNameText()
  if self.name_text then
    self.name_text.dead = true
  end
  local class_text = '[' .. self.character_color_string .. '[3]]' .. self.unit.character .. ' ' .. self.unit.level
  self.name_text = Text({{text = class_text, font = pixul_font, alignment = 'center'}}, global_text_tags)
end

-- NEW FUNCTION: Handles creation of elements that need to be refreshed.
function CharacterCard:cleanupUIElements()
  -- Clean up buttons
  if self.unit_stats_icon then
    if self.unit_stats_icon.die then
      self.unit_stats_icon:die()
    else
      self.unit_stats_icon.dead = true
    end
  end
  
  if self.last_round_stats_icon then
    self.last_round_stats_icon.dead = true
  end

  -- Clean up set bonus elements
  if self.set_bonus_elements then
    for _, element in ipairs(self.set_bonus_elements) do
      element.dead = true
    end
    self.set_bonus_elements = {}
  end
  
  -- Clean up popups
  self:hide_popup()
  self:hide_set_bonus_popup()
  self:hide_last_round_popup()
end

function CharacterCard:createUIElements()
  
    self:createNameText()

    -- Ensure old elements are removed before creating new ones to prevent duplicates.
    self:cleanupUIElements()

    -- Create unit stats icon (small button next to class name)
    self.unit_stats_icon = Button{
        group = self.group,
        x = self.x + 35, -- Position to the right of the class name
        y = self.y - self.h/2 + 10, -- Same y as class name
        w = 12,
        h = 12,
        bg_color = 'bg',
        fg_color = 'bg10',
        button_text = 'U',
        action = function() end -- No action on click, just hover
    }
    self.unit_stats_icon.parent = self
    
    -- Create last round stats icon (small button to the left of the class name)
    self.last_round_stats_icon = Button{
        group = self.group,
        x = self.x - 35, -- Position to the left of the class name
        y = self.y - self.h/2 + 10, -- Same y as class name
        w = 12,
        h = 12,
        bg_color = 'bg',
        fg_color = 'bg10',
        button_text = 'S',
        action = function() end -- No action on click, just hover
    }
    self.last_round_stats_icon.parent = self
    
    -- Create set bonus display
    self:create_set_bonus_display()
end

function CharacterCard:create_set_bonus_display()
  -- Remove old set bonus elements
  if self.set_bonus_elements then
    for _, element in ipairs(self.set_bonus_elements) do
      element.dead = true
    end
  end
  
  self.set_bonus_elements = {}
  
  -- Get unit sets
  local unit_sets = self:get_unit_sets()
  
  if #unit_sets == 0 then return end
  
  -- Sort sets by name for consistent display
  table.sort(unit_sets, function(a, b) return a.name < b.name end)
  
  -- Create button elements for each set
  local y_offset = 0
  for i, set_info in ipairs(unit_sets) do
    local max_pieces = 0
    for pieces, _ in pairs(set_info.bonuses) do
      max_pieces = math.max(max_pieces, pieces)
    end
    
    local set_color = set_info.color or 'fg'
    local text = set_info.current_pieces .. ' / ' .. max_pieces .. ' ' .. set_info.name:upper()
    
    local set_button = Button{
      group = self.group,
      x = self.x,
      y = self.y - self.h/2 + 30 + y_offset, -- Move up under character name
      w = 80,
      h = 14,
      bg_color = 'bg',
      fg_color = set_color, -- Use set color for text
      button_text = text,
      action = function() end, -- No action on click, just hover
      set_info = set_info, -- Store set info for hover
      no_spring = true -- Disable spring effect
    }
    set_button.parent = self
    
    table.insert(self.set_bonus_elements, set_button)
    y_offset = y_offset + 16
  end
end

function CharacterCard:get_unit_sets()
  local sets = {}
  local set_counts = {}
  
  -- Count items by set
  if self.unit.items then
    for _, item in ipairs(self.unit.items) do
      if item and item.sets then
        for _, set_name in ipairs(item.sets) do
          set_counts[set_name] = (set_counts[set_name] or 0) + 1
        end
      end
    end
  end
  
  -- Build set info
  for set_name, count in pairs(set_counts) do
    local set_def = ITEM_SETS[set_name]
    if set_def then
      table.insert(sets, {
        name = set_name,
        current_pieces = count,
        bonuses = set_def.bonuses,
        color = set_def.color
      })
    end
  end
  
  return sets
end


function CharacterCard:show_last_round_stats_popup()
  -- Get all units to compare stats
  local all_units = {}
  for _, card in ipairs(Character_Cards) do
    if card.unit and card.unit.last_round_damage then
      table.insert(all_units, card.unit)
    end
  end
  
  -- Find best stats
  local best_damage = 0
  local best_dps = 0
  local best_kills = 0
  
  for _, unit in ipairs(all_units) do
    if unit.last_round_damage and unit.last_round_damage > best_damage then
      best_damage = unit.last_round_damage
    end
    if unit.last_round_dps and unit.last_round_dps > best_dps then
      best_dps = unit.last_round_dps
    end
    if unit.last_round_kills and unit.last_round_kills > best_kills then
      best_kills = unit.last_round_kills
    end
  end
  
  -- Create text lines for last round stats
  local text_lines = {}
  table.insert(text_lines, {text = '[bg10]Last Round', font = pixul_font, alignment = 'center'})
  
  if self.unit.last_round_dps and self.unit.last_round_damage then
    local damage_text = math.floor(self.unit.last_round_damage)
    local dps_text = string.format("%.1f", self.unit.last_round_dps)
    
    local damage_star = (self.unit.last_round_damage == best_damage and best_damage > 0) and ' *' or ''
    table.insert(text_lines, {text = '[red]DMG: [red]' .. damage_text .. damage_star, font = pixul_font, alignment = 'center'})
    
    local dps_star = (self.unit.last_round_dps == best_dps and best_dps > 0) and ' *' or ''
    table.insert(text_lines, {text = '[green]DPS: [green]' .. dps_text .. dps_star, font = pixul_font, alignment = 'center'})
    
    if self.unit.last_round_kills then
      local kills_star = (self.unit.last_round_kills == best_kills and best_kills > 0) and ' *' or ''
      table.insert(text_lines, {text = '[blue]Kills: [blue]' .. self.unit.last_round_kills .. kills_star, font = pixul_font, alignment = 'center'})
    end
  else
    table.insert(text_lines, {text = '[fg]No combat data', font = pixul_font, alignment = 'center'})
  end
  
  self.last_round_popup = InfoText{group = main.current.world_ui, force_update = false}
  self.last_round_popup:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.last_round_popup.x = self.x
  self.last_round_popup.y = self.y - self.h/2 + 60
end

function CharacterCard:hide_last_round_popup()
  if self.last_round_popup then
    self.last_round_popup:deactivate()
    self.last_round_popup = nil
  end
end



-- FIX: This function now correctly calls the refactored UI creation function.
function CharacterCard:refreshText()
    self:cleanupUIElements()
    self:createUIElements()
end

function CharacterCard:show_unit_stats_popup()
  local item_stats = get_unit_stats(self.unit)
  local text_lines = {}
  
  for stat_name, stat_value in pairs(item_stats) do
    local prefix, value, suffix, display_name = format_stat_display(stat_name, stat_value)
    table.insert(text_lines, { 
      text = '[yellow[0]]' .. prefix .. value .. suffix .. display_name:capitalize(), 
      font = pixul_font, 
      alignment = 'center' 
    })
  end
  
  -- Check if we actually have any stats (hash table, so check if it's empty)
  local has_stats = false
  for _ in pairs(item_stats) do
    has_stats = true
    break
  end
  
  if not has_stats then
    table.insert(text_lines, { 
      text = '[fg]No unit stats', 
      font = pixul_font, 
      alignment = 'center' 
    })
  end
  
  self.popup = InfoText{group = main.current.world_ui, force_update = false}
  self.popup:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.popup.x = self.x
  self.popup.y = self.y - self.h/2 + 60
end

function CharacterCard:show_set_bonus_popup_for_set(set_info)
  -- Create text lines for this specific set
  local text_lines = {}
  
  -- Set name header
  local set_color = set_info.color or 'fg'
  table.insert(text_lines, {
    text = '[' .. set_color .. ']' .. set_info.name:upper(), 
    font = pixul_font, 
    alignment = 'center'
  })
  
  -- Set bonuses
  for i = 1, MAX_SET_BONUS_PIECES do
    local bonus = set_info.bonuses[i]
    if bonus then
      local is_reached = set_info.current_pieces >= i
      local color = is_reached and set_color or 'fg[2]' -- Use set color if reached, gray if not
      
      local stat_name = ''
      if bonus.stats then
        for stat, value in pairs(bonus.stats) do
          if item_stat_lookup[stat] then
            stat_name = stat_name .. '+' .. value .. ' ' .. item_stat_lookup[stat] .. ', '
          else
            stat_name = stat .. ' stat not found'
          end
        end
      end
      if bonus.procs then
        for _, proc in ipairs(bonus.procs) do
          stat_name = stat_name .. proc .. ', '
        end
      end

      table.insert(text_lines, {
        text = '[' .. color .. ']' .. i .. 'pc: ' .. stat_name, 
        font = pixul_font, 
        alignment = 'left'
      })
    end
  end

  self:hide_set_bonus_popup()
  
  self.set_bonus_popup = InfoText{group = main.current.world_ui, force_update = false}
  self.set_bonus_popup:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.set_bonus_popup.x = self.x
  self.set_bonus_popup.y = self.y - self.h/2 - 10
end

function CharacterCard:hide_popup()
  if self.popup then
    self.popup:deactivate()
    self.popup = nil
  end
end

function CharacterCard:hide_set_bonus_popup()
  if self.set_bonus_popup then
    self.set_bonus_popup:deactivate()
    self.set_bonus_popup = nil
  end
end

function CharacterCard:refreshText()
  -- Remove old buttons if they exist
  if self.unit_stats_icon then
    self.unit_stats_icon.dead = true
  end
  
  -- Remove old last round stats icon if it exists
  if self.last_round_stats_icon then
    self.last_round_stats_icon.dead = true
  end

  if self.set_bonus_elements then
    for _, element in ipairs(self.set_bonus_elements) do
      element.dead = true
    end
    self.set_bonus_elements = {}
  end
  

  
  self:createUIElements()
end

function CharacterCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  --draw background
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.background_color)
  --draw text
  self.name_text:draw(self.x, self.y - (self.h/2) + 10)

  graphics.pop()
end
  
function CharacterCard:update(dt)
  self:update_game_object(dt)
  
  -- Check unit stats icon hover state
  if self.unit_stats_icon and self.unit_stats_icon.selected and not self.unit_stats_hovered then
    self.unit_stats_hovered = true
    self:show_unit_stats_popup()
  elseif self.unit_stats_icon and not self.unit_stats_icon.selected and self.unit_stats_hovered then
    self.unit_stats_hovered = false
    self:hide_popup()
  end
  
  -- Check set bonus elements hover state
  self.set_bonus_hovered = false
  if self.set_bonus_elements then
    for _, element in ipairs(self.set_bonus_elements) do
      if element.selected then
        self:show_set_bonus_popup_for_set(element.set_info)
        self.set_bonus_hovered = true
        break
      end
    end
    if not self.set_bonus_hovered then
      self:hide_set_bonus_popup()
    end
  end
  
  -- Check last round stats icon hover state
  if self.last_round_stats_icon and self.last_round_stats_icon.selected and not self.last_round_stats_hovered then
    self.last_round_stats_hovered = true
    self:show_last_round_stats_popup()
  elseif self.last_round_stats_icon and not self.last_round_stats_icon.selected and self.last_round_stats_hovered then
    self.last_round_stats_hovered = false
    self:hide_last_round_popup()
  end
  

end

function CharacterCard:die()
  --kill all items
  for i =1, 6 do
    if self.items[i] then
      self.items[i]:die()
    end
  end
  self.name_text.dead = true
  
  -- Clean up UI elements
  self:cleanupUIElements()
  
  self.dead = true
end

ItemPart = Object:extend()
ItemPart:implement(GameObject)
function ItemPart:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.sx * 20, self.sy * 20)
  self.interact_with_mouse = true
  self.itemGrabbed = false
  self.looseItem = nil
  self.info_text = nil

  self.h = 18
  self.w = 18

  self.spring:pull(0.2, 200, 10)
  self.just_created = true
  self.t:after(0.1, function() self.just_created = false end)
end

function ItemPart:hasItem()
  return not not self.parent.unit.items[self.i]
end

function ItemPart:addItem(item)
  self.parent.unit.items[self.i] = item
  Refresh_All_Cards_Text()
end

function ItemPart:sellItem()
  --kill the item first, to trigger the item's die function
  --have to create the item first to remove it
  -- unit.items is just the item data, not the item object
  if self.parent.unit.items[self.i] then
    local item = Create_Item(self.parent.unit.items[self.i].name)
    if item then
      if item.consumable then
        spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 1}
        --item:consume()
        Stats_Consume_Item()
      else
        --play sell sound
        spawn_mark1:play{pitch = random:float(0.8, 1.2), volume = 1}
        local sell_value = math.ceil(item.cost / 3)
        main.current:gain_gold(sell_value)

        Stats_Sell_Item()
        Stats_Max_Gold()
      end
      item:sell()
      self:remove_tooltip()
    end
  end

  --then remove the item from the unit
  self:removeItem()
end

function ItemPart:removeItem()
  self.parent.unit.items[self.i] = nil
  Refresh_All_Cards_Text()
end

function ItemPart:getItem()
  return self.parent.unit.items[self.i]
end

function ItemPart:isActiveInvSlot()
  return Active_Inventory_Slot == self
end

function ItemPart:update(dt)
  self:update_game_object(dt)

  if self.colliding_with_mouse then
    Active_Inventory_Slot = self
  elseif Active_Inventory_Slot == self then
    Active_Inventory_Slot = nil
  end

  if input.m1.pressed and self.colliding_with_mouse and self:hasItem() then
    self.itemGrabbed = true
    self.looseItem = LooseItem{group = main.current.world_ui, item = self:getItem(), parent = self}
    self:remove_tooltip()
  end

  if self.itemGrabbed and input.m1.released then
    self.itemGrabbed = false
    self.looseItem:die()
    self.looseItem = nil
    local active = Active_Inventory_Slot
    if active and not self:isActiveInvSlot() then
      if active:hasItem() then
        local temp = active:getItem()
        active:addItem(self:getItem())
        self:addItem(temp)
      else
        active:addItem(self:getItem())
        self:removeItem()
      end
      main.current:save_run()
    end
  end

  --differentiate between moving the item to another slot, and selling the item w m2
  if input.m2.released and not self.itemGrabbed and self:isActiveInvSlot() and self:hasItem() then
    self:sellItem()
    main.current:save_run()
  end

  if self.cant_click then return end

  self.shape:move_to(self.x, self.y)
end

function ItemPart:draw(y)
  if y then
    print("what is y doing here!?")
    print(y)
  end
  if not self.parent.grabbed then
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    local item = self.parent.unit.items[self.i]
    -- Use V2 item tier_color if available, otherwise fall back to item_to_color
    local tier_color = item and (item.tier_color or item_to_color(item)) or grey[0]
    graphics.rectangle(self.x, self.y, self.w+4, self.h+4, 3, 3, tier_color)
    graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg[5])

    if item then
      -- draw item background colors (duplicated from itemCard code)
      if item.colors then
        local num_colors = #item.colors
        local color_h = self.h / num_colors
        for i, color_name in ipairs(item.colors) do
          --make a copy of the color so we can change the alpha
          local color = _G[color_name]
          color = color[0]:clone()
          color.a = 0.6
          --find the y midpoint of the rectangle
          local y = (self.y - self.h/2) + ((i-1) * color_h) + (color_h/2)
  
          graphics.rectangle(self.x, y, self.w, color_h, 2, 2, color)
        end
      end

      local image = find_item_image(item)
      if not self.itemGrabbed then
        image:draw(self.x, self.y, 0, 0.4, 0.4)
      else
        --draw loose item instead
        -- local mouseX, mouseY = camera:get_mouse_position()
        -- image:draw(mouseX, mouseY, 0, 0.4, 0.4)
      end
    end
    
    if self.colliding_with_mouse and main.current and not main.current.loose_inventory_item then
      if not self.tooltip then
        self:create_tooltip()
      end
    else
      self:remove_tooltip()
    end
    graphics.pop()
  end
end



function ItemPart:die()
  self.dead = true
  Refresh_All_Cards_Text()
  if Active_Inventory_Slot == self then
    Active_Inventory_Slot = nil
  end
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

function ItemPart:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.selected = true
  self.spring:pull(0.2, 200, 10)

  self:create_tooltip()
end

--BUG: calls as soon as entered sometimes
function ItemPart:on_mouse_exit()
  self.selected = false
  if self.tooltip then 
    self.tooltip:die() 
    self.tooltip = nil
  end
end

function ItemPart:create_tooltip()
  if not self:hasItem() then return end

  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end

  self.tooltip = ItemTooltip{
    group = main.current.world_ui,
    item = self:getItem(),
    x = gw/2, 
    y = gh/2 - 50,
  }
end

function ItemPart:remove_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end



function ItemPart:highlight()
self.highlighted = true
self.spring:pull(0.2, 200, 10)
end


function ItemPart:unhighlight()
self.highlighted = false
self.spring:pull(0.05, 200, 10)
end

function CharacterCard:update_button_positions()
  -- Update unit stats icon position
  if self.unit_stats_icon then
    self.unit_stats_icon.x = self.x + 35
    self.unit_stats_icon.y = self.y - self.h/2 + 10
  end
  
  -- Update last round stats icon position
  if self.last_round_stats_icon then
    self.last_round_stats_icon.x = self.x - 35
    self.last_round_stats_icon.y = self.y - self.h/2 + 10
  end
  
  -- Update level up button position
  if self.level_up_button then
    self.level_up_button.x = self.x
    self.level_up_button.y = self.y - 5
  end
  

end

-- Custom Level Up Button Class
LevelUpButton = Object:extend()
LevelUpButton:implement(GameObject)
function LevelUpButton:init(args)
  self:init_game_object(args)
  self.parent = args.parent
  self.w = 40
  self.h = 20
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.enabled = true
  
  -- Initialize appearance
  self:update_appearance()
end

function LevelUpButton:update(dt)
  self:update_game_object(dt)

  if not self.interact_with_mouse then return end
  if not self.enabled then return end
  
  -- Handle click
  if self.selected and input.m1.pressed then
    self.parent:level_up_unit()
  end
end

function LevelUpButton:update_appearance()
  local cost = self.parent:get_level_up_cost()
  if cost == 999 then
    self.enabled = false
  end
  local can_afford = self.parent:can_afford_level_up()
  
  -- Update button appearance based on affordability
  if can_afford then
    self.bg_color = bg[10]
    self.fg_color = yellow[0] -- Yellow outline when affordable
    self.interact_with_mouse = true -- Enable mouse interaction
  else
    self.bg_color = bg[10]
    self.fg_color = fg[0]
    self.interact_with_mouse = false -- Disable mouse interaction
  end
  
  -- Update cost text
  local color_string = can_afford and 'yellow[0]' or 'bg10'
  self.cost_text = 'Level up: ' .. cost
  self.text_color = color_string
end

function LevelUpButton:draw()
  if not self.enabled then return end
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
  
  -- Draw button background
  graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, self.bg_color)
  
  -- Draw button border
  graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, self.fg_color, 2)
  
  -- Draw plus symbol
  local plus_text = Text({{text = '[fg]+', font = pixul_font, alignment = 'center'}}, global_text_tags)
  plus_text:draw(self.x, self.y)
  
  -- Draw level up text above the button
  local level_text = Text({{text = '[' .. self.text_color .. ']' .. self.cost_text, font = pixul_font, alignment = 'center'}}, global_text_tags)
  level_text:draw(self.x, self.y - 20)
  
  graphics.pop()
end

function LevelUpButton:on_mouse_enter()
  if self.interact_with_mouse then
    ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
    self.selected = true
    self.spring:pull(0.2, 200, 10)
  end
end

function LevelUpButton:on_mouse_exit()
  self.selected = false
end

function LevelUpButton:die()
  self.dead = true
end
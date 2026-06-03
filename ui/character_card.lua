Active_Inventory_Slot = nil
Loose_Inventory_Item = nil
Character_Cards = {}

--still have duplicate text bug 
--hack workaround: add all card texts to a global table
--and clear them all when refreshing

--looks like it only happens after losing/restarting a run,
--where the old cards are not killed until the new ones are created

ALL_CARD_TEXTS = {}


-- Items are laid out in a flat 3-col grid, filled left->right, top->bottom.
ITEM_LIST_COLUMNS = 3
function get_item_list_location(i)
  local col = (i - 1) % ITEM_LIST_COLUMNS
  local row = math.floor((i - 1) / ITEM_LIST_COLUMNS)
  return {x = col, y = row}
end

function Refresh_All_Cards_Text()
  for _, text in pairs(ALL_CARD_TEXTS) do
    if not text.dead then
      text.dead = true
    end
  end
  ALL_CARD_TEXTS = {}
  for _, card in pairs(Character_Cards) do
    card:refreshText()
  end
end

function Kill_All_Cards()
  if not Character_Cards then return end
  for _, card in pairs(Character_Cards) do
    if card.last_round_display then
      card.last_round_display:deactivate()
      card.last_round_display.dead = true
    end
    card:die()
  end
  Character_Cards = {}
  for _, text in pairs(ALL_CARD_TEXTS) do
    text.dead = true
  end
end

CharacterCard = Object:extend()
CharacterCard.__class_name = 'CharacterCard'
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

    -- FIX: The call to Refresh_All_Cards_Text() has been removed from here.
    -- It should be called once, AFTER all cards have been created.
    
    if self.spawn_effect then SpawnEffect{group = main.current.world_ui, x = self.x, y = self.y, color = self.character_color} end
end

-- ItemParts on the character card are wide pills with the set name inside
-- instead of a square icon. Initial positions don't matter — layout_item_parts
-- overrides (x, y) every frame. Sizes live in ui_constants.lua.
function CharacterCard:createItemParts()
    local item_x = self.x + CHARACTER_CARD_ITEM_X
    local item_y = self.y + CHARACTER_CARD_ITEM_Y

    for i = 1, MAX_ITEMS do
      if i <= UNIT_LEVEL_TO_NUMBER_OF_ITEMS[self.unit.level] then
        local location = get_item_list_location(i)
        table.insert(self.items, ItemPart{group = self.group,
            x = item_x + (CHARACTER_CARD_ITEM_X_SPACING*location.x),
            y = item_y + (CHARACTER_CARD_ITEM_Y_SPACING*location.y),
            w = CARD_ITEM_PART_WIDTH, h = CARD_ITEM_PART_HEIGHT,
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

function CharacterCard:cleanupUIElements()
  if self.inventory_count_text then
    self.inventory_count_text.dead = true
    self.inventory_count_text = nil
    self.inventory_count_last = nil
  end

  self:hide_popup()
  self:hide_last_round_popup()
end

function CharacterCard:createUIElements()
  self:createNameText()
  self:cleanupUIElements()
  -- inventory_count_text is built lazily on the first refresh, so we don't
  -- duplicate the format string here.
end

function CharacterCard:current_item_count()
  local n = 0
  if self.unit and self.unit.items then
    for _, item in pairs(self.unit.items) do
      if item then n = n + 1 end
    end
  end
  return n
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
  
  self.last_round_popup = InfoText{group = self.group, force_update = false}
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
  
  self.popup = InfoText{group = main.current.ui_top or self.group, force_update = false}
  self.popup:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.popup.x = self.x
  self.popup.y = self.y - self.h/2 + 60
end

function CharacterCard:hide_popup()
  if self.popup then
    self.popup:deactivate()
    self.popup = nil
  end
end

function CharacterCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  --draw background
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.background_color)
  --draw text
  self.name_text:draw(self.x, self.y - (self.h/2) + 10)

  -- x/6 inventory count, sitting just above the bottom edge of the card.
  if self.inventory_count_text then
    self.inventory_count_text:draw(self.x, self.y + self.h/2 - 8)
  end

  graphics.pop()
end
  
function CharacterCard:update(dt)
  if self.dead then return end
  self:update_game_object(dt)

  -- Item layout: vertical list grouped by the displayed set, duplicates stack
  -- horizontally on the same row. Recomputed every frame so add/sell/swap
  -- show up immediately without an explicit refresh.
  self:layout_item_parts()
  self:refresh_inventory_count_text()
end

-- Walks unit.items, builds one row per displayed set, and positions the
-- corresponding ItemParts horizontally on that row. ItemParts whose slot is
-- empty are flagged hidden so they neither draw nor accept mouse hits;
-- interact_with_mouse alone keeps them out of hover/click without any
-- shape-parking or tooltip-killing busywork in the per-frame loop.
function CharacterCard:layout_item_parts()
  if not self.items or not self.unit or not self.unit.items then return end

  for _, part in ipairs(self.items) do
    part.hidden = true
    part.interact_with_mouse = false
  end

  -- One ordered list of {key=..., indices={...}} per visible group. Walking
  -- unit.items in slot order means a linear scan to find an existing group
  -- (max MAX_ITEMS groups) — cheaper and shorter than parallel key+order
  -- tables.
  local groups = {}
  for idx = 1, MAX_ITEMS do
    local item = self.unit.items[idx]
    if item then
      local key = (item.sets and item.sets[1]) or '_no_set'
      local group
      for _, g in ipairs(groups) do
        if g.key == key then group = g; break end
      end
      if not group then
        group = {key = key, indices = {}}
        table.insert(groups, group)
      end
      table.insert(group.indices, idx)
    end
  end

  local row_spacing = 17
  local col_spacing = CARD_ITEM_PART_WIDTH + 2
  local first_row_y = self.y - self.h/2 + 28
  local row_left = self.x - self.w/2 + 6

  for row_i, group in ipairs(groups) do
    local row_y = first_row_y + (row_i - 1) * row_spacing
    for col_i, slot_index in ipairs(group.indices) do
      local part = self.items[slot_index]
      if part then
        part.hidden = false
        part.interact_with_mouse = true
        part.x = row_left + (col_i - 1) * col_spacing + CARD_ITEM_PART_WIDTH/2
        part.y = row_y
        if part.shape then part.shape:move_to(part.x, part.y) end
      end
    end
  end

  -- Drop-target zone: while an item is being dragged from another card, expose
  -- the first empty slot here so the player has a visible landing spot. The
  -- slot itself does the drop_target_glow pulse in ItemPart:draw.
  if Loose_Inventory_Item
     and Loose_Inventory_Item.parent
     and Loose_Inventory_Item.parent.parent ~= self then
    local empty_idx = nil
    for idx = 1, MAX_ITEMS do
      if self.items[idx] and not self.unit.items[idx] then
        empty_idx = idx
        break
      end
    end
    if empty_idx then
      local part = self.items[empty_idx]
      local row_y = first_row_y + #groups * row_spacing
      part.hidden = false
      part.interact_with_mouse = true
      part.x = row_left + CARD_ITEM_PART_WIDTH/2
      part.y = row_y
      if part.shape then part.shape:move_to(part.x, part.y) end
    end
  end
end

-- Lazily creates the count text, and only fires set_text when the count
-- actually changes — avoids a fresh table literal + two garbage strings
-- per card per frame.
function CharacterCard:refresh_inventory_count_text()
  local count = self:current_item_count()
  if not self.inventory_count_text then
    self.inventory_count_text = Text({{text = '[bg10]' .. count .. '/' .. MAX_ITEMS, font = pixul_font, alignment = 'center'}}, global_text_tags)
    table.insert(ALL_CARD_TEXTS, self.inventory_count_text)
    self.inventory_count_last = count
    return
  end
  if count ~= self.inventory_count_last then
    self.inventory_count_text:set_text({{text = '[bg10]' .. count .. '/' .. MAX_ITEMS, font = pixul_font, alignment = 'center'}})
    self.inventory_count_last = count
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
ItemPart.__class_name = 'ItemPart'
ItemPart:implement(GameObject)
function ItemPart:init(args)
  self:init_game_object(args)
  self.w = args.w or ITEM_PART_WIDTH
  self.h = args.h or ITEM_PART_HEIGHT
  self.shape = Rectangle(self.x, self.y, self.sx * (self.w + 2), self.sy * (self.h + 2))
  self.interact_with_mouse = true
  self.itemGrabbed = false
  self.info_text = nil

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

function ItemPart:create_item_added_effect(item)
  if not item then return end
  
  -- Get item tier color
  local tier_color = item.tier_color or item_to_color(item) or grey[0]
  
  -- Create hit particles at the ItemPart position
  for i = 1, 15 do
    HitParticle{
      group = main.current.effects, 
      x = self.x, 
      y = self.y, 
      color = tier_color
    }
  end
  
  -- Play a sound effect
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.4}
end

function ItemPart:sellItem()

  --dont create an item object
  --add that back when there are consumables or sell effects

  local item = self.parent.unit.items[self.i]
  if item then
    if item.consumable then
      spawn_mark2:play{pitch = random:float(0.8, 1.2), volume = 1}
      --item:consume()
      Stats_Consume_Item()
    else
      --play sell sound
      coins1:play{pitch = random:float(0.8, 1.2), volume = 1}
      local sell_value = math.floor(item.cost / 2)
      gold = gold + sell_value

      Stats_Sell_Item()
      Stats_Max_Gold()
    end
    self:remove_tooltip()
  end

  self:removeItem()
  Save_Run_From_Current()
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

  -- Disable interaction only when item is hidden
  if self.hide_item_display then
    self.interact_with_mouse = false
    if Active_Inventory_Slot == self then
      Active_Inventory_Slot = nil
    end
  else
    self.interact_with_mouse = true

    if self.colliding_with_mouse then
      Active_Inventory_Slot = self
    elseif Active_Inventory_Slot == self then
      Active_Inventory_Slot = nil
    end
  end

  -- Drop-target glow: while a Loose_Inventory_Item is in flight, any empty
  -- slot on a *different* card lights up so the player can see where the
  -- item can land. Source card's empty slots are intentionally excluded —
  -- moving within the same unit is the trivial case.
  if Loose_Inventory_Item and not self.hidden and not self:hasItem()
     and Loose_Inventory_Item.parent ~= self
     and Loose_Inventory_Item.parent
     and Loose_Inventory_Item.parent.parent ~= self.parent then
    self.drop_target_glow = true
  else
    self.drop_target_glow = false
  end

  if input.m1.pressed and self.colliding_with_mouse and self:hasItem() and not Loose_Inventory_Item then
    self.itemGrabbed = true
    Loose_Inventory_Item = LooseItem{group = main.current.ui, item = self:getItem(), parent = self}
    self:remove_tooltip()
  end

  if self.itemGrabbed and input.m1.released then
    self.itemGrabbed = false
    --loose item dies when it reaches the target slot
    --and has to be manually killed when you drop it on a new slot
    local loose_item = Loose_Inventory_Item
    Loose_Inventory_Item = nil
    local source_item = self:getItem()
    local active = Active_Inventory_Slot
    
    -- Determine what to do based on target
    if active and not self:isActiveInvSlot() then
      -- Any slot accepts any item
      if active:hasItem() then
        -- SWAP: Exchange items between slots
        local target_item = active:getItem()
        
        -- Do the swap immediately without triggering refreshes
        self.parent.unit.items[self.i] = nil
        active.parent.unit.items[active.i] = nil
        active.parent.unit.items[active.i] = source_item
        self.parent.unit.items[self.i] = target_item
        main.current:save_run()
                
        -- Loose item creates particle effect and dies at target
        loose_item:move_item_to_slot(active, function()
          active:create_item_added_effect(source_item)
        end, true, 0)

        active.just_dropped_item = true
        
        -- Create displaced item animation
        local swap_item = LooseItem{group = main.current.ui, item = target_item, parent = active}
        swap_item.x = active.x
        swap_item.y = active.y
        swap_item:move_item_to_slot(self, function()
          self.hide_item_display = false
          Refresh_All_Cards_Text()
        end, true, 0.2)
        
      else
        -- MOVE: Simple move to empty slot
        self:removeItem()
        active:addItem(source_item)
        main.current:save_run()

        Refresh_All_Cards_Text()

        loose_item:move_item_to_slot(active, function()
          active:create_item_added_effect(source_item)
        end, true, 0)
        
      end
    
    else
      -- RETURN: No valid target, return to original slot
      loose_item:move_item_to_slot(self, function()
        self.hide_item_display = false
      end, false, 0)
    end
    
    if active then
      active.just_dropped_item = true
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

function ItemPart:draw()
  if self.hidden then return end
  if not self.parent.grabbed then
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    local item = self.parent.unit.items[self.i]
    -- Use V2 item tier_color if available, otherwise fall back to item_to_color
    -- But show default color when item is grabbed
    local tier_color = (item and not self.itemGrabbed and not self.hide_item_display) and (item.tier_color or item_to_color(item)) or grey[0]
    -- When a meta-color row is being hovered, items contributing to that
    -- color get a yellow frame so they pop against the rest of the inventory.
    if self.highlighted then tier_color = yellow[0] end
    -- Drop-target glow: pulse a green border on empty slots across other
    -- units while an item is mid-drag, indicating valid drop locations.
    if self.drop_target_glow then
      local pulse = 0.6 + 0.4 * math.abs(math.sin(love.timer.getTime() * 4))
      local glow = green[0]:clone()
      glow.a = pulse
      tier_color = glow
    end
    graphics.rectangle(self.x, self.y, self.w+4, self.h+4, 3, 3, tier_color)
    graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg[5])

    if item and not self.hide_item_display and not self.itemGrabbed then
      -- Cache the tinted color + truncated label keyed by the item itself;
      -- this draw runs every frame per visible part, and item identity only
      -- changes on add/swap/sell.
      if self.cached_item ~= item then
        local set_key = item.sets and item.sets[1]
        local set_def = set_key and ITEM_SETS[set_key]
        local color_name = set_def and set_def.color or 'grey'
        local tint = (_G[color_name] or grey)[0]:clone()
        tint.a = 0.6
        self.cached_tint = tint
        self.cached_label = (set_def and set_def.name or '-'):sub(1, 8)
        self.cached_item = item
      end

      graphics.rectangle(self.x, self.y, self.w, self.h, 2, 2, self.cached_tint)
      graphics.print_centered(self.cached_label, pixul_font, self.x, self.y, 0, 1, 1, 0, 0, fg[0])
    end
    
    if self.colliding_with_mouse and main.current and not Loose_Inventory_Item and not self.just_dropped_item then
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

  -- Re-enable interaction if it was disabled from dropping an item
  if self.just_dropped_item then
    self.just_dropped_item = false
  end

  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

function ItemPart:create_tooltip()
  if self.tooltip then return end
  local item = self:getItem()
  if not item then return end
  self.tooltip = SetBonusTooltip{
    group = main.current.ui_top or self.group,
    item = item,
    x = self.x,
    y = self.y - 40,
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
  -- No header buttons to reposition currently.
end


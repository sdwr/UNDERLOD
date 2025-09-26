--find a way for clicks to buy into first empty slot
--need either a time check or distance check
--so that if you click and drag, you can drop halfway to cancel the buy
ItemCard = BaseCard:extend()
function ItemCard:init(args)
  -- Set up item-specific properties before calling super
  self.item = args.item

  -- Use weapon icon instead of item icon
  if self.item.assigned_weapon then
    local weapon_def = Get_Weapon_Definition(self.item.assigned_weapon)
    if weapon_def and weapon_def.icon then
      args.image = item_images[weapon_def.icon] or item_images['default']
    else
      args.image = item_images['default']
    end
  else
    args.image = find_item_image(self.item)
  end

  args.colors = self.item.colors
  args.tier_color = self.item.tier_color or item_to_color(self.item)
  args.name = self.item.name

  -- Call parent constructor
  ItemCard.super.init(self, args)
  
  -- Item-specific properties
  self.cost = 0  -- No cost anymore
  self.stats = self.item.stats
  self.sets = self.item.sets
  self.origX = self.x
  self.origY = self.y
  self.assigned_weapon = self.item.assigned_weapon
  self.assigned_weapon_index = self.item.assigned_weapon_index

  -- Items are no longer draggable/moveable
  self.can_drag = false
  
  -- Scaling behavior near character slots
  self.base_scale = 1
  self.current_scale = 1
  self.shrink_threshold_y = gh/2 - 25 + 80 -- Character card Y + some buffer

  -- No cost text needed anymore

  -- Create weapon assignment indicator
  if self.assigned_weapon then
    local weapon_def = Get_Weapon_Definition(self.assigned_weapon)
    if weapon_def then
      self.weapon_name_text = Text({{text = '[fg]' .. weapon_def.display_name, font = pixul_font, alignment = 'center'}}, global_text_tags)
    end
  end

  -- Set bonus elements
  self.set_bonus_elements = {}
  if self.sets then
    self:create_set_bonus_elements()
  end
  self.set_button_hovered = false

  -- Create stats text
  self:create_stats_text()
  
  -- Play creation effect
  self:creation_effect()
end

function ItemCard:create_set_bonus_elements()
  local i = 0

  for _, set_key in pairs(self.sets) do
    local set_def = ITEM_SETS[set_key]
    local color = set_def.color or 'orange'

    local text = set_def.name

    local set_button = Button{
      group = self.group,
      parent = self,
      x = 0, -- Position relative to ItemCard center
      y = 10 + i*20, -- Position relative to ItemCard center
      bg_color = 'bg',
      selected_bg_color = fg[-5],
      fg_color = set_def.color or 'orange',
      button_text = set_def.name or "unknown set",
      action = function() end, -- No action on click, just hover
      set_info = set_def, -- Store set info for hover
      no_spring = true, -- Keep no_spring since we'll handle positioning manually
    }

    table.insert(self.set_bonus_elements, set_button)
    i = i + 1
  end
end

function ItemCard:create_stats_text()
  local stats_lines = {}

  --add blank lines so the stats show up below the set buttons
  if self.sets then
    for _, set_key in pairs(self.sets) do
      local set_def = ITEM_SETS[set_key]
      local color = set_def.color or 'orange'
      table.insert(stats_lines, {text = '', font = pixul_font, alignment = 'center'})
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

-- wrap_text is now inherited from BaseCard

-- creation_effect is now inherited from BaseCard

function ItemCard:find_item_part_at_position(x, y)
  -- Check all character cards for ItemParts at this position
  if not Character_Cards then return nil, nil end
  
  for _, card in ipairs(Character_Cards) do
    if card.items then
      for _, item_part in ipairs(card.items) do
        if item_part.shape and item_part.shape:is_colliding_with_point(x, y) then
          return item_part, card.unit
        end
      end
    end
  end
  return nil, nil
end

function ItemCard:handle_purchase_transaction()
  -- Play purchase sound
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}

  self.parent.shop_item_data[self.i] = nil
  self.parent:save_run()
end

function ItemCard:buy_item_to_slot(item_part, unit)
  -- Use the same logic as the existing buy_item but for a specific slot
  local slot_index = item_part.i
  
  -- Check if this unit has this slot and it's empty
  if unit.items[slot_index] then
    Create_Info_Text('slot occupied', self, 'error')
    return false
  end
  
  -- Any item can go in any slot now - no type checking needed
  
  -- Check gold (same as existing)
  if gold < self.cost then
    Create_Info_Text('not enough gold', self, 'error')
    return false
  end
  
  -- Handle purchase transaction
  self:handle_purchase_transaction()
  unit.items[slot_index] = self.item

  -- Create particle effect at the target slot
  item_part:create_item_added_effect(self.item)

  -- Notify buy screen that an item was purchased
  if self.parent.on_item_purchased then
    self.parent:on_item_purchased(unit, slot_index, self.item)
  end

  self:die()
  return true
end

function ItemCard:update_scale_based_on_position()
  if not self.grabbed then return end
  
  local character_y = gh/2 - 25 -- Character card Y position from buy_screen.lua:359
  local distance_to_chars = math.abs(self.y - character_y)
  
  -- Also check radius from character card area
  local char_area_x = gw/2 -- Approximate center of character area
  local char_area_y = character_y
  local radius_to_chars = math.sqrt((self.x - char_area_x)^2 + (self.y - char_area_y)^2)
  
  -- Use whichever distance is smaller (y-axis or radius)
  local effective_distance = math.min(distance_to_chars, radius_to_chars)
  
  -- Scale from 1.0 to ItemPart size based on distance (closer = smaller)
  local max_distance = 100 -- Distance at which scaling begins
  local min_scale = ITEM_PART_WIDTH / self.w -- ItemPart size / ItemCard size
  local max_scale = 1.0
  
  if effective_distance < max_distance then
    local scale_factor = effective_distance / max_distance
    self.current_scale = min_scale + (max_scale - min_scale) * scale_factor
  else
    self.current_scale = max_scale
  end
  
  -- Make it squish to square when shrinking (adjust height scale)
  local target_aspect_ratio = ITEM_PART_WIDTH / ITEM_PART_HEIGHT -- Should be 1.0 (square)
  local current_aspect_ratio = self.w / self.h -- 60/80 = 0.75
  
  if self.current_scale < 1.0 then
    -- Adjust height scaling to make it more square-like as it shrinks
    local square_factor = 1.0 - (1.0 - self.current_scale) * 0.5 -- Gentler height adjustment
    self.sx = self.current_scale
    self.sy = self.current_scale * (current_aspect_ratio / target_aspect_ratio) * square_factor
  else
    self.sx = self.current_scale
    self.sy = self.current_scale
  end
end

function ItemCard:buy_item()
  -- Check if we're in BuyScreen
  if self.parent and self.parent:is(BuyScreen) and self.parent.weapons then
    -- Find the assigned weapon
    local target_weapon = nil
    if self.assigned_weapon_index then
      target_weapon = self.parent.weapons[self.assigned_weapon_index]
    end

    if not target_weapon then
      Create_Info_Text('weapon not found', self, 'error')
      return
    end

    -- Initialize items array if not present
    if not target_weapon.items then
      target_weapon.items = {}
    end

    -- Find available slot in this specific weapon (up to 6 items)
    local slot_index = nil
    for i = 1, 6 do
      if not target_weapon.items[i] then
        slot_index = i
        break
      end
    end

    if not slot_index then
      Create_Info_Text('weapon has max items', self, 'error')
      return
    end

    -- Add item to weapon
    target_weapon.items[slot_index] = self.item

    -- Handle purchase
    self:handle_purchase_transaction()

    -- Save and refresh
    if self.parent.save_run then
      self.parent:save_run()
    end
    if self.parent.set_party then
      self.parent:set_party()
    end

    -- Notify parent of purchase
    if self.parent.on_item_purchased then
      self.parent:on_item_purchased(nil, nil, self.item)
    end

    -- Remove the card
    self.t:after(0.1, function()
      self:die()
    end)

    return
  end

  -- Original behavior for non-BuyScreen
  local unit, slot_index = Helper.Unit:find_available_inventory_slot(self.parent.units, self.item)

  if not unit or not slot_index then
    print("no available slot to buy item")
    return
  end
  
  -- Find the target ItemPart for animation
  local target_item_part = nil
  if Character_Cards then
    for _, card in ipairs(Character_Cards) do
      if card.unit == unit and card.items then
        for _, item_part in ipairs(card.items) do
          if item_part.i == slot_index then
            target_item_part = item_part
            break
          end
        end
      end
      if target_item_part then break end
    end
  end
  
  if target_item_part then
    -- Start flying animation
    self:start_buy_animation(target_item_part, unit, slot_index)
  else
    -- Fallback to immediate purchase if can't find target
    self:complete_purchase(unit, slot_index)
  end
end

function ItemCard:start_buy_animation(target_item_part, unit, slot_index)
  -- Handle purchase transaction immediately
  self:handle_purchase_transaction()
  
  -- Set flag on target ItemPart to hide display (item not assigned yet)
  target_item_part.hide_item_display = true
  
  -- Disable mouse interaction during animation
  self.interact_with_mouse = false
  self.flying_to_slot = true
  
  -- Animate towards the target slot
  local duration = 0.2
  self.t:tween(duration, self, {
    x = target_item_part.x, 
    y = target_item_part.y,
    sx = ITEM_PART_WIDTH / self.w,
    sy = ITEM_PART_HEIGHT / self.h
  }, math.out_cubic, function()
    -- Animation complete - now assign the item
    unit.items[slot_index] = self.item
    target_item_part.hide_item_display = false
    
    -- Create particle effect at the target slot
    target_item_part:create_item_added_effect(self.item)
    
    -- Notify buy screen that an item was purchased
    if self.parent.on_item_purchased then
      self.parent:on_item_purchased(unit, slot_index, self.item)
    end
    
    self:die()
  end)
end

function ItemCard:complete_purchase(unit, slot_index)
  -- Immediate purchase without animation
  self:handle_purchase_transaction()
  unit.items[slot_index] = self.item

  -- Notify buy screen that an item was purchased
  if self.parent.on_item_purchased then
    self.parent:on_item_purchased(unit, slot_index, self.item)
  end

  self:die()
end

function ItemCard:update(dt)
  if self.dead then return end
  ItemCard.super.update(self, dt)

  -- Items are no longer draggable, just click to buy
  if input.m1.pressed and self.colliding_with_mouse then
    -- Check if the purchase is possible
    local can_buy = false
    local no_slot_message = 'no available item slots'

    if self.parent and self.parent:is(BuyScreen) and self.parent.weapons then
      -- Check if assigned weapon has space for items
      if self.assigned_weapon_index then
        local target_weapon = self.parent.weapons[self.assigned_weapon_index]
        if target_weapon then
          if not target_weapon.items then
            target_weapon.items = {}
          end
          -- Check if weapon has space (up to 6 items)
          local has_space = false
          for i = 1, 6 do
            if not target_weapon.items[i] then
              has_space = true
              break
            end
          end
          can_buy = has_space
          if not has_space then
            no_slot_message = 'weapon has max items'
          end
        end
      end
    else
      -- Check unit slots for other screens
      local unit, slot_index = Helper.Unit:find_available_inventory_slot(self.parent.units, self.item)
      can_buy = unit and slot_index  -- No cost check needed
    end

    if can_buy then
      -- Items are clicked to buy immediately
      self:buy_item()
      self:remove_set_bonus_tooltip()
        
    elseif not can_buy then
      self:remove_set_bonus_tooltip()
      Create_Info_Text(no_slot_message, self, 'error')
    end
  end

  -- Update set button positions with the ItemCard
  for i, set_button in ipairs(self.set_bonus_elements) do
    set_button.x = self.x
    set_button.y = self.y + 10 + (i-1)*20
    if set_button.shape then
      set_button.shape:move_to(set_button.x, set_button.y)
    end
  end

  --check if the set buttons are hovered
  for _, set_button in ipairs(self.set_bonus_elements) do
    if set_button.shape:is_colliding_with_point(camera:get_mouse_position()) then
      set_button.selected = true
    else
      set_button.selected = false
    end
  end

  self.set_button_hovered = false

  if not self.grabbed then
    for _, set_button in ipairs(self.set_bonus_elements) do
      if set_button.selected then
        self:show_set_bonus_tooltip(set_button.set_info)
        self.set_button_hovered = true
      end
    end
  end

  if not self.set_button_hovered then
    self:remove_set_bonus_tooltip()
  end

end

function ItemCard:show_set_bonus_tooltip(set_info)
  if self.dead then return end
  
  local text_lines = DrawUtils.build_set_bonus_tooltip_text(set_info)

  self:remove_set_bonus_tooltip()

  self.set_bonus_tooltip = InfoText{group = self.parent.ui_top or self.group, force_update = false}
  self.set_bonus_tooltip:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position()
  self.set_bonus_tooltip.x = pos.x
  self.set_bonus_tooltip.y = pos.y
end

function ItemCard:draw()
  if not self.item then return end

  -- Draw base card
  self:draw_base_card()

  -- Draw weapon assignment indicator on top
  if self.weapon_name_text and self.assigned_weapon then
    -- Draw a small banner at the top with weapon name
    local text_w = self.weapon_name_text.w
    local text_h = 10
    local banner_y = self.y - self.h/2 - 8

    graphics.push(self.x, banner_y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

    -- Background for weapon name
    graphics.rectangle(self.x, banner_y, text_w + 8, text_h, 4, 4, bg[0])

    -- Draw weapon name
    self.weapon_name_text:draw(self.x, banner_y)

    graphics.pop()
  end
end

function ItemCard:on_mouse_enter()
  ItemCard.super.on_mouse_enter(self)

  -- Highlight target slot if not grabbed
  if not self.grabbed and self.parent and self.parent:is(BuyScreen) then
    local weapon, slot_index, weapon_card, item_part = self.parent:get_item_target_slot(self.item)
    if item_part and item_part.highlight then
      item_part:highlight()
    end
  end
end

function ItemCard:on_mouse_exit()
  ItemCard.super.on_mouse_exit(self)
  self:remove_set_bonus_tooltip()

  -- Clear highlights
  if self.parent and self.parent.clear_all_highlights then
    self.parent:clear_all_highlights()
  end
end

function ItemCard:die()
  -- Clean up ItemCard-specific elements
  self:remove_set_bonus_tooltip()
  for _, set_button in ipairs(self.set_bonus_elements) do
    set_button.dead = true
  end
  
  -- Call parent die method
  ItemCard.super.die(self)
end

function ItemCard:remove_set_bonus_tooltip()
  self.set_button_hovered = false

  if self.set_bonus_tooltip then
    self.set_bonus_tooltip:deactivate()
    self.set_bonus_tooltip:die()
    self.set_bonus_tooltip.dead = true
    self.set_bonus_tooltip = nil
  end
end
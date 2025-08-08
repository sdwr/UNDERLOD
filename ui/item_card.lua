--find a way for clicks to buy into first empty slot
--need either a time check or distance check
--so that if you click and drag, you can drop halfway to cancel the buy
ItemCard = BaseCard:extend()
function ItemCard:init(args)
  -- Set up item-specific properties before calling super
  self.item = args.item
  args.image = find_item_image(self.item)
  args.colors = self.item.colors
  args.tier_color = self.item.tier_color or item_to_color(self.item)
  args.name = self.item.name
  
  -- Call parent constructor
  ItemCard.super.init(self, args)
  
  -- Item-specific properties
  self.cost = self.item.cost or 0
  self.stats = self.item.stats
  self.sets = self.item.sets
  self.origX = self.x
  self.origY = self.y

  -- Item card specific behavior
  self.timeGrabbed = 0
  self.buyTimer = 0.2
  self.grabbed = false
  self.grab_offset_x = 0
  self.grab_offset_y = 0
  
  -- Scaling behavior near character slots
  self.base_scale = 1
  self.current_scale = 1
  self.shrink_threshold_y = gh/2 - 25 + 80 -- Character card Y + some buffer

  -- Create cost text
  if self.cost > 0 then
    self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)
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
  -- Handle the gold transaction and bookkeeping
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  gold = gold - self.cost

  if self.cost > 10 then
    Stats_Current_Run_Over10Cost_Items_Purchased()
  end
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
  
  -- Check if item fits in this slot type
  local required_slot_index = ITEM_SLOTS[self.item.slot].index
  if slot_index ~= required_slot_index then
    Create_Info_Text('wrong slot type for ' .. self.item.name, self, 'error')
    return false
  end
  
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
  -- Use Helper.Unit to find available slot
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

  if input.m1.pressed and self.colliding_with_mouse and not self.grabbed then
    -- Check if the purchase is possible
    local unit, slot_index = Helper.Unit:find_available_inventory_slot(self.parent.units, self.item)
    
    if gold >= self.cost and unit and slot_index then
      -- SUCCESS: The player can afford it and has space.
      self.timeGrabbed = love.timer.getTime()
      self.grabbed = true
      
      -- Store the mouse offset from card center when grabbing
      local mouse_x, mouse_y = camera:get_mouse_position()
      self.grab_offset_x = mouse_x - self.x
      self.grab_offset_y = mouse_y - self.y
      
      self:remove_set_bonus_tooltip()
        
    elseif not unit or not slot_index then
      self:remove_set_bonus_tooltip()
      Create_Info_Text('no empty ' .. ITEM_SLOTS[self.item.slot].name .. ' slots - right click to sell', self, 'error')

    elseif gold < self.cost then
      self:remove_set_bonus_tooltip()
      Create_Info_Text('not enough gold', self, 'error')

    end
  end

  --determine when to purchase the item vs when to cancel the purchase
  --should be able to click to buy?
  --but also cancel by letting go if you drag it halfway
  --leave this for now, kinda confusing to track the mouse position or duration of click
  -- and have 2 different ways to cancel the purchase
  if self.grabbed and input.m1.released then
    self.grabbed = false
    
    -- Check if dropped over an item slot
    local mouse_x, mouse_y = camera:get_mouse_position()
    local item_part, unit = self:find_item_part_at_position(mouse_x, mouse_y)
    
    -- Reset scaling when released
    self.current_scale = 1.0
    self.sx = 1.0
    self.sy = 1.0
    
    if love.timer.getTime() - self.timeGrabbed < self.buyTimer then
      -- Quick click - use normal buy logic
      self:buy_item()
    elseif item_part and unit then
      -- Dropped over an item slot - try to buy to that specific slot
      self:buy_item_to_slot(item_part, unit)
    else
      -- Dropped elsewhere - return to original position
      self.x = self.origX
      self.y = self.origY
    end
  end

  if self.grabbed then
    local mouse_x, mouse_y = camera:get_mouse_position()
    self.x = mouse_x - self.grab_offset_x
    self.y = mouse_y - self.grab_offset_y
    
    -- Calculate scaling based on proximity to character slots
    self:update_scale_based_on_position()
    
    self:remove_set_bonus_tooltip()
  end

  -- Update set button positions to move with the ItemCard, accounting for scaling
  for i, set_button in ipairs(self.set_bonus_elements) do
    local base_x = self.x
    local base_y = self.y + 10 + (i-1)*20
    
    -- If grabbed and scaling, apply the same scaling offset as in draw method
    if self.grabbed and self.current_scale < 1.0 then
      local mouse_x, mouse_y = camera:get_mouse_position()
      local scale_offset_x = (mouse_x - self.x) * (1 - self.current_scale)
      local scale_offset_y = (mouse_y - self.y) * (1 - self.current_scale)
      base_x = base_x + scale_offset_x
      base_y = base_y + scale_offset_y
    end
    
    set_button.x = base_x
    set_button.y = base_y
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
  
  -- If grabbed and scaling, we need to handle the scaling towards mouse cursor
  if self.grabbed and self.current_scale < 1.0 then
    local mouse_x, mouse_y = camera:get_mouse_position()
    
    -- Calculate offset from card center to mouse for scaling origin
    local scale_offset_x = (mouse_x - self.x) * (1 - self.current_scale)
    local scale_offset_y = (mouse_y - self.y) * (1 - self.current_scale)
    
    -- Temporarily adjust position for scaling towards mouse
    local original_x, original_y = self.x, self.y
    self.x = self.x + scale_offset_x
    self.y = self.y + scale_offset_y
    
    -- Override the spring scaling with our custom scaling
    local original_sx, original_sy = self.sx, self.sy
    self.sx = self.current_scale * self.spring.x
    self.sy = self.current_scale * self.spring.x
    
    -- Draw base card
    self:draw_base_card()
    
    -- Restore original values
    self.x, self.y = original_x, original_y
    self.sx, self.sy = original_sx, original_sy
  else
    -- Normal drawing
    self:draw_base_card()
  end
end

function ItemCard:on_mouse_enter()
  ItemCard.super.on_mouse_enter(self)
end

function ItemCard:on_mouse_exit()
  ItemCard.super.on_mouse_exit(self)
  self:remove_set_bonus_tooltip()
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
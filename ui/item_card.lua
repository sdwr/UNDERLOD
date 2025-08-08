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

function ItemCard:buy_item()
  -- Use Helper.Unit to find available slot
  local unit, slot_index = Helper.Unit:find_available_inventory_slot(self.parent.units, self.item)
  
  if not unit or not slot_index then
    print("no available slot to buy item")
    return
  end
  
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  unit.items[slot_index] = self.item
  
  gold = gold - self.cost

  if self.cost > 10 then
    Stats_Current_Run_Over10Cost_Items_Purchased()
  end
  self.parent.shop_item_data[self.i] = nil
  self.parent:save_run()

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
    if love.timer.getTime() - self.timeGrabbed < self.buyTimer then
      --buy the item if the mouse is released within the buyTimer
      self:buy_item()
    else
      self.x = self.origX
      self.y = self.origY
    end
  end

  if self.grabbed then
    self.x, self.y = camera:get_mouse_position()
    self:remove_set_bonus_tooltip()
  end

  -- Update set button positions to move with the ItemCard's spring
  for i, set_button in ipairs(self.set_bonus_elements) do
    -- Position setbuttons relative to ItemCard center, accounting for spring scaling
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

  self.set_bonus_tooltip = InfoText{group = self.group, force_update = false}
  self.set_bonus_tooltip:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position()
  self.set_bonus_tooltip.x = pos.x
  self.set_bonus_tooltip.y = pos.y
end

function ItemCard:draw()
  if not self.item then return end
  
  -- Draw base card (background, border, image, text, etc.)
  self:draw_base_card()
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
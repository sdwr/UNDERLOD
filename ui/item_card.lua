--find a way for clicks to buy into first empty slot
--need either a time check or distance check
--so that if you click and drag, you can drop halfway to cancel the buy
ItemCard = Object:extend()
ItemCard:implement(GameObject)
function ItemCard:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.origX = self.x
  self.origY = self.y
  self.interact_with_mouse = true

  self.cost = self.item.cost or 0
  self.image = find_item_image(self.item)
  self.colors = self.item.colors
  -- Use V2 item tier_color if available, otherwise fall back to item_to_color
  self.tier_color = self.item.tier_color or item_to_color(self.item)
  self.stats = self.item.stats
  self.sets = self.item.sets
  self.name = self.item.name

  self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)

  self.timeGrabbed = 0
  self.buyTimer = 0.2

  self.set_bonus_elements = {}
  if self.sets then
    self:create_set_bonus_elements()
  end

  self.set_bonus_hovered = false

  -- Create name and stats text like FloorItem
  self:create_stats_text()
  
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

function ItemCard:wrap_text(text, max_width, font)
  local lines = {}
  local current_line = ''
  -- Prevent errors if text is nil
  if not text then return {} end
  
  for word in text:gmatch("([^ ]+)") do
      local test_line = current_line == '' and word or current_line .. ' ' .. word
      
      if font:get_text_width(test_line) > max_width then
          if current_line == '' then
              -- If single word is too long, just use it as is
              table.insert(lines, word)
          else
              -- Add current line and start new one with current word
              table.insert(lines, current_line)
              current_line = word
          end
      else
          current_line = test_line
      end
  end
  
  -- Add remaining text
  if current_line ~= '' then
      table.insert(lines, current_line)
  end
  
  return lines
end

function ItemCard:creation_effect()
  if self.cost <= 5 then
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
  self.parent:save_run()

  self.parent.shop_item_data[self.i] = nil
  self.parent.shop_text:set_text{{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}
  self:die()
end

function ItemCard:update(dt)
  self:update_game_object(dt)

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
      Create_Info_Text('no empty ' .. ITEM_SLOTS[self.item.slot].name .. ' slots - right click items in character menu to sell', self)

    elseif gold < self.cost then
      self:remove_set_bonus_tooltip()
      Create_Info_Text('not enough gold', self)

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
  end

  -- Update set button positions to move with the ItemCard's spring
  for i, set_button in ipairs(self.set_bonus_elements) do
    -- Position setbuttons relative to ItemCard center, accounting for spring scaling
    set_button.x = self.x
    set_button.y = self.y + 10 + (i-1)*20
  end

  --check if the set buttons are hovered
  --have to do manually because item card eats mouse events
  for _, set_button in ipairs(self.set_bonus_elements) do
    if self.shape:is_colliding_with_point(camera:get_mouse_position()) then
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
        self.set_bonus_hovered = true
      end
    end
  end

  if not self.set_bonus_hovered then
    self:remove_set_bonus_tooltip()
  end

  self.shape:move_to(self.x, self.y)
end

function ItemCard:show_set_bonus_tooltip(set_info)
  local text_lines = DrawUtils.build_set_bonus_tooltip_text(set_info)

  self:remove_set_bonus_tooltip()

  self.set_bonus_tooltip = InfoText{group = self.group, force_update = false}
  self.set_bonus_tooltip:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.set_bonus_tooltip.x = gw/2
  self.set_bonus_tooltip.y = gh/2
end

function ItemCard:draw()
  if self.item then
    local width = self.w or 60
    local height = self.h or 80
    
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

    -- Main background
    graphics.rectangle(self.x, self.y, width, height, 6, 6, bg[5])
    
    -- Set colors (like FloorItem)
    if self.colors then
      local num_colors = #self.colors
      local top_half_height = height / 2 -- Only use top half
      local color_h = top_half_height / num_colors
      for i, color_name in ipairs(self.colors) do
        local color = _G[color_name] or _G['brown']
        color = color[0]:clone()
        color.a = 0.6
        local y = (self.y - height/2) + ((i-1) * color_h) + (color_h/2)
        graphics.rectangle(self.x, y, width, color_h, 6, 6, color)
      end
    end
    
    -- Draw the locked color under the border
    if locked_state then
      local color = grey[0]:clone()
      color.a = 0.8
      graphics.rectangle(self.x, self.y, width, height, 6, 6, color)
    end
    
    -- Border
    graphics.rectangle(self.x, self.y, width, height, 6, 6, self.tier_color, 2)

    -- Cost text at top
    if self.cost_text then
      self.cost_text:draw(self.x + width/2 - 5, self.y - height/2 + 10)
    end
    
    -- Image in center
    if self.image then
      self.image:draw(self.x, self.y - 20, 0, 0.8, 0.8)
    end
    
    -- Stats text (lower part)
    if self.bottom_text then
      local top_section_bottom = self.y + 7 -- The center of the card (boundary between top and bottom)
      local bottom_text_y = top_section_bottom + self.bottom_text.h/2-- Position just below the top section with small padding
      self.bottom_text:draw(self.x, bottom_text_y)
    end

    graphics.pop()
  end
end

function ItemCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)

  
end

function ItemCard:on_mouse_exit()
  self.selected = false
  self:remove_set_bonus_tooltip()
end

function ItemCard:die()
  self.dead = true
  self.cost_text = nil
  self.name_text = nil
  self.bottom_text = nil
  -- Ensure the tooltip is removed when the card dies
  self:remove_set_bonus_tooltip()
end

function ItemCard:remove_set_bonus_tooltip()
  self.set_bonus_hovered = false

  if self.set_bonus_tooltip then
    self.set_bonus_tooltip:die()
    self.set_bonus_tooltip = nil
  end
end
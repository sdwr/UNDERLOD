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
    card:die()
  end
  for i, text in ipairs(ALL_CARD_TEXTS) do
    text.dead = true
  end
end

CharacterCard = Object:extend()
CharacterCard:implement(GameObject)
function CharacterCard:init(args)
  self:init_game_object(args)
  self.background_color = args.background_color or bg[0]
  self.character = args.unit.character or 'none'
  self.character_color = character_colors[self.character]
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


  --otherwise have duplicate text somehow?? 
  Refresh_All_Cards_Text()
  
  if self.spawn_effect then SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.character_color} end
end

function CharacterCard:createItemParts()
  local item_x = self.x + CHARACTER_CARD_ITEM_X
  local item_y = self.y + CHARACTER_CARD_ITEM_Y

  --draw in 2 rows

  for i = 1, self.unit.numItems do

    table.insert(self.items, ItemPart{group = main.current.main,
       x = item_x + (CHARACTER_CARD_ITEM_X_SPACING*((i-1) % 3)), 
       y = item_y + (i > 3 and 25 or 0),
       i = i, parent = self})
  end
end

function CharacterCard:initText()
  self.name_text = Text({{text = '[' .. self.character_color_string .. '[3]]' .. self.character, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self:createButtons()
  
  self.proc_text = nil
end

function CharacterCard:createButtons()
  -- Create "Last Round" button
  self.last_round_button = Button{
    group = main.current.ui,
    x = self.x - 25,
    y = self.y - self.h/2 + 30,
    w = 40,
    h = 20,
    bg_color = 'bg',
    fg_color = 'bg10',
    button_text = 'Last Round',
    action = function() end -- No action on click, just hover
  }
  
  -- Create "Unit Stats" button
  self.unit_stats_button = Button{
    group = main.current.ui,
    x = self.x + 25,
    y = self.y - self.h/2 + 30,
    w = 40,
    h = 20,
    bg_color = 'bg',
    fg_color = 'bg10',
    button_text = 'Unit Stats',
    action = function() end -- No action on click, just hover
  }
  
  -- Store references for hover detection
  self.last_round_button.parent = self
  self.unit_stats_button.parent = self
end

function CharacterCard:show_round_stats_popup()
  if self.unit.last_round_dps and self.unit.last_round_damage then
    local text_lines = {}
    
    -- Format damage and DPS
    local damage_text = math.floor(self.unit.last_round_damage)
    local dps_text = string.format("%.1f", self.unit.last_round_dps)
    
    -- Add damage line
    table.insert(text_lines, { 
      text = '[red]DMG: [red]' .. damage_text, 
      font = pixul_font, 
      alignment = 'center' 
    })
    
    -- Add DPS line
    table.insert(text_lines, { 
      text = '[green]DPS: [green]' .. dps_text, 
      font = pixul_font, 
      alignment = 'center' 
    })
    
    -- Add kills if available
    if self.unit.last_round_kills and self.unit.last_round_kills > 0 then
      table.insert(text_lines, { 
        text = '[yellow]Kills: [yellow]' .. self.unit.last_round_kills, 
        font = pixul_font, 
        alignment = 'center' 
      })
    end
    
    self.popup = InfoText{group = main.current.ui, force_update = false}
    self.popup:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
    self.popup.x = self.x
    self.popup.y = self.y - self.h/2 + 60
  end
end

function CharacterCard:show_unit_stats_popup()
  local item_stats = get_unit_stats(self.unit)
  local text_lines = {}
  
  for k, v in pairs(item_stats) do
    table.insert(text_lines, { 
      text = '[yellow[0]]+' .. (v * 100) .. '% ' .. k:capitalize(), 
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
      text = '[fg]No item stats', 
      font = pixul_font, 
      alignment = 'center' 
    })
  end
  
  self.popup = InfoText{group = main.current.ui, force_update = false}
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

function CharacterCard:refreshText()
  -- Remove old buttons if they exist
  if self.last_round_button then
    self.last_round_button.dead = true
  end
  if self.unit_stats_button then
    self.unit_stats_button.dead = true
  end
  
  self:createButtons()
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
  
  -- Check button hover states and show/hide popups
  if self.last_round_button and self.last_round_button.selected and not self.last_round_hovered then
    self.last_round_hovered = true
    self:show_round_stats_popup()
  elseif self.last_round_button and not self.last_round_button.selected and self.last_round_hovered then
    self.last_round_hovered = false
    self:hide_popup()
  end
  
  if self.unit_stats_button and self.unit_stats_button.selected and not self.unit_stats_hovered then
    self.unit_stats_hovered = true
    self:show_unit_stats_popup()
  elseif self.unit_stats_button and not self.unit_stats_button.selected and self.unit_stats_hovered then
    self.unit_stats_hovered = false
    self:hide_popup()
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
  
  -- Clean up buttons
  if self.last_round_button then
    self.last_round_button.dead = true
  end
  if self.unit_stats_button then
    self.unit_stats_button.dead = true
  end
  
  -- Clean up popup
  self:hide_popup()
  
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
    self.looseItem = LooseItem{group = main.current.ui, item = self:getItem(), parent = self}
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
      buyScreen:save_run()
    end
  end

  --differentiate between moving the item to another slot, and selling the item w m2
  if input.m2.released and not self.itemGrabbed and self:isActiveInvSlot() and self:hasItem() then
    self:sellItem()
    buyScreen:save_run()
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
    local tier_color = item_to_color(item)
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
    
    if self.colliding_with_mouse and buyScreen and not buyScreen.loose_inventory_item then
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
    group = main.current.ui,
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
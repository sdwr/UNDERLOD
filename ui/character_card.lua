
--unit data in buy screen
function Create_Unit_Data(character)
  local data = {}
  data.character = character
  data.items = {nil, nil, nil, nil, nil, nil}
  data.numItems = 6
  data.consumedItems = {}
  return data
end

function Consume_Item(unit, item)
  --make a copy of the item so we can store it in the unit
  print('consuuming item in shop')
  print_object(item)
  local itemCopy = Create_Item(item.name)
  print('item copy')
  print_object(itemCopy)
  if not unit.consumedItems then
    unit.consumedItems = {}
  end
  for i, existingItem in ipairs(unit.consumedItems) do
    if existingItem and existingItem.name == item.name then
      return false
    end
  end
  table.insert(unit.consumedItems, itemCopy)
end

function Clear_Consumed_Items(units)
  if not units then return end
  for i, unit in ipairs(units) do
    unit.consumedItems = {}
  end
end


--character cards in UI
Active_Inventory_Slot = nil
Character_Cards = {}

function Refresh_All_Cards_Text()
  for i, card in ipairs(Character_Cards) do
    card:refreshText()
    card:refreshProcIcons()
  end
end

function Kill_All_Cards()
  if not Character_Cards then return end
  for i, card in ipairs(Character_Cards) do
    card:die()
  end
end

CharacterCard = Object:extend()
CharacterCard:implement(GameObject)
function CharacterCard:init(args)
  self:init_game_object(args)
  self.background_color = args.background_color or bg[0]
  self.character = args.unit.character or 'none'
  self.character_color = character_colors[self.character]
  
  self.w = CHARACTER_CARD_WIDTH
  self.h = CHARACTER_CARD_HEIGHT
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  
  self.interact_with_mouse = true

  self.procIcons = {}

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
  self.name_text = Text({{text = '[yellow[3]]' .. self.character, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.stat_text = build_character_text(self.unit)
  self.stat_text.x = self.x
  self.stat_text.y = self.y - self.h/2 + 25 + self.stat_text.h/2
  
  self.proc_text = nil
end

function CharacterCard:addProcIcon(item)
  local proc_x = self.x + CHARACTER_CARD_PROC_X
  local proc_y = self.y + CHARACTER_CARD_PROC_Y

  local x = proc_x + (#self.procIcons * CHARACTER_CARD_PROC_X_SPACING)

  local procIcon = ProcIcon{
    group = main.current.main, 
    x = x, 
    y = proc_y,
    item = item,
  }
  table.insert(self.procIcons, procIcon)
end

function CharacterCard:refreshProcIcons()
  for i, icon in ipairs(self.procIcons) do
    icon:die()
  end
  self.procIcons = {}
  if not self.unit.consumedItems then return end
  for i, item in ipairs(self.unit.consumedItems) do
    print_object(item)
    self:addProcIcon(item)
  end
end

function CharacterCard:refreshText()
  self.stat_text.dead = true
  self.stat_text = build_character_text(self.unit)
  self.stat_text.x = self.x
  self.stat_text.y = self.y - self.h/2 + 35 + self.stat_text.h/2
end

function CharacterCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  --draw background
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.background_color)
  --draw text
  self.name_text:draw(self.x, self.y - (self.h/2) + 10)
  self.stat_text:draw()

  graphics.pop()
end
  
function CharacterCard:update(dt)
  self:update_game_object(dt)
end

function CharacterCard:die()
  self.name_text.dead = true
  self.stat_text.dead = true
  self.dead = true
end

ProcIcon = Object:extend()
ProcIcon:implement(GameObject)
function ProcIcon:init(args)
  self:init_game_object(args)
  self.shape = Circle(self.x, self.y, 10)
  self.interact_with_mouse = true
  self.text = build_proc_text(self.item)
  self.color = get_item_color(self.item)
  self.info_text = nil
end

function ProcIcon:update(dt)
  self:update_game_object(dt)
  if self.colliding_with_mouse then
    if not self.info_text then
      self:create_info_text()
    end
  else
    if self.info_text then
      self.info_text:deactivate()
      self.info_text.dead = true
      self.info_text = nil
    end
  end
end

function ProcIcon:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  graphics.circle(self.x, self.y, 5, self.color)
  graphics.pop()
end

function ProcIcon:create_info_text()
  self.info_text = InfoText{group = main.current.ui, force_update = true}
  self.info_text:activate(self.text, nil, nil, nil, nil, 16, 4, nil, 2)
  --set the position of the info text
  self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
end

function ProcIcon:die()
  self.dead = true
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
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
        Consume_Item(self.parent.unit, item)
        Refresh_All_Cards_Text()
      else
        --play sell sound
        spawn_mark1:play{pitch = random:float(0.8, 1.2), volume = 1}
        local sell_value = math.ceil(item.cost / 3)
        main.current:gain_gold(sell_value)
      end
      item:sell()
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
    --remove item text
    self:remove_item_text()
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
      if not self.info_text then
        self:create_info_text()
      end
    else
      self:remove_item_text()
    end
    graphics.pop()
  end
end

--item part
function ItemPart:create_info_text()
  self:remove_item_text()
  if self:hasItem() then
    local item = self:getItem()
    self.info_text = InfoText{group = main.current.ui, force_update = true}
    self.info_text:activate(build_item_text(item), nil, nil, nil, nil, 16, 4, nil, 2)
    --set the position of the info text
    self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
  end
end

function ItemPart:remove_item_text()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end

function ItemPart:die()
  self.dead = true
  Refresh_All_Cards_Text()
  if Active_Inventory_Slot == self then
    Active_Inventory_Slot = nil
  end
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end

function ItemPart:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.selected = true
  self.spring:pull(0.2, 200, 10)
end

--BUG: calls as soon as entered sometimes
function ItemPart:on_mouse_exit()
  self.selected = false
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
  end
  self.info_text = nil
end



function ItemPart:highlight()
self.highlighted = true
self.spring:pull(0.2, 200, 10)
end


function ItemPart:unhighlight()
self.highlighted = false
self.spring:pull(0.05, 200, 10)
end
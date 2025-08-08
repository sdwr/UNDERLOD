PerksPanel = Object:extend()
PerksPanel:implement(GameObject)

function PerksPanel:init(args)
  self:init_game_object(args)
  
  -- Panel properties
  self.x = args.x or gw - 100
  self.y = args.y or 20
  self.width = args.width or 80
  self.slot_size = 32
  self.slot_spacing = 8
  self.perks = args.perks or {}
  
  -- Create title text
  self.title = Text2{
    group = self.group,
    x = self.x + self.width/2,
    y = self.y,
    lines = {{text = 'perks', font = pixul_font, alignment = 'center'}},
    fg_color = 'white'
  }
  
  -- Create perk slots
  self.slots = {}
  for i = 1, 5 do
    local slot_y = self.y + 25 + (i-1) * (self.slot_size + self.slot_spacing)
    self.slots[i] = PerkSlot{
      group = self.group,
      x = self.x + 15 + (self.width - self.slot_size) / 2,
      y = slot_y,
      w = self.slot_size,
      h = self.slot_size,
      parent = self
    }
    if self.perks[i] then
      self.slots[i]:set_perk(self.perks[i])
    end
  end
end

function PerksPanel:update(dt)
  self:update_game_object(dt)
end

function PerksPanel:draw()
  if self.title then
    self.title:draw()
  end
end

function PerksPanel:set_perks(perks)
  self.perks = perks or {}
  
  -- Update slots with perks
  for i, slot in ipairs(self.slots) do
    slot:set_perk(self.perks[i])
  end
end

function PerksPanel:add_perk(perk)
  -- Find first empty slot
  for i, slot in ipairs(self.slots) do
    if not slot.perk then
      slot:set_perk(perk)
      table.insert(self.perks, perk)
      return true
    end
  end
  return false -- No empty slots
end

function PerksPanel:remove_perk(index)
  if self.perks[index] then
    table.remove(self.perks, index)
    -- Rebuild slots
    for i, slot in ipairs(self.slots) do
      slot:set_perk(self.perks[i])
    end
    return true
  end
  return false
end

function PerksPanel:die()
  for _, slot in ipairs(self.slots) do
    slot:die()
  end
  if self.title then
    self.title.dead = true
  end
  self.dead = true
end

-- PerkSlot object
PerkSlot = Object:extend()
PerkSlot:implement(GameObject)

function PerkSlot:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.perk = nil
  self.parent = args.parent
  self.spring:pull(0.2, 200, 10)
end

function PerkSlot:try_level_perk()
  if not self.perk then return end
  if not Can_Perk_Level_Up(self.perk) then return end
  
  local cost = Perk_Level_Up_Cost(self.perk)
  if gold < cost then 
    Create_Info_Text('not enough gold', self, 'error')
    return 
  end
  
  gold = gold - cost
  ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.perk.level = self.perk.level + 1

  main.current:save_run()
end

function PerkSlot:update(dt)
  self:update_game_object(dt)
  self.shape:move_to(self.x, self.y)
  self:update_cost()

  if input.m1.pressed and self.colliding_with_mouse and self.perk then
    self:try_level_perk()
  end
end

function PerkSlot:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    
    -- Draw slot background (empty slot)
    graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, bg[0])
    
    -- Draw slot border
    graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, 
                      self.perk and fg[0] or bg[5], 1)
    
    -- Draw perk if it exists
    if self.perk then
      -- Draw perk icon similar to item cards
      local image = self:find_perk_image(self.perk)
      if image then
        image:draw(self.x, self.y, 0, 0.6, 0.6)
      end
      
      -- Draw level ticks at the bottom
      self:draw_level_ticks()

      if self.cost_text then
        self.cost_text:draw(self.x + self.w/2 - 5, self.y - self.h/2 + 3)
      end
    end
    
    
  graphics.pop()
end

function PerkSlot:update_cost()
  if not self.perk then return end
  if not Can_Perk_Level_Up(self.perk) then 
    self.cost = nil
    self.cost_text = nil
    return 
  end

  self.cost = Perk_Level_Up_Cost(self.perk)
  self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)

end

function PerkSlot:draw_level_ticks()
  if not self.perk then return end
  
  local max_level = Get_Perk_Max_Level(self.perk)
  local current_level = self.perk.level or 1
  local tick_width = 7
  local tick_height = 5
  local tick_spacing = 3
  
  -- Calculate the total width of all ticks and the spaces between them
  local total_width = (max_level * tick_width) + ((max_level - 1) * tick_spacing)
  
  -- Calculate the starting x-position for the *block* of ticks, so it's centered on self.x
  local block_start_x = self.x - total_width / 2
  
  local tick_y = self.y + (self.h/2) -- Position ticks vertically at the bottom of the slot
  
  -- Draw a single background line behind all the ticks
  graphics.line(block_start_x, tick_y, block_start_x + total_width, tick_y, bg[1], 1)
  
  for i = 1, max_level do
      -- Calculate the center x-position for each individual tick
      local tick_x = block_start_x + (i - 1) * (tick_width + tick_spacing) + (tick_width / 2)
      local is_filled = i <= current_level
      
      -- Draw tick background (empty)
      graphics.rectangle(tick_x, tick_y, tick_width, tick_height, 1, 1, bg[5])
      
      -- Draw filled tick if this level is achieved
      if is_filled then
          graphics.rectangle(tick_x, tick_y, tick_width, tick_height, 1, 1, fg[0])
      end
  end
end


function PerkSlot:set_perk(perk)
  self.perk = perk
end

function PerkSlot:on_mouse_enter()
  self.selected = true
  
  if self.perk then
    ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    self:show_perk_tooltip()
  end
end

function PerkSlot:on_mouse_exit()
  self.selected = false
  self.spring:pull(0.1, 200, 10)
  
  if self.perk then
    self:hide_perk_tooltip()
  end
end

function PerkSlot:show_perk_tooltip()
  if not self.perk then return end
  
  -- Create infotext popup with wrapped description
  local name_line = {text = '[fg]' .. self.perk.name, font = pixul_font, alignment = 'center'}
  local wrapped_lines = self:wrap_text(self.perk.description, 200, pixul_font)
  local text_lines = {name_line}
  for _, line in ipairs(wrapped_lines) do
    table.insert(text_lines, {text = '[fg]' .. line, font = pixul_font, alignment = 'center'})
  end

  self.info_text = InfoText{group = main.current.world_ui or main.current.ui}
  self.info_text:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position()
  self.info_text.x, self.info_text.y = pos.x, pos.y
  global_info_text = self.info_text.cost_text_object
end

function PerkSlot:hide_perk_tooltip()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end

-- Helper function to wrap text to a certain pixel width
function PerkSlot:wrap_text(text, max_width, font)
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

-- Helper function to find perk image (similar to find_item_image)
function PerkSlot:find_perk_image(perk)
  -- For now, use a default image since perk images aren't defined yet
  -- This can be expanded later when perk images are added
  return item_images[perk.icon] or item_images['default']
end

function PerkSlot:die()
  self:hide_perk_tooltip()
  self.dead = true
end 
OwnedWeaponCard = Object:extend()
OwnedWeaponCard.__class_name = 'OwnedWeaponCard'
OwnedWeaponCard:implement(GameObject)

function OwnedWeaponCard:init(args)
  self:init_game_object(args)
  
  self.weapon_name = args.weapon_name
  self.level = args.level or 1
  self.xp = args.xp or 0  -- Support old 'count' param for compatibility
  self.index = args.index or 1
  self.weapon = args.weapon or {}
  self.item_parts = {}
  
  -- Get weapon definition
  self.weapon_def = Get_Weapon_Definition(self.weapon_name)
  
  -- Card dimensions
  self.w = 50
  self.h = 20

  self.ITEM_SLOT_WIDTH = 15
  self.ITEM_SLOT_HEIGHT = 15
  self.ITEM_SLOT_SPACING = 5
  
  -- Position based on index
  self.x = args.x
  self.y = args.y
  
  -- Create shape for interaction
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  
  -- Title text showing level and name
  local level_text = 'Lv.' .. self.level .. ' '
  local title_string = level_text .. self.weapon_def.name
  self.title_text = Text({{text = '[yellow]' .. title_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
  
  -- Calculate XP needed for next level
  self:update_xp_requirements()
  
  -- Create ItemPart instances for weapon items
  self:create_item_parts()
end

function OwnedWeaponCard:update_xp_requirements()
  -- XP needed: Level 1->2 needs 2 xp, Level 2->3 needs 3 xp
  if self.level == 1 then
    self.xp_needed = 2
  elseif self.level == 2 then
    self.xp_needed = 3
  else
    self.xp_needed = 0  -- Max level
  end
end

-- Removed add_xp and level_up functions - weapon leveling is handled in BuyScreen

function OwnedWeaponCard:get_xp_progress()
  if self.level >= WEAPON_MAX_LEVEL then return 0 end
  if self.xp_needed == 0 then return 0 end
  return self.xp / self.xp_needed
end

function OwnedWeaponCard:create_item_parts()
  -- Clean up existing item parts
  for _, part in ipairs(self.item_parts) do
    part:die()
  end
  self.item_parts = {}
  
  -- Create 3 item parts for weapon slots
  for i = 1, 3 do
    local y_offset = (i-1) * (self.ITEM_SLOT_HEIGHT + self.ITEM_SLOT_SPACING)
    local item_part = ItemPart{
      group = self.group,
      x = self.x,
      y = self.y + self.h/2 + self.ITEM_SLOT_HEIGHT/2 + self.ITEM_SLOT_SPACING + y_offset,
      i = i,
      parent = self,
      w = self.ITEM_SLOT_WIDTH,
      h = self.ITEM_SLOT_HEIGHT
    }
    table.insert(self.item_parts, item_part)
  end
end

function OwnedWeaponCard:update(dt)
  self:update_game_object(dt)
  
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
  
  -- Update values from weapon if they've changed
  if self.weapon then
    if self.weapon.level ~= self.level or self.weapon.xp ~= self.xp then
      self.level = self.weapon.level
      self.xp = self.weapon.xp or 0
      self:update_xp_requirements()
      
      -- Update title text
      if self.title_text then
        self.title_text.dead = true
      end
      local level_text = 'Lv.' .. self.level .. ' '
      local title_string = level_text .. self.weapon_def.name
      self.title_text = Text({{text = '[yellow]' .. title_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
    end
  end
end

function OwnedWeaponCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end

function OwnedWeaponCard:on_mouse_exit()
  self.selected = false
end

function OwnedWeaponCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x * self.sx, self.spring.x * self.sy)
  
  -- Background based on weapon level
  local bg_color = bg[2]
  
  -- Draw card background
  graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg_color)
  
  -- Draw XP progress bar at top of card
  if self.level < WEAPON_MAX_LEVEL then
    local xp_progress = self:get_xp_progress()
    if xp_progress > 0 then
      local bar_height = 3
      local bar_width = self.w * xp_progress
      local xp_color = blue[0]:clone()
      xp_color.a = 0.5
      graphics.rectangle(self.x - self.w/2 + bar_width/2, self.y, bar_width, self.h, 0, 0, xp_color)
    end
  end
  
  -- Draw border
  local border_color = self.selected and yellow[0] or fg[0]
  graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, nil, 2, border_color)
  
  -- Draw texts
  if self.title_text then
    self.title_text:draw(self.x, self.y - self.h/2 + 10)
  end
  
  graphics.pop()
end

function OwnedWeaponCard:die()
  self.dead = true
  
  if self.title_text then
    self.title_text.dead = true
    self.title_text = nil
  end
  
  -- Clean up item parts
  for _, part in ipairs(self.item_parts) do
    part:die()
  end
  self.item_parts = {}
end
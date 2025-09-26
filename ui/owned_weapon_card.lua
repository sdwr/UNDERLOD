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
  self.is_empty = args.is_empty
  self.item_parts = {}

  -- Get weapon definition if not empty
  if not self.is_empty and self.weapon_name then
    self.weapon_def = Get_Weapon_Definition(self.weapon_name)
  end

  -- Card dimensions
  self.w = 50
  self.h = 50  -- Make it square for icon

  self.ITEM_SLOT_WIDTH = 20
  self.ITEM_SLOT_HEIGHT = 20
  self.ITEM_SLOT_SPACING = 5

  -- Position based on index
  self.x = args.x
  self.y = args.y

  -- Create shape for interaction
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true

  -- Get weapon icon image if available (same as WeaponCard)
  if not self.is_empty and self.weapon_def then
    if self.weapon_def.icon and item_images[self.weapon_def.icon] then
      self.image = item_images[self.weapon_def.icon]
    elseif item_images['default'] then
      self.image = item_images['default']
    end
  end

  -- Calculate XP needed for next level
  if not self.is_empty then
    self:update_xp_requirements()
    -- Create ItemPart instances for weapon items
    self:create_item_parts()
  end
end

function OwnedWeaponCard:update_xp_requirements()
  -- Use global XP requirements table
  local next_level = self.level + 1
  if next_level <= WEAPON_MAX_LEVEL then
    self.xp_needed = WEAPON_XP_REQUIREMENTS[next_level]
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

  -- Only show item slots if weapon has items
  if not self.weapon or not self.weapon.items then
    return
  end

  -- Count actual items
  local num_items = 0
  for i = 1, 6 do
    if self.weapon.items[i] then
      num_items = num_items + 1
    end
  end

  if num_items == 0 then
    return
  end

  -- Create item parts only for existing items
  -- Position slots in a 3x2 grid below the card
  local slots_per_row = 3
  local slot_index = 0

  for i = 1, 6 do
    if self.weapon.items[i] then
      local row = math.floor(slot_index / slots_per_row)
      local col = slot_index % slots_per_row

      local x_offset = (col - 1) * (self.ITEM_SLOT_WIDTH + self.ITEM_SLOT_SPACING)
      local y_offset = row * (self.ITEM_SLOT_HEIGHT + self.ITEM_SLOT_SPACING)

      -- Center the grid horizontally
      local grid_width = (slots_per_row - 1) * (self.ITEM_SLOT_WIDTH + self.ITEM_SLOT_SPACING)
      local start_x = self.x - grid_width / 2

      local item_part = ItemPart{
        group = self.group,
        x = start_x + x_offset,
        y = self.y + self.h/2 + self.ITEM_SLOT_HEIGHT/2 + 5 + y_offset,
        i = i,
        parent = self,
        w = self.ITEM_SLOT_WIDTH,
        h = self.ITEM_SLOT_HEIGHT,
        item = self.weapon.items[i]  -- Pass the actual item
      }
      table.insert(self.item_parts, item_part)
      slot_index = slot_index + 1
    end
  end
end

function OwnedWeaponCard:update(dt)
  self:update_game_object(dt)

  if self.shape then
    self.shape:move_to(self.x, self.y)
  end

  -- Right-click to sell weapon
  if input.m2.pressed and self.colliding_with_mouse and not self.is_empty then
    -- Check if weapon has items
    local has_items = false
    if self.weapon and self.weapon.items then
      for i = 1, 3 do
        if self.weapon.items[i] then
          has_items = true
          break
        end
      end
    end

    if has_items then
      Create_Info_Text('remove items first', self, 'error')
    else
      -- Weapons sell for 0 gold
      local sell_price = 0

      -- Set weapon to nil in BuyScreen's weapons array (keeps indices stable)
      local buy_screen = main.current
      if buy_screen and buy_screen:is(BuyScreen) and buy_screen.weapons then
        for i, weapon in pairs(buy_screen.weapons) do
          if weapon == self.weapon then
            buy_screen.weapons[i] = nil  -- Set to nil instead of removing
            break
          end
        end
      end

      -- Add gold (0 for weapons)
      gold = gold + sell_price

      -- Play sound but don't show +0 gold text
      if gold1 then
        gold1:play{pitch = random:float(0.95, 1.05), volume = 0.3}
      end

      -- Save and refresh the display
      if buy_screen and buy_screen:is(BuyScreen) then
        buy_screen:save_run()
        -- Refresh the owned weapons display
        if buy_screen.owned_weapons_display then
          buy_screen.owned_weapons_display:refresh_cards()
        end
      end
    end
  end

  -- Update values from weapon if they've changed
  if self.weapon and not self.is_empty then
    if self.weapon.level ~= self.level or self.weapon.xp ~= self.xp then
      local old_level = self.level
      self.level = self.weapon.level
      self.xp = self.weapon.xp or 0
      self:update_xp_requirements()

      -- Recreate item parts if level changed
      if old_level ~= self.level then
        self:create_item_parts()
      end
    end
  end

  -- Update item parts
  for _, part in ipairs(self.item_parts) do
    part:update(dt)
  end
end

function OwnedWeaponCard:on_mouse_enter()
  if self.is_empty then return end

  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)

  -- Create hover tooltip with weapon name and level using global function
  if self.weapon_def then
    local level_text = 'Lv.' .. self.level .. ' '
    local title_string = level_text .. self.weapon_def.name
    Create_Info_Text(title_string, self, 'weapon_hover', true)
  end
end

function OwnedWeaponCard:on_mouse_exit()
  self.selected = false
  -- Global tooltip is handled by Create_Info_Text and clears itself
end

function OwnedWeaponCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x * self.sx, self.spring.x * self.sy)

  if self.is_empty then
    -- Draw empty slot
    local bg_color = bg[5]

    -- Draw yellow glow when highlighted as target
    if self.highlight_target then
      local glow_color = yellow[0]:clone()
      glow_color.a = 0.4
      graphics.rectangle(self.x, self.y, self.w+6, self.h+6, 3, 3, glow_color)
      graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg_color)
      graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, nil, 1, yellow[0])
    else
      graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg_color)
      graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, nil, 1, fg[10])
    end
  else
    -- Background and border based on weapon level
    local bg_color = bg[2]
    local border_width = 2
    local border_color = fg[0]  -- Default grey

    -- Level-based visual enhancements
    if self.level == 1 then
      bg_color = bg[2]
      border_color = fg[0]  -- Grey for level 1
      border_width = 2
    elseif self.level == 2 then
      bg_color = bg[0]
      border_color = green[0]  -- Green for level 2
      border_width = 2
    elseif self.level >= WEAPON_MAX_LEVEL then
      bg_color = bg[-2]
      border_color = orange[0]  -- Orange for level 3 (max)
      border_width = 3
    end

    -- Draw card background
    graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg_color)

    -- Draw XP progress bar at bottom of card
    if self.level < WEAPON_MAX_LEVEL then
      local xp_progress = self:get_xp_progress()
      if xp_progress > 0 then
        local bar_height = 6
        local bar_width = self.w * xp_progress
        local xp_color = blue[0]:clone()
        xp_color.a = 0.7
        graphics.rectangle(self.x - self.w/2 + bar_width/2, self.y + self.h/2 - bar_height/2, bar_width, bar_height, 0, 0, xp_color)
      end
    end

    -- Draw weapon icon (same as BaseCard does)
    if self.image then
      self.image:draw(self.x, self.y, 0, 0.5, 0.5)
    end

    -- Draw level indicator in corner with enhanced styling
    if self.level > 0 then
      local level_color = yellow[0]
      local level_text = 'Lv. ' .. tostring(self.level)
      -- Simple level indicator without background box
      graphics.print(level_text, pixul_font, self.x - 13, self.y - self.h/2 + 2, 0, 1, 1, nil, nil, level_color)
    end

    -- Override with yellow glow when highlighted as target
    if self.highlight_target then
      -- Draw yellow glow with reduced opacity
      local glow_color = yellow[0]:clone()
      glow_color.a = 0.4
      graphics.rectangle(self.x, self.y, self.w+6, self.h+6, 3, 3, glow_color)
      graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, yellow[0], border_width)
    else
      -- Draw border with the appropriate level color
      if self.selected then
        graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, yellow[0], border_width)
      else
        graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, border_color, border_width)
      end
    end
  end

  graphics.pop()

  -- Draw item slots below the card
  for _, part in ipairs(self.item_parts) do
    part:draw()
  end
end

function OwnedWeaponCard:die()
  self.dead = true
  -- Global tooltip is handled by Create_Info_Text and clears itself

  -- Clean up item parts
  for _, part in ipairs(self.item_parts) do
    part:die()
  end
  self.item_parts = {}
end
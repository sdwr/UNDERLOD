buyScreen = nil

BuyScreen = Object:extend()
BuyScreen.__class_name = 'BuyScreen'
BuyScreen:implement(State)
BuyScreen:implement(GameObject)
function BuyScreen:init(name)
  self:init_state(name)
  self:init_game_object()
  buyScreen = self
  
  -- Initialize weapons array if not present
  if not self.weapons then
    self.weapons = {}
  end
end

function BuyScreen:on_exit()
  Kill_All_Cards()
  self.main:destroy()
  self.effects:destroy()
  self.ui:destroy()
  self.t:destroy()
  self.main = nil
  self.effects = nil
  self.ui = nil
  self.ui_top = nil
  self.overlay_ui = nil
  self.options_ui = nil
  self.gold_counter = nil
  self.items_text = nil
  self.sets = nil
  self.info_text = nil
  self.units = nil
  self.passives = nil
  self.player = nil
  self.t = nil
  self.springs = nil
  self.flashes = nil
  self.hfx = nil
  self.tutorial_button = nil
  self.restart_button = nil
  self.level_button = nil
  self.perks_panel = nil
end

function BuyScreen:on_enter(from)

  self.shop_level = level_to_shop_tier(self.level)
  self.last_shop_level = level_to_shop_tier(self.level - 1)
  
  if not locked_state and self.reroll_shop then
    self.shop_item_data = {}
  end
  camera.x, camera.y = gw/2, gh/2

  --decide on enemies for every level here
  --if this is the first level
  if self.level == 1 or #self.level_list == 0 then
    self:roll_levels()
  end

  if self.level == 1 and #self.units == 0 then
    self.units = {}
    self.first_shop = true
  end

  -- input:set_mouse_visible(true)
  
  -- Set cursor to simple mode for buy screen
  set_cursor_simple()
  
  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Shop - Level ' .. self.level)
  
  self.main = Group()
  self.effects = Group()
  self.ui = Group()
  self.ui_top = Group()
  self.overlay_ui = Group()
  self.tutorial = Group()
  self.options_ui = Group()
  
  -- Initialize perks if not already set
  if not self.perks then
    self.perks = {}
  end

  -- Create perks panel
  self.perks_panel = PerksPanel{
    group = self.ui,
    perks = self.perks
  }

  self:create_tutorial_popup()
  
  Check_All_Achievements()
  
  Refresh_All_Cards_Text()
  
  self.show_level_buttons = false
  
  self.gold_counter = GoldCounter{group = self.ui, x = GOLD_COUNTER_X_OFFSET, y = LEVEL_MAP_Y_POSITION + 1}

  -- Removed shop level text

  self.level_buttons = {}
  self.items = {}
  
  self:build_level_map()
  self:set_party()
  
  
  -- Move buttons to the left
  self.lock_button = LockButton{group = self.main, x = 40, y = gh - 50, parent = self}
  self.reroll_button = RerollButton{group = self.main, x = 40, y = gh - 25, parent = self}

  --only roll items once a character exists
  self:try_roll_items(true)
  
  GoButton{group = self.main, x = gw - 50, y = gh - 30, parent = self}
  
  -- self.tutorial_button = Button{group = self.main, x = gw/2 + 129, y = 18, button_text = '?', fg_color = 'bg10', bg_color = 'bg', 
  --   action = function()
  --     self.tutorial_popup:open()
  --     self.in_tutorial = true
  --   end,
  --   mouse_enter = function(b)
  --   b.info_text = InfoText{group = main.current.ui, force_update = true}
  --   b.info_text:activate({
  --     {text = '[fg]controls', font = pixul_font, alignment = 'center'},
  --   }, nil, nil, nil, nil, 16, 4, nil, 2)
  --   b.info_text.x, b.info_text.y = b.x, b.y + 20
  -- end, mouse_exit = function(b)
  --   if not b.info_text then return end
  --   b.info_text:deactivate()
  --   b.info_text.dead = true
  --   b.info_text = nil
  -- end}

  trigger:tween(1, main_song_instance, {volume = 0.2, pitch = 1}, math.linear)

  buyScreen:save_run()
end

function BuyScreen:on_item_purchased(unit, slot_index, item)
  -- Refresh character cards to show the new item
  Refresh_All_Cards_Text()
  
  -- You can add additional logic here if needed
  -- For example, play a specific sound, show a notification, etc.
end


function BuyScreen:update(dt)
  if main_song_instance and main_song_instance:isStopped() then
    main_song_instance = title_music:play{volume = 1}
  end

  if not self.paused then
    run_time = run_time + dt
  end

  self:update_game_object(dt*slow_amount)

  if not self.in_tutorial and not self.choose_character and not self.paused then
    self.main:update(dt*slow_amount)
    self.effects:update(dt*slow_amount)
    self.ui:update(dt*slow_amount)
    self.ui_top:update(dt*slow_amount)
    self.overlay_ui:update(dt*slow_amount)
    self.options_ui:update(dt*slow_amount)
    if self.items_text then self.items_text:update(dt) end
  elseif self.choose_character and not self.paused then
    self.overlay_ui:update(dt*slow_amount)
    self.options_ui:update(dt*slow_amount)
  elseif self.paused then
    self.options_ui:update(dt*slow_amount)
  else
    self.tutorial:update(dt*slow_amount)
    self.options_ui:update(dt*slow_amount)
  end

  --buy screen controls
  if input['lctrl'].down or input['rctrl'].down then
    if input['g'].pressed then
      gold = gold + 100
    end
    if input['u'].pressed then
      self.show_level_buttons = not self.show_level_buttons
    end
    if input['a'].pressed then
      --toggle achievements
    end
  end

  if input.escape.pressed and not self.transitioning then
    if not self.paused then
      open_options(self)
    else
      close_options(self, self.in_tutorial)
    end

  end
end

function BuyScreen:save_run()
  local save_data = Collect_Save_Data_From_State(self)
  save_data.gold = gold
  save_data.locked_state = locked_state

  system.save_run(save_data)
end

function BuyScreen:set_locked_state(state)
  locked_state = state
  if self.lock_button then
    self.lock_button:update_text()
  end
  self:save_run()
end

--level map /level list functions
function BuyScreen:roll_levels()
  self.level_list = Build_Level_List(NUMBER_OF_ROUNDS)
  --rebuild the level map to update the text/colors
  self:build_level_map()
end

function BuyScreen:build_level_map()
  if self.level_map then self.level_map:die() end
  self.level_map = BuildLevelMap(self.main, gw/2, LEVEL_MAP_Y_POSITION, self, self.level, self.loop, self.level_list)
  self:create_level_buttons()
end

function BuyScreen:create_level_buttons()
  if self.level_buttons then for _, button in ipairs(self.level_buttons) do button:die() end end
  self.level_buttons = {}
  local button = ArenaLevelButton{group = self.main, x = 195, y = 20, parent = self}
  table.insert(self.level_buttons, button)
  button = ArenaLevelButton{group = self.main, x = 295, y = 20, up = true, parent = self}
  table.insert(self.level_buttons, button)
end

--buy functions

function BuyScreen:buy_unit(character)
  table.insert(self.units, {character = character, level = 1, reserve = {0, 0}, items = {nil, nil, nil, nil, nil, nil}})
  self:set_party()
  self:save_run()
end

-- Weapon management functions
function BuyScreen:add_weapon(weapon_name)
  -- Check if we already own this weapon
  local existing_weapon = nil
  local existing_index = nil
  
  for i, weapon in ipairs(self.weapons) do
    if weapon.name == weapon_name then
      existing_weapon = weapon
      existing_index = i
      break
    end
  end
  
  if existing_weapon then
    -- Add XP to existing weapon
    existing_weapon.xp = (existing_weapon.xp or 0) + 1
    
    -- Check for level up
    -- Level 1->2 needs 2 xp, Level 2->3 needs 3 xp
    local xp_needed = 0
    if existing_weapon.level == 1 then
      xp_needed = 2
    elseif existing_weapon.level == 2 then
      xp_needed = 3
    end
    
    if existing_weapon.xp >= xp_needed and existing_weapon.level < WEAPON_MAX_LEVEL then
      existing_weapon.level = existing_weapon.level + 1
      existing_weapon.xp = existing_weapon.xp - xp_needed
      
      -- Play upgrade sound
      if upgrade1 then
        upgrade1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      end
    end
  else
    -- Add new weapon if we haven't reached the cap
    if #self.weapons < MAX_OWNED_WEAPONS then
      table.insert(self.weapons, {
        name = weapon_name,
        level = 1,
        xp = 0
      })
    else
      -- Can't add more weapons
      return false
    end
  end
  
  -- Force refresh of owned weapons display
  if self.owned_weapons_display then
    self.owned_weapons_display.weapons = table.copy(self.weapons)
    self.owned_weapons_display:refresh_cards()
  end
  
  self:save_run()
  return true
end

function BuyScreen:get_weapon_count()
  return #self.weapons
end

function BuyScreen:can_buy_weapon(weapon_name)
  -- Check if at max weapons (unless it's a duplicate)
  if #self.weapons >= MAX_OWNED_WEAPONS then
    for _, weapon in ipairs(self.weapons) do
      if weapon.name == weapon_name then
        return true -- Can buy duplicates to upgrade
      end
    end
    return false -- Can't buy new weapon type
  end
  return true
end

--item functions
--NO LONGER FUNCTIONAL WITH SLOT SYSTEM
function BuyScreen:unit_first_available_inventory_slot(unit)
  for i = 1, UNIT_LEVEL_TO_NUMBER_OF_ITEMS[unit.level] do
    if not unit.items[i] then
      return i
    end
  end
  return nil
end

--this returns the UI element "ItemPart" that corresponds to the first available inventory slot
--can call :addItem on this element to add an item rfto the unit's inventory
--NO LONGER FUNCTIONAL WITH SLOT SYSTEM
function BuyScreen:get_first_available_inventory_slot()
  for i, character in ipairs(Character_Cards) do
    if character.unit then
      local index = self:unit_first_available_inventory_slot(character.unit)
      if index then
        return character.items[index]
      end
    end
  end
  return nil
end

function BuyScreen:create_tutorial_popup()
  local shop_tutorial_lines = {
    {text = '[fg]Shop Tutorial', font = fat_font, alignment = 'center'},
    {text = '', height_multiplier = 0.1}, -- Spacer
    {text = '[yellow]Left Click:[fg] buy items and troops', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Left Click and drag:[fg] move items between troops', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Right Click:[fg] sell items', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]R:[fg] reroll shop', font = pixul_font, height_multiplier = 1.5},
    {text = '[yellow]Space:[fg] start next level', height_multiplier = 1.5},
    {text = '[yellow]Esc:[fg] open options', font = pixul_font, height_multiplier = 1.5},

  }

  self.tutorial_popup = TutorialPopup{
    group = self.tutorial, 
    parent = self,
    lines = shop_tutorial_lines,
    display_show_hints_checkbox = false,
    draw_bg = true,
  }
end




function BuyScreen:quit_tutorial()
  self.in_tutorial = false
end

-- Perk management functions
function BuyScreen:add_perk(perk)
  if self.perks_panel:add_perk(perk) then
    self:save_run()
    return true
  end
  return false
end

function BuyScreen:remove_perk(index)
  if self.perks_panel:remove_perk(index) then
    self:save_run()
    return true
  end
  return false
end

function BuyScreen:set_perks(perks)
  self.perks = perks or {}
  if self.perks_panel then
    self.perks_panel:set_perks(self.perks)
  end
  self:save_run()
end


function BuyScreen:draw()
  self.main:draw()
  self.effects:draw()
  if self.items_text then self.items_text:draw(self.items_text_x, self.items_text_y) end


  self.ui:draw()
  self.ui_top:draw()
  if self.paused then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  
  self.overlay_ui:draw()
  self.tutorial:draw()
  self.options_ui:draw()

end

function BuyScreen:gain_gold(amount)
  gold = (gold + amount) or 0
end

function BuyScreen:set_party()
  Kill_All_Cards()
  Character_Cards = {}
  
  -- Create owned weapons display in center of screen
  if self.owned_weapons_display then
    self.owned_weapons_display:die()
  end
  
  self.owned_weapons_display = OwnedWeaponDisplay{
    group = self.ui,
    x = gw/2,
    y = gh/2 - 60,
    weapons = self.weapons,
    parent = self
  }
end

function BuyScreen:try_buy_unit(cost)
  if gold >= cost then
    self:gain_gold(-cost)
    gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.overlay_ui
    }
  end
end

function BuyScreen:most_copies_of_unit()
  -- No longer tracking units, return 0
  return 0
end

function BuyScreen:try_roll_items(is_shop_start)
  self:set_weapons(self.shop_level, is_shop_start)
end

-- Combined weapon and item shop
function BuyScreen:set_weapons(shop_level, is_shop_start)
  -- Clear all cards
  if self.weapon_cards then
    for _, card in ipairs(self.weapon_cards) do
      card:die()
    end
  end
  self.weapon_cards = {}

  if self.item_cards then
    for _, card in ipairs(self.item_cards) do
      card:die()
    end
  end
  self.item_cards = {}

  -- Initialize shop data
  if not self.shop_weapon_data then
    self.shop_weapon_data = {}
  end
  if not self.shop_item_data then
    self.shop_item_data = {}
  end

  -- Roll new weapons and items if needed
  if not locked_state and self.reroll_shop then
    self.shop_weapon_data = Get_Random_Shop_Weapons(3)
    self.shop_item_data = Get_Random_Shop_Items(2, shop_level)  -- Get 2 items
  elseif locked_state and self.reroll_shop then
    -- Fill empty slots
    while #self.shop_weapon_data < 3 do
      local available_weapons = Get_Random_Shop_Weapons(1)
      if available_weapons[1] then
        table.insert(self.shop_weapon_data, available_weapons[1])
      end
    end
    while #self.shop_item_data < 2 do
      local available_items = Get_Random_Shop_Items(1, shop_level)
      if available_items[1] then
        table.insert(self.shop_item_data, available_items[1])
      end
    end
  end

  -- Only reroll once
  self.reroll_shop = false

  -- Disable interaction with buttons while rerolling
  if self.reroll_button then self.reroll_button.interact_with_mouse = false end
  if self.lock_button then self.lock_button.interact_with_mouse = false end

  -- Shop layout: 5 cards total (3 weapons + 2 items)
  local card_h = 80
  local card_w = 60
  local card_spacing = 70
  local y = gh - (card_h / 2) - 20

  -- Center the 5 cards
  local total_width = 5 * card_spacing - (card_spacing - card_w)
  local start_x = gw/2 - total_width/2 + card_w/2

  -- Create 3 weapon cards
  for i = 1, 3 do
    if self.shop_weapon_data[i] then
      local card = WeaponCard{
        group = self.ui,
        x = start_x + (i-1) * card_spacing,
        y = y,
        w = card_w,
        h = card_h,
        weapon_name = self.shop_weapon_data[i],
        parent = self,
        i = i
      }
      table.insert(self.weapon_cards, card)
    end
  end

  -- Create 2 item cards
  for i = 1, 2 do
    if self.shop_item_data[i] then
      local card = ItemCard{
        group = self.ui,
        x = start_x + (2 + i) * card_spacing,  -- Position after 3 weapons
        y = y,
        w = card_w,
        h = card_h,
        item = self.shop_item_data[i],
        parent = self,
        i = 3 + i  -- Index continues from weapons
      }
      table.insert(self.item_cards, card)
    end
  end

  -- Re-enable buttons after a short delay
  self.t:after(0.1, function()
    if self.reroll_button then self.reroll_button.interact_with_mouse = true end
    if self.lock_button then self.lock_button.interact_with_mouse = true end
  end)
end

-- Keep old function for compatibility but have it call the new one
function BuyScreen:set_items(shop_level, is_shop_start)
  self:set_weapons(shop_level, is_shop_start)
  self.reroll_button:on_mouse_exit()
  self.lock_button:on_mouse_exit()
  self.reroll_button.selected = false
  self.lock_button.selected = false


  local item_h = 50
  local item_w = 40

  local y = gh - (item_h / 2) - 20
  local x = gw/2 - 70

  -- Create items with staggered timing
  local transition_duration = is_shop_start and TRANSITION_DURATION_IN_NEW_STATE + 0.2 or 0

 -- Check if the shop has actually leveled up since the last time we animated it.
  if self.shop_level > self.last_shop_level then
    -- IT HAS: Play the level up animation and sound.
    self.t:after(transition_duration, function()
        gold3:play{pitch = random:float(0.95, 1.05), volume = 0.7}
        
        for i = 1, 20 do
            local angle = (i / 20) * 2 * math.pi
            local distance = math.random() * 30
            local particle_x = self.items_text_x + math.cos(angle) * distance
            local particle_y = self.items_text_y + math.sin(angle) * distance
            HitParticle{group = self.ui, x = particle_x, y = particle_y, color = yellow[0]}
        end
        
        self.items_text:set_text({{text = '[wavy_mid, fg]shop - Lv. ' .. self.shop_level, font = pixul_font, alignment = 'center'}})
    end)
    
    -- Delay item creation to happen after the text animation
    transition_duration = transition_duration
    
    -- IMPORTANT: Update last_shop_level immediately.
    -- This "remembers" that we've played the animation for this level,
    -- preventing it from running again on a reroll or re-entry.
    self.last_shop_level = self.shop_level

  else
    -- IT HAS NOT: This is a reroll or a re-entry from the main menu.
    -- Just set the text instantly without any animation.
    self.items_text:set_text({{text = '[wavy_mid, fg]shop - Lv. ' .. self.shop_level, font = pixul_font, alignment = 'center'}})
  end

  --create items
  local item_count = 0
  for i = 1, 3 do
    local item_number = i
    if self.shop_item_data[i] then
      item_count = item_count + 1
      self.t:after((0.3 * (item_count-1)) + transition_duration, function()
        local item = ItemCard{
          group = self.ui, 
          x = x + (i-1)*70, 
          y = y, 
          w = 60,
          h = 80,
          item = self.shop_item_data[i], 
          parent = self, 
          i = i,
          is_perk_selection = self.is_perk_selection
        }
        table.insert(self.items, item)
      end)
    end
  end
  self.t:after(((item_count-1) * 0.3) + transition_duration, function()
    self.reroll_button.interact_with_mouse = true
    self.lock_button.interact_with_mouse = true
  end)

end




SteamFollowButton = Object:extend()
SteamFollowButton.__class_name = 'SteamFollowButton'
SteamFollowButton:implement(GameObject)
function SteamFollowButton:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  self.shape = Rectangle(self.x, self.y, pixul_font:get_text_width('follow me on steam!') + 12, pixul_font.h + 4)
  self.text = Text({{text = '[greenm5]follow me on steam!', font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function SteamFollowButton:update(dt)
  self:update_game_object(dt)
  if main.current.in_credits then return end

  if self.selected and input.m1.pressed then
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    self.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url'https://store.steampowered.com/dev/a327ex/'
  end
end


function SteamFollowButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or green[0])
    self.text:draw(self.x, self.y)
  graphics.pop()
end


function SteamFollowButton:on_mouse_enter()
  if main.current.in_credits then return end
  love.mouse.setCursor(love.mouse.getSystemCursor'hand')
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]follow me on steam!', font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.05, 200, 10)
end


function SteamFollowButton:on_mouse_exit()
  if main.current.in_credits then return end
  love.mouse.setCursor()
  self.text:set_text{{text = '[greenm5]follow me on steam!', font = pixul_font, alignment = 'center'}}
  self.selected = false
end




WishlistButton = Object:extend()
WishlistButton.__class_name = 'WishlistButton'
WishlistButton:implement(GameObject)
function WishlistButton:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  if self.w_to_wishlist then
    self.shape = Rectangle(self.x, self.y, 85, 18)
    self.text = Text({{text = '[bg10]w to wishlist', font = pixul_font, alignment = 'center'}}, global_text_tags)
  else
    self.shape = Rectangle(self.x, self.y, 110, 18)
    self.text = Text({{text = '[bg10]wishlist on steam', font = pixul_font, alignment = 'center'}}, global_text_tags)
  end
end


function WishlistButton:update(dt)
  self:update_game_object(dt)

  if self.selected and input.m1.pressed then
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    self.selected = true
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    system.open_url'https://store.steampowered.com/app/915310/SNKRX/'
  end
end


function WishlistButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[1])
    self.text:draw(self.x, self.y + 1)
  graphics.pop()
end


function WishlistButton:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  if self.w_to_wishlist then
    self.text:set_text{{text = '[fgm5]w to wishlist', font = pixul_font, alignment = 'center'}}
  else
    self.text:set_text{{text = '[fgm5]wishlist on steam', font = pixul_font, alignment = 'center'}}
  end
  self.spring:pull(0.2, 200, 10)
end


function WishlistButton:on_mouse_exit()
  if self.w_to_wishlist then
    self.text:set_text{{text = '[bg10]w to wishlist', font = pixul_font, alignment = 'center'}}
  else
    self.text:set_text{{text = '[bg10]wishlist on steam', font = pixul_font, alignment = 'center'}}
  end
  self.selected = false
end

ArenaLevelButton = Object:extend()
ArenaLevelButton.__class_name = 'ArenaLevelButton'
ArenaLevelButton:implement(GameObject)
function ArenaLevelButton:init(args)
  self:init_game_object(args)
  local text = '-'
  if self.up then
    text = "+"
  end
  self.shape = Rectangle(self.x, self.y, pixul_font:get_text_width(text) + 2, pixul_font.h + 4)
  self.interact_with_mouse = true
  self.text = Text({{text = text, font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function ArenaLevelButton:update(dt)
  if main.current.in_credits then return end
  self:update_game_object(dt)

  if buyScreen.show_level_buttons then
    if self.selected and input.m1.pressed then
      if self.up then
        self.parent.level = self.parent.level + 1
        self.parent.level_map:reset()
      else
        if self.parent.level > 1 then
          self.parent.level = self.parent.level -1
          self.parent.level_map:reset()
        end
      end
      self.parent.shop_level = level_to_shop_tier(self.parent.level)
      system.save_state()
      buyScreen:save_run()
    end
  end
end


function ArenaLevelButton:draw()
  if buyScreen.show_level_buttons then
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[1])
      self.text:draw(self.x, self.y + 1, 0, 1, 1)
    graphics.pop()
  end
end


function ArenaLevelButton:on_mouse_enter()
  if main.current.in_credits then return end
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.spring:pull(0.2, 200, 10)
end


function ArenaLevelButton:on_mouse_exit()
  if main.current.in_credits then return end
  self.selected = false
end

function ArenaLevelButton:die()
  self.dead = true
end





RestartButton = Object:extend()
RestartButton.__class_name = 'RestartButton'
RestartButton:implement(GameObject)
function RestartButton:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, pixul_font:get_text_width('restart') + 4, pixul_font.h + 4)
  self.interact_with_mouse = true
  self.text = Text({{text = '[bg10]NG+' .. tostring(current_new_game_plus), font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function RestartButton:update(dt)
  if main.current.in_credits then return end
  self:update_game_object(dt)

  if self.selected and input.m1.pressed then
    main.current.transitioning = true
    ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    TransitionEffect{group = main.transitions, x = gw/2, y = gh/2, color = state.dark_transitions and bg[-2] or fg[0], transition_action = function()
      current_new_game_plus = current_new_game_plus + 1
      Start_New_Run_And_Go_To_Buy_Screen()
    end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']restarting...', font = pixul_font, alignment = 'center'}}, global_text_tags)}
  end
end


function RestartButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[1])
    self.text:draw(self.x, self.y + 1, 0, 1, 1)
  graphics.pop()
end


function RestartButton:on_mouse_enter()
  if main.current.in_credits then return end
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]NG+' .. tostring(current_new_game_plus), font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
end


function RestartButton:on_mouse_exit()
  if main.current.in_credits then return end
  self.text:set_text{{text = '[bg10]NG+' .. tostring(current_new_game_plus), font = pixul_font, alignment = 'center'}}
  self.selected = false
end






Button = Object:extend()
Button.__class_name = 'Button'
Button:implement(GameObject)
function Button:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
  self.interact_with_mouse = true
  self.text = Text({{text = '[' .. self.fg_color .. ']' .. self.button_text, font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function Button:update(dt)
  self:update_game_object(dt)
  if main.current.in_credits and not self.credits_button then return end

  if self.hold_button then
    if self.selected and input.m1.pressed then
      self.press_time = love.timer.getTime()
      self.spring:pull(0.2, 200, 10)
    end
    if self.press_time then
      if input.m1.down and love.timer.getTime() - self.press_time > self.hold_button then
        self:action()
        self.press_time = nil
        self.spring:pull(0.1, 200, 10)
      end
    end
    if input.m1.released then
      self.press_time = nil
      self.spring:pull(0.1, 200, 10)
    end
  else
    if self.selected and input.m1.pressed then
      if self.action then
        self:action()
      end
    end
    if self.selected and input.m2.pressed then
      if self.action_2 then
        self:action_2()
      end
    end
  end
end


function Button:draw()
  -- If this button is a child of an ItemCard, use the parent's spring scaling
  local spring_x, spring_y = self.spring.x, self.spring.y
  if self.parent and self.parent.item then -- ItemCard has an 'item' property
    spring_x = self.parent.sx * self.parent.spring.x
    spring_y = self.parent.sy * self.parent.spring.x
  end
  
  graphics.push(self.x, self.y, 0, spring_x, spring_y)
    if self.hold_button and self.press_time then
      graphics.set_line_width(5)
      graphics.set_color(fg[-5])
      graphics.arc('open', self.x, self.y, 0.6*self.shape.w, 0, math.remap(love.timer.getTime() - self.press_time, 0, self.hold_button, 0, 1)*2*math.pi)
      graphics.set_line_width(1)
    end
    local selected_bg_color = self.selected_bg_color or fg[0]
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and selected_bg_color or _G[self.bg_color][0])
    self.text:draw(self.x, self.y + 1, 0, 1, 1)
  graphics.pop()
end


function Button:on_mouse_enter()
  if main.current.in_credits and not self.credits_button then return end
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]' .. self.button_text, font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
  if self.mouse_enter then self:mouse_enter() end
end


function Button:on_mouse_exit()
  if main.current.in_credits and not self.credits_button then return end
  self.text:set_text{{text = '[' .. self.fg_color .. ']' .. self.button_text, font = pixul_font, alignment = 'center'}}
  self.selected = false
  if self.mouse_exit then self:mouse_exit() end
end


function Button:set_text(text)
  self.button_text = text
  self.text:set_text{{text = '[' .. self.fg_color .. ']' .. self.button_text, font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
end




GoButton = Object:extend()
GoButton.__class_name = 'GoButton'
GoButton:implement(GameObject)
function GoButton:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 28, 18)
  self.interact_with_mouse = true
  self.text = Text({{text = '[greenm5]GO!', font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function GoButton:update(dt)
  self:update_game_object(dt)

  if ((self.selected and input.m1.pressed) or input.enter.pressed) and not self.transitioning then
    if #self.parent.weapons == 0 then
      if not self.info_text then
        error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self.info_text = InfoText{group = main.current.ui}
        self.info_text:activate({
          {text = '[fg]cannot start the round with [yellow]0 [fg]weapons', font = pixul_font, alignment = 'center'},
        }, nil, nil, nil, nil, 16, 4, nil, 2)
        self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
      end
      self.t:after(2, function() self.info_text:deactivate(); self.info_text.dead = true; self.info_text = nil end, 'info_text')

    else
      ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self.spring:pull(0.2, 200, 10)
      self.selected = true
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      ui_transition1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self.transitioning = true
      buyScreen:save_run()
      TransitionEffect{group = main.transitions, x = self.x, y = self.y, color = state.dark_transitions and bg[-2] or orange[0], transition_action = function()

        main:add(WorldManager'world_manager')

        local current_run = Collect_Save_Data_From_State(self.parent)
        main:go_to('world_manager', current_run)
      end, text = Text({{text = '[wavy, ' .. tostring(state.dark_transitions and 'fg' or 'bg') .. ']level ' .. tostring(self.parent.level) .. '/' .. tostring(25*(self.parent.loop+1)), font = pixul_font, alignment = 'center'}}, global_text_tags)}
    end

    if input.enter.pressed then self.selected = false end
  end
end


function GoButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or green[0])
    self.text:draw(self.x, self.y + 1, 0, 1, 1)
  graphics.pop()
end


function GoButton:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]GO!', font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
end


function GoButton:on_mouse_exit()
  self.text:set_text{{text = '[greenm5]GO!', font = pixul_font, alignment = 'center'}}
  self.selected = false
end


LockButton = Object:extend()
LockButton.__class_name = 'LockButton'
LockButton:implement(GameObject)
function LockButton:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 32, 16)
  self.interact_with_mouse = true
  if locked_state then self.shape.w = 44
  else self.shape.w = 32 end
  if locked_state then self.text = Text({{text = '[fgm5]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}}, global_text_tags)
  else self.text = Text({{text = '[bg10]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}}, global_text_tags) end
end


function LockButton:update(dt)
  self:update_game_object(dt)

  if not self.interact_with_mouse then return end

  if self.selected and input.m1.pressed then
    self.parent:set_locked_state(not locked_state)
    glass_shatter:play{volume = 0.6}
    self.selected = true
    self.spring:pull(0.2, 200, 10)
    if locked_state then self.shape.w = 44
    else self.shape.w = 32 end
  end
end

function LockButton:update_text()
  self.text:set_text{{text = '[fgm5]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}}
  if locked_state then self.shape.w = 44
  else self.shape.w = 32 end
end


function LockButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, (self.selected or locked_state) and fg[0] or bg[1])
    self.text:draw(self.x, self.y + 1)
  graphics.pop()
end


function LockButton:on_mouse_enter()
  if not self.interact_with_mouse then return end

  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
end


function LockButton:on_mouse_exit()
  if not self.interact_with_mouse then return end

  if not locked_state then self.text:set_text{{text = '[bg10]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}} end
  self.selected = false
end

RerollButton = Object:extend()
RerollButton.__class_name = 'RerollButton'
RerollButton:implement(GameObject)
function RerollButton:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  if self.parent:is(BuyScreen) then
    self.shape = Rectangle(self.x, self.y, 54, 16)
    self.text = Text({{text = '[bg10]reroll: [yellow]', font = pixul_font, alignment = 'center'}}, global_text_tags)
    self:refresh_text('[bg10]')
  elseif self.parent:is(Arena) then
    self.shape = Rectangle(self.x, self.y, 60, 16)
    local merchant
    for _, unit in ipairs(self.parent.starting_units) do
      if unit.character == 'merchant' then
        merchant = unit
        break
      end
    end
    if self.parent.level == 3 or (merchant and merchant.level == 3) then
      self.free_reroll = true
      self.text = Text({{text = '[bg10]reroll: [yellow]0', font = pixul_font, alignment = 'center'}}, global_text_tags)
    else
      self.text = Text({{text = '[bg10]reroll: [yellow]5', font = pixul_font, alignment = 'center'}}, global_text_tags)
    end
  end
end

function RerollButton:update(dt)
  self:update_game_object(dt)

  if not self.interact_with_mouse then return end

  if (self.selected and input.m1.pressed) or input.r.pressed then
    if self.parent.level == 1 then
      Create_Info_Text('cannot roll items in the first level', self, 'error')
    elseif self.parent:is(BuyScreen) then
      local rerollCost = REROLL_COST(self.parent.times_rerolled)
      if gold < rerollCost then
        self.spring:pull(0.2, 200, 10)
        self.selected = true
        error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        if not self.info_text then
          self.info_text = InfoText{group = main.current.ui}
          self.info_text:activate({
            {text = '[fg]not enough gold', font = pixul_font, alignment = 'center'},
          }, nil, nil, nil, nil, 16, 4, nil, 2)
          self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
        end
        self.t:after(2, function() self.info_text:deactivate(); self.info_text.dead = true; self.info_text = nil end, 'info_text')
      else
        --don't play sound here
        if locked_state then
          self.parent:set_locked_state(false)
        end
        self.parent.reroll_shop = true
        gold = gold - rerollCost
        self.parent.times_rerolled = self.parent.times_rerolled + 1
        self.parent:try_roll_items(false)
        self:refresh_text('[bg10]')
        gold2:play{pitch = random:float(0.95, 1.05), volume = 0.3}
        self.selected = true
        self.spring:pull(0.2, 200, 10)

        Stats_Current_Run_Rerolls()
        Stats_Total_Rerolls()
        buyScreen:save_run()
      end
    elseif self.parent:is(Arena) then
      --nothing
    end

    if input.r.pressed then self.selected = false end
  end
end

function RerollButton:refresh_text(colorString)
  if self.parent:is(BuyScreen) then
    local rerollCost = REROLL_COST(self.parent.times_rerolled)
    local re = tostring(rerollCost)
    self.text:set_text{{text = colorString ..'reroll: [yellow]'.. re, font = pixul_font, alignment = 'center'}}
  elseif self.parent:is(Arena) then
    --unused
  end

end


function RerollButton:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    if self.parent:is(Arena) then
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[-2])
    else
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[1])
    end
    self.text:draw(self.x, self.y + 1)
  graphics.pop()
end


function RerollButton:on_mouse_enter()
  if not self.interact_with_mouse then return end

  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  if self.parent:is(BuyScreen) then
    self:refresh_text('[fgm5]')
  elseif self.parent:is(Arena) then
    if self.free_reroll then
      self.text:set_text{{text = '[fgm5]reroll: 0', font = pixul_font, alignment = 'center'}}
    else
      self.text:set_text{{text = '[fgm5]reroll: 5', font = pixul_font, alignment = 'center'}}
    end
  end
  self.spring:pull(0.2, 200, 10)
end


function RerollButton:on_mouse_exit()
  if not self.interact_with_mouse then return end

  if self.parent:is(BuyScreen) then
    self:refresh_text('[bg10]')
  elseif self.parent:is(Arena) then
    if self.free_reroll then
      self.text:set_text{{text = '[fgm5]reroll: [yellow]0', font = pixul_font, alignment = 'center'}}
    else
      self.text:set_text{{text = '[fgm5]reroll: [yellow]5', font = pixul_font, alignment = 'center'}}
    end
  end
  self.selected = false
end

LooseItem = Object:extend()
LooseItem.__class_name = 'LooseItem'
LooseItem:implement(GameObject)
function LooseItem:init(args)
  self:init_game_object(args)
  self.h = self.sy * 20
  self.w = self.sx * 20
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false

end

function LooseItem:update(dt)
  if self.dead then return end

  self:update_game_object(dt)

  if not self.flying_to_slot then
    self.x, self.y = camera:get_mouse_position()
    self.shape:move_to(self.x, self.y)
  end
end


--duplicated from ItemPart (should be combined!!)
function LooseItem:draw()
  if self.item then
    -- Use V2 item tier_color if available, otherwise fall back to item_to_color
  local tier_color = self.item.tier_color or item_to_color(self.item)
    graphics.rectangle(self.x, self.y, self.w+4, self.h+4, 3, 3, tier_color)
    graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg[5])
    if self.item.colors then
      local num_colors = #self.item.colors
      local color_h = self.h / num_colors
      for i, color_name in ipairs(self.item.colors) do
        --make a copy of the color so we can change the alpha
        local color = _G[color_name]
        color = color[0]:clone()
        color.a = 0.6
        --find the y midpoint of the rectangle
        local y = (self.y - self.h/2) + ((i-1) * color_h) + (color_h/2)

        graphics.rectangle(self.x, y, self.w, color_h, 2, 2, color)
      end
    end
  end

  local image = find_item_image(self.item)
  if image then
    image:draw(self.x, self.y, 0, 0.4, 0.4)
  end

end

function LooseItem:move_item_to_slot(target_item_part, on_complete, create_hit_effect, duration)
  -- Set flag on target ItemPart to hide display during animation
  target_item_part.hide_item_display = true
  
  -- Disable interaction during animation
  self.interact_with_mouse = false
  self.flying_to_slot = true
  
  -- Default to creating hit effects unless explicitly disabled
  if create_hit_effect == nil then create_hit_effect = true end
  
  -- Animate towards the target slot
  if duration == nil then duration = 0.2 end
  self.t:tween(duration, self, {
    x = target_item_part.x, 
    y = target_item_part.y,
    sx = ITEM_PART_WIDTH / self.w,
    sy = ITEM_PART_HEIGHT / self.h
  }, math.out_cubic, function()
    -- Animation complete
    target_item_part.hide_item_display = false
    
    -- Create particle effect at the target slot only if requested
    if create_hit_effect then
      target_item_part:create_item_added_effect(self.item)
    end
    
    -- Call completion callback
    if on_complete then
      on_complete()
    end
    
    self:die()
  end)
end

function LooseItem:update(dt)
  self:update_game_object(dt)
  
  -- Only follow mouse if not flying to slot
  if not self.flying_to_slot then
    self.x, self.y = camera:get_mouse_position()
  end
  
  self.shape:move_to(self.x, self.y)
end

function LooseItem:die()
  self.dead = true
  if Loose_Inventory_Item and Loose_Inventory_Item.id == self.id then
    Loose_Inventory_Item = nil
  end
end

PassiveCard = Object:extend()
PassiveCard.__class_name = 'PassiveCard'
PassiveCard:implement(GameObject)
function PassiveCard:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.spring:pull(0.2, 200, 10)
end


function PassiveCard:update(dt)
  self:update_game_object(dt)

  if ((self.selected and input.m1.pressed) or input[tostring(self.card_i)].pressed) and self.arena.choosing_passives then
    self.arena.choosing_passives = false
    table.insert(self.arena.passives, {passive = self.passive, level = 1, xp = 0})
    self.arena:restore_passives_to_pool(self.card_i)
    trigger:tween(0.25, _G, {slow_amount = 1, music_slow_amount = 1}, math.linear, function()
      slow_amount = 1
      music_slow_amount = 1
      self.arena:transition()
    end)
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self:die()
  end
end


function PassiveCard:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    _G[self.passive]:draw(self.x, self.y + 24, 0, 1, 1, 0, 0, fg[0])
  graphics.pop()
end


function PassiveCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end


function PassiveCard:on_mouse_exit()
  self.selected = false
end


function PassiveCard:die()
  self.dead = true
end



CharacterIcon = Object:extend()
CharacterIcon.__class_name = 'CharacterIcon'
CharacterIcon:implement(GameObject)
function CharacterIcon:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 40, 20)
  self.interact_with_mouse = true
  self.character_text = Text({{text = '[' .. character_color_strings[self.character] .. ']' .. string.lower(character_names[self.character]), font = pixul_font, alignment = 'center'}}, global_text_tags)
end


function CharacterIcon:update(dt)
  self:update_game_object(dt)
  self.character_text:update(dt)
end


function CharacterIcon:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    graphics.rectangle(self.x, self.y - 7, 14, 14, 3, 3, character_colors[self.character])
    self.character_text:draw(self.x, self.y + 10)
  graphics.pop()
end


function CharacterIcon:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
  if self.text_on_mouseover then
    self.info_text = InfoText{group = main.current.ui}
    self.info_text:activate({
      {text = '[' .. character_color_strings[self.character] .. ']' .. self.character:capitalize() .. '[fg] - cost: [yellow]' .. self.parent.cost, font = pixul_font, alignment = 'center', height_multiplier = 1.25},
      {text = '[fg]Types: ' .. character_type_strings[self.character], font = pixul_font, alignment = 'center', height_multiplier = 1.25},
    }, nil, nil, nil, nil, 16, 4, nil, 2)
    self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
  end
end


function CharacterIcon:on_mouse_exit()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
  end
  self.info_text = nil
end


function CharacterIcon:die(dont_spawn_effect)
  self.dead = true
  if not dont_spawn_effect then SpawnEffect{group = main.current.effects, x = self.x, y = self.y + 4, color = character_colors[self.character]} end
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end



TutorialClassIcon = Object:extend()
TutorialClassIcon.__class_name = 'TutorialClassIcon'
TutorialClassIcon:implement(GameObject)
function TutorialClassIcon:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y + 11, 20, 40)
  self.interact_with_mouse = true
  self.spring:pull(0.2, 200, 10)
end


function TutorialClassIcon:update(dt)
  self:update_game_object(dt)
end


function TutorialClassIcon:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
  graphics.pop()
end


function TutorialClassIcon:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end


function TutorialClassIcon:on_mouse_exit()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
  end
  self.info_text = nil
end




TypeIcon = Object:extend()
TypeIcon.__class_name = 'TypeIcon'
TypeIcon:implement(GameObject)
function TypeIcon:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y + 11, 20, 40)
  self.interact_with_mouse = true
  self.t:every(0.5, function() self.flash = not self.flash end)
  self.spring:pull(0.2, 200, 10)
end


function TypeIcon:update(dt)
  self:update_game_object(dt)
end


function TypeIcon:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
  graphics.pop()
end


function TypeIcon:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end


function TypeIcon:on_mouse_exit()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
  end
  self.info_text = nil

  if not self.parent:is(ShopCard) then
    for _, character in ipairs(self.parent.characters) do
      if character_types[character.character]== self.type then
        character:unhighlight()
        for _, c in ipairs(character.parts) do
          c:unhighlight()
        end
      end
    end
  end
end


function TypeIcon:die(dont_spawn_effect)
  self.dead = true
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end

  if self.selected and not self.parent:is(ShopCard) then
    for _, character in ipairs(self.parent.characters) do
      if character.type == self.type then
        character:highlight()
      end
    end
  end
end


function TypeIcon:highlight()
  self.highlighted = true
  self.spring:pull(0.2, 200, 10)
end


function TypeIcon:unhighlight()
  self.highlighted = false
  self.spring:pull(0.05, 200, 10)
end

-- helper functions
function Create_Info_Text(text, parent, type)
  if global_info_text then
    global_info_text:deactivate()
    global_info_text.dead = true
    global_info_text = nil
  end
  error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  local info_text = InfoText{group = main.current.world_ui or main.current.ui}
  
  info_text:activate({
    {text = '[fg]' .. text, font = pixul_font, alignment = 'center'},
  }, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position(type)
  info_text.x, info_text.y = pos.x, pos.y
  info_text.t:after(2, function() info_text:deactivate(); info_text.dead = true; info_text = nil end, 'info_text')
  
  global_info_text = info_text
end
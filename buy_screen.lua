buyScreen = nil

BuyScreen = Object:extend()
BuyScreen:implement(State)
BuyScreen:implement(GameObject)
function BuyScreen:init(name)
  self:init_state(name)
  self:init_game_object()
  buyScreen = self
end

function BuyScreen:on_exit()
  self.main:destroy()
  self.effects:destroy()
  self.ui:destroy()
  self.t:destroy()
  Kill_All_Cards()
  self.main = nil
  self.effects = nil
  self.ui = nil
  self.ui_top = nil
  self.overlay_ui = nil
  self.options_ui = nil
  self.shop_text = nil
  self.items_text = nil
  self.sets = nil
  self.info_text = nil
  self.units = nil
  self.loose_inventory_item = nil
  self.passives = nil
  self.player = nil
  self.t = nil
  self.springs = nil
  self.flashes = nil
  self.hfx = nil
  self.tutorial_button = nil
  self.restart_button = nil
  self.level_button = nil
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

  input:set_mouse_visible(true)
  
  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Shop - Level ' .. self.level)
  
  self.main = Group()
  self.effects = Group()
  self.ui = Group()
  self.ui_top = Group()
  self.overlay_ui = Group()
  self.tutorial = Group()
  self.options_ui = Group()

  self:create_tutorial_popup()
  
  Check_All_Achievements()
  
  Refresh_All_Cards_Text()
  
  self.show_level_buttons = false
  
  self.shop_text = Text({{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}, global_text_tags)

  self.items_text_x, self.items_text_y = gw/2 - 150, gh - 60
  self.items_text = Text({{text = '[wavy_mid, fg]shop - Lv. ' .. self.last_shop_level, font = pixul_font, alignment = 'center'}}, global_text_tags)

  self.level_buttons = {}
  self.items = {}
  
  self:build_level_map()
  self:set_party()
  
  
  self.lock_button = LockButton{group = self.main, x = gw/2 - 150, y = gh - 40, parent = self}
  self.reroll_button = RerollButton{group = self.main, x = 90, y = gh - 20, parent = self}

  --only roll items once a character exists
  if not self.first_shop then
    self:try_roll_items(true)
  end
  
  GoButton{group = self.main, x = gw - 90, y = gh - 20, parent = self}
  
  self.tutorial_button = Button{group = self.main, x = gw/2 + 129, y = 18, button_text = '?', fg_color = 'bg10', bg_color = 'bg', 
    action = function()
      self.tutorial_popup:open()
      self.in_tutorial = true
    end,
    mouse_enter = function(b)
    b.info_text = InfoText{group = main.current.ui, force_update = true}
    b.info_text:activate({
      {text = '[fg]controls', font = pixul_font, alignment = 'center'},
    }, nil, nil, nil, nil, 16, 4, nil, 2)
    b.info_text.x, b.info_text.y = b.x, b.y + 20
  end, mouse_exit = function(b)
    if not b.info_text then return end
    b.info_text:deactivate()
    b.info_text.dead = true
    b.info_text = nil
  end}

  trigger:tween(1, main_song_instance, {volume = 0.2, pitch = 1}, math.linear)

  buyScreen:save_run()
end


function BuyScreen:update(dt)
  if main_song_instance and main_song_instance:isStopped() then
    main_song_instance = silence:play{volume = 0.5}
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
    if self.shop_text then self.shop_text:update(dt) end
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
      self.shop_text:set_text{{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}
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
  self.level_map = BuildLevelMap(self.main, gw/2, 30, self, self.level, self.loop, self.level_list)
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
  table.insert(self.units, {character = character, level = 1, reserve = {0, 0}, items = {nil, nil, nil, nil, nil, nil}, numItems = 6})
  self:set_party()
  if #self.items == 0 and gold > 0 then
    self:try_roll_items(false)
  end
  self:save_run()
end

--item functions

function BuyScreen:unit_first_available_inventory_slot(unit)
  for i = 1, 6 do
    if not unit.items[i] then
      return i
    end
  end
  return nil
end

--this returns the UI element "ItemPart" that corresponds to the first available inventory slot
--can call :addItem on this element to add an item rfto the unit's inventory
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


function BuyScreen:draw()
  self.main:draw()
  self.effects:draw()
  if self.items_text then self.items_text:draw(self.items_text_x, self.items_text_y) end

  if self.shop_text then self.shop_text:draw(64, 20) end

  self.ui:draw()
  self.ui_top:draw()
  if self.paused then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  
  self.overlay_ui:draw()
  self.tutorial:draw()
  self.options_ui:draw()

end

function BuyScreen:gain_gold(amount)
  gold = (gold + amount) or 0
  self.shop_text:set_text{{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}
end

function BuyScreen:set_party()
  Kill_All_Cards()
  Character_Cards = {}

  local y = gh/2
  local x = gw/2

  local number_of_cards = #self.units
  if self.first_shop then
    number_of_cards = number_of_cards + 1
  end
  if self.level >= PICK_SECOND_CHARACTER and number_of_cards < 2 then
    number_of_cards = number_of_cards + 1
  end
  if self.level >= PICK_THIRD_CHARACTER and number_of_cards < 3 then
    number_of_cards = number_of_cards + 1
  end


  --center single unit, otherwise start on the left

  if number_of_cards == 2 then
    x = gw/2 - CHARACTER_CARD_WIDTH/2 - CHARACTER_CARD_SPACING
  elseif number_of_cards == 3 then
    x = gw/2 - CHARACTER_CARD_WIDTH - CHARACTER_CARD_SPACING
  end

  for i, unit in ipairs(self.units) do
    table.insert(Character_Cards, CharacterCard{group = self.main, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self})
    unit.spawn_effect = true
    self.first_shop = false
  end

  if self.first_shop then
    table.insert(Character_Cards, CharacterCardBuy{group = self.main, x = x + (#Character_Cards)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, i = #Character_Cards+1, parent = self,
      is_unlocked = true, cost = 5})
  elseif self.level >= PICK_SECOND_CHARACTER and #Character_Cards == 1 then
    table.insert(Character_Cards, CharacterCardBuy{group = self.main, x = x + (#Character_Cards)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, i = #Character_Cards+1, parent = self,
      is_unlocked = true, cost = 10})
  elseif self.level >= PICK_THIRD_CHARACTER and #Character_Cards == 2 then
    table.insert(Character_Cards, CharacterCardBuy{group = self.main, x = x + (#Character_Cards)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, i = #Character_Cards+1, parent = self,
      is_unlocked = true, cost = 15})
  end


  for i, card in ipairs(Character_Cards) do
    card.x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING)
  end


  --check how many of the same unit are in the party
  local max_count = self:most_copies_of_unit()
  Stats_Current_Run_Num_Same_Unit(max_count)
end

function BuyScreen:try_buy_unit(cost)
  if gold >= cost then
    self:gain_gold(-cost)
    gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.overlay_ui
    }
    self.first_shop = false
  end
end

function BuyScreen:most_copies_of_unit()
  local unit_counts = {}
  for _, unit in ipairs(self.units) do
    unit_counts[unit.character] = (unit_counts[unit.character] or 0) + 1
  end
  local max = 0
  local max_unit = nil
  for unit, count in pairs(unit_counts) do
    if count > max then
      max = count
    end
  end
  return max
end

function BuyScreen:try_roll_items(is_shop_start)
  self:set_items(self.shop_level, is_shop_start)
end


function BuyScreen:set_items(shop_level, is_shop_start)
  --clear item cards (UI elements)
  if self.items then for _, item in ipairs(self.items) do item:die() end end
  self.items = {}
  local shop_level = shop_level or 1
  local tier_weights = level_to_item_odds[shop_level]
  local item_1
  local item_2
  local item_3
  local all_items = {nil, nil, nil}
  local shop_already_rolled = false

  if self.first_shop or self.level == 1 then
    return
  end

  if not self.shop_item_data then
    self.shop_item_data = {}
  end

  if self.shop_item_data[1] or self.shop_item_data[2] or self.shop_item_data[3] then
    shop_already_rolled = true
  end

  if self.shop_item_data[1] and locked_state then
    item_1 = self.shop_item_data[1]
  elseif not self.reroll_shop then
    item_1 = self.shop_item_data[1]
  else
    item_1 = Get_Random_Item(shop_level, self.units, all_items)
  end

  all_items[1] = item_1

  if self.shop_item_data[2] and locked_state then
    item_2 = self.shop_item_data[2]
  elseif not self.reroll_shop then
    item_2 = self.shop_item_data[2]
  else
    item_2 = Get_Random_Item(shop_level, self.units, all_items)
  end

  all_items[2] = item_2

  if self.shop_item_data[3] and locked_state then
    item_3 = self.shop_item_data[3]
  elseif not self.reroll_shop then
    item_3 = self.shop_item_data[3]
  else
    item_3 = Get_Random_Item(shop_level, self.units, all_items)
  end

  all_items[3] = item_3

  --only reroll once (so, main menu and back in won't reroll again)
  self.reroll_shop = false

  --disable interaction with the reroll and lock buttons while rerolling
  self.reroll_button.interact_with_mouse = false
  self.lock_button.interact_with_mouse = false
  self.reroll_button:on_mouse_exit()
  self.lock_button:on_mouse_exit()
  self.reroll_button.selected = false
  self.lock_button.selected = false

  all_items = {item_1, item_2, item_3}
  self.shop_item_data = all_items

  local item_h = 50
  local item_w = 40

  local y = gh - (item_h / 2) - 10
  local x = gw/2 - 60

  -- Create items with staggered timing
  local transition_duration = is_shop_start and TRANSITION_DURATION + 0.2 or 0

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
    transition_duration = transition_duration + 0.5
    
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
    if all_items[i] then
      item_count = item_count + 1
      self.t:after((0.3 * (item_count-1)) + transition_duration, function()
        local item = ItemCard{group = self.ui, x = x + (i-1)*60, y = y, w = item_w, h = item_h, item = all_items[i], parent = self, i = i}
        table.insert(self.items, item)
      end)
    end
  end
  self.t:after((item_count * 0.3) + transition_duration, function()
    self.reroll_button.interact_with_mouse = true
    self.lock_button.interact_with_mouse = true
  end)

end




SteamFollowButton = Object:extend()
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
      slow_amount = 1
      music_slow_amount = 1
      run_time = 0
      gold = STARTING_GOLD
      passives = {}
      main_song_instance:stop()
      run_passive_pool = {
        'centipede', 'ouroboros_technique_r', 'ouroboros_technique_l', 'amplify', 'resonance', 'ballista', 'call_of_the_void', 'crucio', 'speed_3', 'damage_4', 'shoot_5', 'death_6', 'lasting_7',
        'defensive_stance', 'offensive_stance', 'kinetic_bomb', 'porcupine_technique', 'last_stand', 'seeping', 'deceleration', 'annihilation', 'malediction', 'hextouch', 'whispers_of_doom',
        'tremor', 'heavy_impact', 'fracture', 'meat_shield', 'hive', 'baneling_burst', 'blunt_arrow', 'explosive_arrow', 'divine_machine_arrow', 'chronomancy', 'awakening', 'divine_punishment',
        'assassination', 'flying_daggers', 'ultimatum', 'magnify', 'echo_barrage', 'unleash', 'reinforce', 'payback', 'enchanted', 'freezing_field', 'burning_field', 'gravity_field', 'magnetism',
        'insurance', 'dividends', 'berserking', 'unwavering_stance', 'unrelenting_stance', 'blessing', 'haste', 'divine_barrage', 'orbitism', 'psyker_orbs', 'psychosink', 'rearm', 'taunt', 'construct_instability',
        'intimidation', 'vulnerability', 'temporal_chains', 'ceremonial_dagger', 'homing_barrage', 'critical_strike', 'noxious_strike', 'infesting_strike', 'burning_strike', 'lucky_strike', 'healing_strike', 'stunning_strike',
        'silencing_strike', 'culling_strike', 'lightning_strike', 'psycholeak', 'divine_blessing', 'hardening', 'kinetic_strike',
      }
      self.max_units = MAX_UNITS
      system.save_state()
      main:add(BuyScreen'buy_screen')
      system.save_run()

      local new_run = Start_New_Run()
      main:go_to('buy_screen', new_run)
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

LevelMap = Object:extend()
LevelMap:implement(GameObject)
function LevelMap:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = false
  self.shape = Rectangle(self.x, self.y, 200, 60)
  self.text = Text({{text = '[fg]level map', font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.level = args.level
  self.parent = args.parent
  self.level_list = args.level_list

  self:build()
end

function LevelMap:build()
  self.levels = {}
  self.level_connections = {}
  self.level = self.parent.level

  for i = 1, 5 do
    local level = self.level + i - 1
    if level < NUMBER_OF_ROUNDS then
      table.insert(self.levels, 
        LevelMapLevel{group = self.group, x = self.x - 60 + (i-1)*30, y = self.y + 10, 
        line_color = (level == self.level) and yellow[2] or fg[0],
        fill_color = self.parent.level_list[level].color,
        level = level,
        parent = self
        })
    end
  end

  self.level_connections = {}
  for i = 1, #self.levels - 1 do
    if i == 1 and self.level > 1 then
      table.insert(self.level_connections, LevelMapConnection{group = main.current.ui, x = self.levels[i].x - 15, y = self.levels[i].y, w = 20, h = 3, color = fg[1]})
    end
    table.insert(self.level_connections, LevelMapConnection{group = main.current.ui, x = self.levels[i].x + 15, y = self.levels[i].y, w = 20, h = 3, color = fg[1]})
  end
  if self.level < NUMBER_OF_ROUNDS then
    table.insert(self.level_connections, LevelMapConnection{group = main.current.ui, x = self.levels[#self.levels].x + 15, y = self.levels[#self.levels].y, w = 20, h = 3, color = fg[1]})
  end
end

function LevelMap:update(dt)
  self:update_game_object(dt)
end

function LevelMap:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    --graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or bg[1])
    self.text:draw(self.x, self.y - 15, 0, 1, 1)
  graphics.pop()
end

function LevelMap:clear()
  for _, level in ipairs(self.levels) do
    level:die()
  end
  for _, connection in ipairs(self.level_connections) do
    connection:die()
  end
end

function LevelMap:reset()
  self:clear()
  self:build()
end

function LevelMap:die()
  self:clear()
  self.dead = true
end

LevelMapLevel = Object:extend()
LevelMapLevel:implement(GameObject)
function LevelMapLevel:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  self.shape = Circle(self.x, self.y, 10, 3)
  self.line_color = args.line_color
  self.fill_color = args.fill_color
  self.text_color = fg[0]
  self.level = args.level
  self.parent = args.parent

  if Is_Boss_Level(self.level) then
    self.is_boss = true
  end
end

function LevelMapLevel:update(dt)
  self:update_game_object(dt)
end

function LevelMapLevel:draw()
  if self.level == PICK_SECOND_CHARACTER or self.level == PICK_THIRD_CHARACTER then
    self.fill_color = yellow[0]
    self.text_color = bg[0]
    if self.level == self.parent.level then
      
    else

    end
  end

  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.circle(self.x, self.y, 9, self.fill_color)
    if self.is_boss then
      skull:draw(self.x, self.y, 0, 0.7, 0.7)
    else
      graphics.circle(self.x, self.y, 10, self.line_color, 3)
      graphics.print_centered(self.level, pixul_font, self.x, self.y +2, 0, 1, 1, 0, 0, self.text_color)
    end

  graphics.pop()
end

function LevelMapLevel:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.spring:pull(0.2, 200, 10)
  self.level_text = BuildLevelText(self.parent.level_list, 
    self.level, gw/2, LEVEL_TEXT_HOVER_HEIGHT )
end

function LevelMapLevel:on_mouse_exit()
  self.level_text:deactivate()
  self.level_text.dead = true
  self.level_text = nil
  self.selected = false
end

function LevelMapLevel:die()
  self.dead = true
end


LevelMapConnection = Object:extend()
LevelMapConnection:implement(GameObject)
function LevelMapConnection:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = true
  self.shape = Rectangle(self.x, self.y, args.w, args.h)
  self.color = args.color
end

function LevelMapConnection:update(dt)
  self:update_game_object(dt)
end

function LevelMapConnection:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.color)
  graphics.pop()
end

function LevelMapConnection:die()
  self.dead = true
end




Button = Object:extend()
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
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    if self.hold_button and self.press_time then
      graphics.set_line_width(5)
      graphics.set_color(fg[-5])
      graphics.arc('open', self.x, self.y, 0.6*self.shape.w, 0, math.remap(love.timer.getTime() - self.press_time, 0, self.hold_button, 0, 1)*2*math.pi)
      graphics.set_line_width(1)
    end
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.selected and fg[0] or _G[self.bg_color][0])
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
    if #self.parent.units == 0 then
      if not self.info_text then
        error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self.info_text = InfoText{group = main.current.ui}
        self.info_text:activate({
          {text = '[fg]cannot start the round with [yellow]0 [fg]units', font = pixul_font, alignment = 'center'},
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
      TransitionEffect{group = main.transitions, x = self.x, y = self.y, color = state.dark_transitions and bg[-2] or character_colors[random:table(self.parent.units).character], transition_action = function()
        print('starting arena')
        print(#self.parent.units)
        main:add(Arena'arena')

        local current_run = Collect_Save_Data_From_State(self.parent)
        main:go_to('arena', current_run)
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
    if self.parent.level == 1 then
      Create_Info_Text('cannot buy items in the first level', self)
    else
      self.parent:set_locked_state(not locked_state)
      glass_shatter:play{volume = 0.6}
      self.selected = true
      self.spring:pull(0.2, 200, 10)
      if locked_state then self.shape.w = 44
      else self.shape.w = 32 end
    end
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
      Create_Info_Text('cannot buy items in the first level', self)
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
        self.parent.shop_text:set_text{{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}


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
LooseItem:implement(GameObject)
function LooseItem:init(args)
  self:init_game_object(args)
  self.h = self.sy * 20
  self.w = self.sx * 20
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false

  if buyScreen then
    buyScreen.loose_inventory_item = self
  end
end

function LooseItem:update(dt)
  self:update_game_object(dt)
  self.x, self.y = camera:get_mouse_position()
  self.shape:move_to(self.x, self.y)
end


--duplicated from ItemPart (should be combined!!)
function LooseItem:draw()
  if self.item then
    local tier_color = item_to_color(self.item)
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

function LooseItem:die()
  self.dead = true
  if buyScreen then
    buyScreen.loose_inventory_item = nil
  end
end

PassiveCard = Object:extend()
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

  self.cost = self.item.cost
  -- putin item data?
  self.image = find_item_image(self.item)
  self.colors = self.item.colors

  self.tier_color = item_to_color(self.item)
  self.text = item_text[self.item]
  self.stats = self.item.stats

  self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)

  self.timeGrabbed = 0
  self.buyTimer = 0.2

  self:creation_effect()
  
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

function ItemCard:buy_item(slot)
  if not slot or not slot.addItem then 
    print("no slot to buy item")
    return
  end
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  slot:addItem(self.item)
  gold = gold - self.cost

  if self.cost > 10 then
    Stats_Current_Run_Over10Cost_Items_Purchased()
  end
  buyScreen:save_run()

  self.parent.shop_item_data[self.i] = nil
  self.parent.shop_text:set_text{{text = '[wavy_mid, fg]gold: [yellow]' .. gold, font = pixul_font, alignment = 'right'}}
  self:die()
end

function ItemCard:update(dt)
  self:update_game_object(dt)

  if self.parent:is(Arena) then return end

  if input.m1.pressed and self.colliding_with_mouse and not self.grabbed and not locked_state then

    -- Now, check if the purchase is possible.
    local firstEmptySlot = self.parent:get_first_available_inventory_slot()
    
    if gold >= self.cost and firstEmptySlot then
      -- SUCCESS: The player can afford it and has space.
      self.timeGrabbed = love.timer.getTime()
      self.grabbed = true
      self:remove_tooltip()
        
    elseif not firstEmptySlot then
      self:remove_tooltip()
      Create_Info_Text('no empty item slots - right click to sell', self)

    elseif gold < self.cost then
      self:remove_tooltip()
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
    if Active_Inventory_Slot and not Active_Inventory_Slot:hasItem() then
      self:buy_item(Active_Inventory_Slot)
    elseif love.timer.getTime() - self.timeGrabbed < self.buyTimer then
      --buy the item if the mouse is released within the buyTimer
      firstEmptySlot = self.parent:get_first_available_inventory_slot()
      if firstEmptySlot then
        self:buy_item(firstEmptySlot)
      end
    else
      self.x = self.origX
      self.y = self.origY
    end
  end

  if self.grabbed then
    self.x, self.y = camera:get_mouse_position()
  end

  self.shape:move_to(self.x, self.y)
end

function ItemCard:distance_from_slots()
  local slot_y = ITEM_SLOT_LOWER_BOUND
  if self.y < slot_y then
    return 0
  else
    return math.min(self.y - slot_y, ITEM_SLOT_DISTANCE) / ITEM_SLOT_DISTANCE
  end
end

function ItemCard:get_drawn_size()
  local max_h = ITEM_CARD_HEIGHT
  local min_h = ITEM_SLOT_SIZE

  local max_w = ITEM_CARD_WIDTH
  local min_w = ITEM_SLOT_SIZE

  local dist = self:distance_from_slots()
  local w = math.lerp(dist, min_w, max_w)
  local h = math.lerp(dist, min_h, max_h)


  return w, h
end

function ItemCard:draw()
  if self.item then
    local width = self.w
    local height = self.h
    local item_sx = 1
    local item_sy = 1

    if self.grabbed then
      width, height = self:get_drawn_size()
      item_sx = width / ITEM_CARD_WIDTH
      item_sy = height / ITEM_CARD_HEIGHT
    end
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

    graphics.rectangle(self.x, self.y, width, height, 6,6, bg[5])
    if self.colors then
      local num_colors = #self.colors
      local color_h = height / num_colors
      for i, color_name in ipairs(self.colors) do
        --make a copy of the color so we can change the alpha
        local color = _G[color_name]
        color = color[0]:clone()
        color.a = 0.6
        --find the y midpoint of the rectangle
        local y = (self.y - height/2) + ((i-1) * color_h) + (color_h/2)

        graphics.rectangle(self.x, y, width, color_h, 6, 6, color)
      end
    end
    --draw the locked color under the border
    if locked_state then
      local color = grey[0]:clone()
      color.a = 0.8
      graphics.rectangle(self.x, self.y, width, height, 6, 6, color)
    end
    graphics.rectangle(self.x, self.y, width, height, 6, 6, self.tier_color, 2)

    self.cost_text:draw(self.x + width/2, self.y - height/2)
    if self.image then
      self.image:draw(self.x, self.y, 0, item_sx, item_sy)
    end



    graphics.pop()
  end
end


function ItemCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)

  self:remove_tooltip()
  
  -- Create and position the new tooltip
  self.tooltip = ItemTooltip{
    group = main.current.ui,
    item = self.item,
    x = gw/2, 
    y = gh/2
  }
end


function ItemCard:on_mouse_exit()
  self.selected = false
  -- Deactivate the tooltip, which will play its closing animation
  self:remove_tooltip()
end


function ItemCard:die()
  self.dead = true
  self.cost_text = nil
  -- Ensure the tooltip is removed when the card dies
  self:remove_tooltip()
end

function ItemCard:remove_tooltip()
  if self.tooltip then
    self.tooltip:die()
    self.tooltip = nil
  end
end

CharacterIcon = Object:extend()
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
      {text = character_descriptions[self.character](1), font = pixul_font, alignment = 'center', height_multiplier = 2},
      {text = '[' .. (self.level == 3 and 'yellow' or 'light_bg') .. ']Lv.3 [' .. (self.level == 3 and 'fg' or 'light_bg') .. ']Effect - ' .. 
        (self.level == 3 and character_effect_names[self.character] or character_effect_names_gray[self.character]), font = pixul_font, alignment = 'center', height_multiplier = 1.25},
      {text = (self.level == 3 and character_effect_descriptions[self.character]() or character_effect_descriptions_gray[self.character]()), font = pixul_font, alignment = 'center'},
      -- {text = character_stats[self.character](1), font = pixul_font, alignment = 'center'},
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
function Create_Info_Text(text, parent)
  if not parent.info_text then
    error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    parent.info_text = InfoText{group = main.current.ui}
    parent.info_text:activate({
      {text = '[fg]' .. text, font = pixul_font, alignment = 'center'},
    }, nil, nil, nil, nil, 16, 4, nil, 2)
    parent.info_text.x, parent.info_text.y = gw/2, gh/2 + 10
  end
  parent.t:after(2, function() parent.info_text:deactivate(); parent.info_text.dead = true; parent.info_text = nil end, 'info_text')
end
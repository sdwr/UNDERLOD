GameState = Object:extend()
function GameState:init(...)
  self:import(...)
end

function GameState:save_run()
  system.save_run(self.level, self.level_list, self.loop, gold, self.units, self.max_units, self.passives, self.shop_level, self.shop_xp, self.shop_item_data)
end

function GameState:load_run()
  local run = system.load_run()
  self:import(run)
end


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

function BuyScreen:on_enter(from, level, level_list, loop, units, max_units, passives, shop_level, shop_xp, shop_item_data)
  self.gameState = GameState({
    level = level, 
    loop = loop, 
    units = units, 
    max_units = max_units, 
    passives = passives, 
    shop_level = shop_level, 
    shop_xp = shop_xp,
    shop_item_data = shop_item_data,
  })
  self.level = level
  self.level_list = level_list
  self.loop = loop
  self.units = units
  self.max_units = max_units
  self.passives = passives
  self.shop_level = level_to_shop_tier(level)
  self.shop_xp = shop_xp
  self.shop_item_data = shop_item_data

  if not locked_state then
    self.shop_item_data = {}
  end
  camera.x, camera.y = gw/2, gh/2

  --decide on enemies for every level here
  --if this is the first level
  if self.level == 1 or #self.level_list == 0 then
    self:roll_levels()
  end

  input:set_mouse_visible(true)

  --steam.friends.setRichPresence('steam_display', '#StatusFull')
  --steam.friends.setRichPresence('text', 'Shop - Level ' .. self.level)

  self.main = Group()
  self.effects = Group()
  self.ui = Group()
  self.ui_top = Group()
  self.tutorial = Group()

  self.lock_button = LockButton{group = self.main, x = gw/2 - 150, y = gh - 40, parent = self}


  self:try_roll_items()
  
  self.show_level_buttons = false
  
  self.shop_text = Text({{text = '[wavy_mid, fg]shop [fg]- gold: [yellow]' .. gold, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.items_text = Text({{text = '[wavy_mid, fg]items - Lv. ' .. self.shop_level, font = pixul_font, alignment = 'center'}}, global_text_tags)
  
  self.level_buttons = {}
  
  self:build_level_map()
  self:set_party()

  --builds characters from units?
  --open once at the start of the game
  if not Character_Cards or #Character_Cards == 0 then
    Character_Cards = {}
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.ui
    }
  --and again at round 5
  elseif self.level == PICK_SECOND_CHARACTER and #Character_Cards == 1 then
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.ui
    }
  elseif self.level == PICK_THIRD_CHARACTER and #Character_Cards == 2 then
    self.select_character_overlay = CharacterSelectOverlay{
      group = self.ui
    }
  end

  
  RerollButton{group = self.main, x = 90, y = gh - 20, parent = self}
  GoButton{group = self.main, x = gw - 90, y = gh - 20, parent = self}
  self.tutorial_button = Button{group = self.main, x = gw/2 + 129, y = 18, button_text = '?', fg_color = 'bg10', bg_color = 'bg', action = function()
    self.in_tutorial = true
    self.title_text = Text2{group = self.tutorial, x = gw/2, y = 35, lines = {{text = '[fg]WELCOME TO UNDERLOD!', font = fat_font, alignment = 'center'}}}
    self.tutorial_text = Text2{group = self.tutorial, x = 228, y = 160, lines = {
      {text = '[fg]You control a snake of multiple heroes that auto-attack nearby enemies.', font = pixul_font, height_multiplier = 1.2},
      {text = '[fg]You can steer the snake left or right by pressing [yellow]A/D[fg] or [yellow]left/right arrows[fg].', font = pixul_font, height_multiplier = 2.2},
      {text = '[fg]Combine the same heroes to level them up:', font = pixul_font, height_multiplier = 1.2},
      {text = '[fg]At [yellow]Lv.3[fg] heroes unlock special effects.', font = pixul_font, height_multiplier = 2.2},
      {text = '[fg]Hire heroes of the same classes to unlock class passives:', font = pixul_font, height_multiplier = 1.2},
      {text = '[fg]Each hero can have between [yellow]1 to 3[fg] classes.', font = pixul_font, height_multiplier = 2.2},
      {text = '[fg]You gain [yellow]1 interest per 5 gold[fg], up to a maximum of 5.', font = pixul_font, height_multiplier = 1.2},
      {text = "[fg]This means that saving above [yellow]25 gold[fg] doesn't yield more interest.", font = pixul_font, height_multiplier = 2.2},
      {text = "[yellow, wavy_mid]Good luck!", font = pixul_font, height_multiplier = 2.2, alignment = 'center'},
    }}


    self.close_button = Button{group = self.tutorial, x = gw - 20, y = 20, button_text = 'x', bg_color = 'bg', fg_color = 'bg10', action = function()
      trigger:after(0.01, function()
        self:quit_tutorial()
      end)
    end}
  end, mouse_enter = function(b)
    b.info_text = InfoText{group = main.current.ui, force_update = true}
    b.info_text:activate({
      {text = '[fg]guide', font = pixul_font, alignment = 'center'},
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

  if not self.in_tutorial and not self.paused then
    self.main:update(dt*slow_amount)
    self.effects:update(dt*slow_amount)
    self.ui:update(dt*slow_amount)
    self.ui_top:update(dt*slow_amount)
    if self.shop_text then self.shop_text:update(dt) end
    if self.items_text then self.items_text:update(dt) end
  else
    self.ui:update(dt*slow_amount)
    self.ui_top:update(dt*slow_amount)
    self.tutorial:update(dt*slow_amount)
  end

  if self.in_tutorial and input.escape.pressed then
    self:quit_tutorial()
  end

  if input['lctrl'].down or input['rctrl'].down then
    if input['g'].pressed then
      gold = gold + 100
      self.shop_text:set_text{{text = '[wavy_mid, fg]shop [fg]- [fg, nudge_down]gold: [yellow, nudge_down]' .. gold, font = pixul_font, alignment = 'center'}}
    end
    if input['u'].pressed then
      self.show_level_buttons = not self.show_level_buttons
    end
  end

  if input.escape.pressed and not self.transitioning and not self.in_tutorial then
    if not self.paused then
      open_options(self)
    else
      close_options(self)
    end
  end
end

function BuyScreen:save_run()
  system.save_run(self.level, self.level_list, self.loop, gold, self.units,  self.max_units, self.passives, self.shop_level, self.shop_xp, self.shop_item_data)
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
    local index = self:unit_first_available_inventory_slot(character.unit)
    if index then
      return character.items[index]
    end
  end
  return nil
end




function BuyScreen:quit_tutorial()
  self.in_tutorial = false
  self.tutorial_text.dead = true
  self.tutorial_text = nil
  self.title_text.dead = true
  self.title_text = nil
  self.close_button.dead = true
  self.close_button = nil
  self.tutorial_cards = {}
  self.tutorial:update(0)
end


function BuyScreen:draw()
  self.main:draw()
  self.effects:draw()
  if self.items_text then self.items_text:draw(gw/2 - 150, gh - 60) end

  if self.shop_text then self.shop_text:draw(64, 20) end

  if self.paused then graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent) end
  self.ui:draw()
  self.ui_top:draw()

  if self.in_tutorial then
    graphics.rectangle(gw/2, gh/2, 2*gw, 2*gh, nil, nil, modal_transparent_2)
    arrow:draw(gw/2 + 93, gh/2 - 30, 0, 0.4, 0.35)
    arrow:draw(gw/2 + 93, gh/2 - 10, 0, 0.4, 0.35)
  end
  self.tutorial:draw()
end

function BuyScreen:gain_gold(amount)
  gold = (gold + amount) or 0
  self.shop_text:set_text{{text = '[wavy_mid, fg]shop [fg]- [fg, nudge_down]gold: [yellow, nudge_down]' .. gold, font = pixul_font, alignment = 'center'}}
end

function BuyScreen:set_party()
  Kill_All_Cards()
  Character_Cards = {}
  local y = gh/2
  local x = gw/2
  --center single unit, otherwise start on the left
  if #self.units == 2 then
    x = gw/2 - CHARACTER_CARD_WIDTH/2 - CHARACTER_CARD_SPACING
  elseif #self.units == 3 then
    x = gw/2 - CHARACTER_CARD_WIDTH - CHARACTER_CARD_SPACING
  end

  for i, unit in ipairs(self.units) do
    table.insert(Character_Cards, CharacterCard{group = self.main, x = x + (i-1)*(CHARACTER_CARD_WIDTH+CHARACTER_CARD_SPACING), y = y, unit = unit, character = unit.character, i = i, parent = self})
    unit.spawn_effect = true
  end
end

function BuyScreen:try_roll_items()
  self:set_items(self.shop_level)
end


function BuyScreen:set_items(shop_level)
  --clear item cards (UI elements)
  if self.items then for _, item in ipairs(self.items) do item:die() end end
  self.items = {}
  local shop_level = shop_level or 1
  local tier_weights = level_to_item_odds[shop_level]
  local item_1
  local item_2
  local item_3
  local all_items = {}

  if locked_state and self.shop_item_data and self.shop_item_data[1] then
    item_1 = self.shop_item_data[1]
  else
    item_1 = Get_Random_Item(shop_level, self.units)
  end
  if locked_state and self.shop_item_data and self.shop_item_data[2] then
    item_2 = self.shop_item_data[2]
  else
    item_2 = Get_Random_Item(shop_level, self.units)
  end
  if locked_state and self.shop_item_data and self.shop_item_data[3] then
    item_3 = self.shop_item_data[3]
  else
    item_3 = Get_Random_Item(shop_level, self.units)
  end

  all_items = {item_1, item_2, item_3}
  self.shop_item_data = all_items

  local item_h = 50
  local item_w = 40

  local y = gh - (item_h / 2) - 10
  local x = gw/2 - 60
  for i, item in ipairs(all_items) do
    table.insert(self.items, ItemCard{group = self.ui, x = x + (i-1)*60, y = y, w = 40, h = 50,
                  item = item, parent = self, i = i})
  end
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
      main:go_to('buy_screen', 1, self.level_list, 0, {}, self.max_units, passives, 1, 0)
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

ProgressBar = Object:extend()
ProgressBar:implement(GameObject)
function ProgressBar:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = false
  self.progress = args.progress or 0
  self.max_progress = args.max_progress or 1
  self.color = args.color or fg[0]
  self.bgcolor = args.bgcolor or bg[1]
end

function ProgressBar:update(dt)
  self:update_game_object(dt)
end

function ProgressBar:draw()
  local progressPct = math.min(self.progress / self.max_progress, 1)
  local width = self.shape.w*progressPct
  local new_center_x = self.x - self.shape.w/2 + width/2
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, bg[1])
    graphics.rectangle(new_center_x, self.y, width, self.shape.h, 4, 4, self.color)
  graphics.pop()
end

function ProgressBar:set_progress(progress)
  self.progress = progress
end

function ProgressBar:increase_progress(amount)
  self.progress = self.progress + amount
  alert1:play{pitch = random:float(0.95, 1.05), volume = 1.1}
  self:create_particles()
end

function ProgressBar:create_particles()
  local progress_location = {x = self.x, y = self.y}
  progress_location.x = progress_location.x - self.shape.w/2 + self.shape.w*self.progress/self.max_progress
  for i = 1, 10 do
    HitParticle{group = main.current.effects, x = progress_location.x, y = progress_location.y, color = self.color}
  end

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
        main:go_to('arena', self.parent.level, self.parent.level_list, self.parent.loop, self.parent.units, self.parent.max_units, self.parent.passives, self.parent.shop_level, self.parent.shop_xp, self.parent.shop_item_data)
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
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.text:set_text{{text = '[fgm5]' .. tostring(locked_state and 'unlock' or 'lock'), font = pixul_font, alignment = 'center'}}
  self.spring:pull(0.2, 200, 10)
end


function LockButton:on_mouse_exit()
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
    self.text = Text({{text = '[bg10]reroll: [yellow]2', font = pixul_font, alignment = 'center'}}, global_text_tags)
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

  if (self.selected and input.m1.pressed) or input.r.pressed then
    if self.parent:is(BuyScreen) then
      if gold < 2 then
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
        self.parent:try_roll_items()
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self.selected = true
        self.spring:pull(0.2, 200, 10)
        gold = gold - 2
        self.parent.shop_text:set_text{{text = '[wavy_mid, fg]shop [fg]- [fg, nudge_down]gold: [yellow, nudge_down]' .. gold, font = pixul_font, alignment = 'center'}}

        buyScreen:save_run()
      end
    elseif self.parent:is(Arena) then
      if gold < 5 and not self.free_reroll then
        self.spring:pull(0.2, 200, 10)
        self.selected = true
        error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        if not self.info_text then
          self.info_text = InfoText{group = main.current.ui, force_update = true}
          self.info_text:activate({
            {text = '[fg]not enough gold', font = pixul_font, alignment = 'center'},
          }, nil, nil, nil, nil, 16, 4, nil, 2)
          self.info_text.x, self.info_text.y = gw/2, gh/2 + 10
        end
        self.t:after(2, function() self.info_text:deactivate(); self.info_text.dead = true; self.info_text = nil end, 'info_text')
      else
        ui_switch2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
        self.parent:set_passives(true)
        self.selected = true
        self.spring:pull(0.2, 200, 10)
        if not self.free_reroll then gold = gold - 5 end
        self.parent.shop_text:set_text{{text = '[fg, nudge_down]gold: [yellow, nudge_down]' .. gold, font = pixul_font, alignment = 'center'}}
        self.free_reroll = false
        self.text = Text({{text = '[bg10]reroll: [yellow]5', font = pixul_font, alignment = 'center'}}, global_text_tags)
      end
    end

    if input.r.pressed then self.selected = false end
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
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  if self.parent:is(BuyScreen) then
    self.text:set_text{{text = '[fgm5]reroll: 2', font = pixul_font, alignment = 'center'}}
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
  if self.parent:is(BuyScreen) then
    self.text:set_text{{text = '[bg10]reroll: [yellow]2', font = pixul_font, alignment = 'center'}}
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
  self.shape = Rectangle(self.x, self.y, self.sx * 20, self.sy * 20)
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

function LooseItem:draw()
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
  elseif self.cost <= 10 then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif self.cost <= 15 then
    pop1:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.4, 200, 10)
    for i = 1, 20 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  else
    gold3:play{pitch = random:float(0.95, 1.05), volume = 0.8}
    self.spring:pull(0.6, 200, 10)
    for i = 1, 30 do
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
  self.parent.shop_text:set_text{{text = '[wavy_mid, fg]shop [fg]- [fg, nudge_down]gold: [yellow, nudge_down]' .. gold, font = pixul_font, alignment = 'right'}}
  buyScreen:save_run()
  self:die()
end

function ItemCard:update(dt)
  self:update_game_object(dt)

  if self.parent:is(Arena) then return end

  local firstEmptySlot = self.parent:get_first_available_inventory_slot()
  if input.m1.pressed and self.colliding_with_mouse and gold >= self.cost and not locked_state and firstEmptySlot then
    if not self.grabbed then
      self.timeGrabbed = love.timer.getTime()
    end
    self.grabbed = true
    --remove item text when grabbed
    self:remove_info_text()
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


function ItemCard:draw()
  if self.item then
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

    graphics.rectangle(self.x, self.y, self.w, self.h, 6,6, bg[5])
    if self.colors then
      local num_colors = #self.colors
      local color_h = self.h / num_colors
      for i, color_name in ipairs(self.colors) do
        --make a copy of the color so we can change the alpha
        local color = _G[color_name]
        color = color[0]:clone()
        color.a = 0.6
        --find the y midpoint of the rectangle
        local y = (self.y - self.h/2) + ((i-1) * color_h) + (color_h/2)

        graphics.rectangle(self.x, y, self.w, color_h, 6, 6, color)
      end
    end
    --draw the locked color under the border
    if locked_state then
      local color = grey[0]:clone()
      color.a = 0.8
      graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, color)
    end
    graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, self.tier_color, 2)

    self.cost_text:draw(self.x + self.w/2, self.y - self.h/2)
    if self.image then
      self.image:draw(self.x, self.y)
    end



    graphics.pop()
  end
end


function ItemCard:create_info_text()
  self:remove_info_text()
  if self.item then
    self.info_text = InfoText{group = main.current.ui, force_update = true}
    self.info_text:activate(build_item_text(self.item), nil, nil, nil, nil, 16, 4, nil, 2)
    self.info_text.x, self.info_text.y = gw/2, gh/2 + ITEM_CARD_TEXT_HOVER_HEIGHT_OFFSET
  end
end

function ItemCard:remove_info_text()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
  end
  self.info_text = nil
end


function ItemCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
  self:create_info_text()
end


function ItemCard:on_mouse_exit()
  self.selected = false
  self:remove_info_text()
end


function ItemCard:die()
  self.dead = true
  self.cost_text = nil
  self:remove_info_text()
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
    graphics.print_centered(self.parent.cost, pixul_font, self.x + 0.5, self.y - 5, 0, 1, 1, 0, 0, _G[character_color_strings[self.character]][-5])
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
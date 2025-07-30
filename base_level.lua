BaseLevel = Arena:extend()

function BaseLevel:init(args)
  -- Call parent Arena init
  BaseLevel.super.init(self, args)
  
  -- Level-specific properties
  self.floor_items = {}
  self.door = nil
  self.floor_item_text = nil
  
  -- Buy character properties
  self.buy_character = nil
  self.character_items = {}
  self.character_options = {'swordsman', 'archer', 'laser'}
  
  -- Create door for this level
  self:create_door()
end

function BaseLevel:create_door()
  -- Create door on the right side of the arena
  if self.door then
    self.door.dead = true
    self.door = nil
  end

  self.door = Door{
    type = 'door',
    group = self.main,
    x = gw - 50 + self.offset_x,
    y = gh/2 + self.offset_y,
    width = 40,
    height = 80,
    parent = self
  }
end

function BaseLevel:open_door()

  if self.door then
    self.door:open()
  end
end

--
function BaseLevel:level_clear()
  spawn_mark2:play{pitch = 1, volume = 0.8}
  Helper.Unit:update_units_with_combat_data(self)
  
  self.t:after(1, function()
    Helper.Unit:resurrect_all_teams()
    Helper.Unit:heal_all_teams_to_full()
  end)

  self.t:after(DOOR_OPEN_DELAY, function() self:open_door() end)
  main.current:increase_level()
  -- Create 3 floor items for selection
  if LEVEL_TO_PERKS[self.level] then
    self:create_perk_floor_items()
  else
    self:create_floor_items()
  end
  local num_troops = #self.units
  self:create_buy_character(NUMBER_OF_TROOPS_TO_CHARACTER_COST[num_troops])
end

function BaseLevel:create_floor_items()
  self.floor_items = {}
  
  -- Generate 3 random items using the new V2 system
  local items = {}
  for i = 1, 3 do
    local tier = LEVEL_TO_TIER(self.level or 1)
    local item = create_random_item(tier)
    if item then
      table.insert(items, item)
    end
  end
  
  -- Position items on the floor
  local positions = {
    {x = gw/2 - 100, y = gh/2},
    {x = gw/2, y = gh/2},
    {x = gw/2 + 100, y = gh/2}
  }
  
  if not self.floor_item_text then
    self.floor_item_text = Text2{group = self.floor, x = gw/2 + self.offset_x, y =ARENA_TITLE_TEXT_Y + self.offset_y, lines = {{text = '[wavy_mid, cbyc3]Buy an item:', font = fat_font, alignment = 'center'}}}
  end

  for i, item in ipairs(items) do
    if positions[i] then
      self.t:after(ITEM_SPAWN_DELAY_INITAL + i*ITEM_SPAWN_DELAY_OFFSET, function()
        local floor_item = FloorItem{
          group = self.floor,
          main_group = self.main,
          x = positions[i].x + self.offset_x,
          y = positions[i].y + self.offset_y,
          item = item,
          parent = self
        }
        table.insert(self.floor_items, floor_item)
      end)
    end
  end
end

function BaseLevel:create_perk_floor_items()
  self.floor_items = {}
  
  -- Get perk choices
  local perk_choices = Get_Random_Perk_Choices(self.perks or {})
  
  -- Position perks on the floor (same positions as items)
  local positions = {
    {x = gw/2 - 80, y = gh/2},
    {x = gw/2, y = gh/2},
    {x = gw/2 + 80, y = gh/2}
  }
  
  if not self.floor_item_text then
    self.floor_item_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = ARENA_TITLE_TEXT_Y + self.offset_y, lines = {{text = '[wavy_mid, cbyc3]Choose a perk:', font = fat_font, alignment = 'center'}}}
  end

  for i, perk in ipairs(perk_choices) do
    if positions[i] then
      self.t:after(ITEM_SPAWN_DELAY_INITAL + i*ITEM_SPAWN_DELAY_OFFSET, function()
        local floor_item = FloorItem{
          group = self.floor,
          main_group = self.main,
          x = positions[i].x + self.offset_x,
          y = positions[i].y + self.offset_y,
          perk = perk,
          is_perk_selection = true,
          parent = self
        }
        table.insert(self.floor_items, floor_item)
      end)
    end
  end
end

function BaseLevel:create_buy_character(cost)
  if self.buy_character then
    self.buy_character.dead = true
    self.buy_character = nil
  end

  self.buy_character = BuyCharacter{
    group = self.floor,
    main_group = self.main,
    x = 50 + self.offset_x,
    y = gh/2 + self.offset_y,
    cost = cost,
    parent = self,
    interaction_activation_sound = gold2,
  }
end

function BaseLevel:on_buy_character_triggered()
  if gold < self.buy_character.cost then
    Create_Info_Text('not enough gold', self.buy_character)
    return
  end

  self:purchase_character()
end

function BaseLevel:purchase_character()
  gold = gold - self.buy_character.cost
  self.gold_counter:update_display()

  self:create_character_selection()
end

function BaseLevel:create_character_selection()
  self.character_items = {}
  
  local positions = {
    {x = gw/2 - 80 + self.offset_x, y = gh/2 + self.offset_y},
    {x = gw/2 +   0 + self.offset_x, y = gh/2 + self.offset_y},
    {x = gw/2 + 80 + self.offset_x, y = gh/2 + self.offset_y}
  }
  
  for i, character in ipairs(self.character_options) do
    if positions[i] then
      local floor_item = FloorItem{
        group = self.floor,
        main_group = self.main,
        x = positions[i].x,
        y = positions[i].y,
        character = character,
        is_character_selection = true,
        parent = self,
        interaction_activation_sound = ui_modern_hover,
      }
      table.insert(self.character_items, floor_item)
    end
  end
end

function BaseLevel:remove_all_character_items()
  for _, item in ipairs(self.character_items) do
    item:die()
  end
  self.character_items = {}
end

function BaseLevel:remove_all_floor_items()
  if self.floor_item_text then
    self.floor_item_text.dead = true
    self.floor_item_text = nil
  end
  if self.floor_items then
    for _, item in ipairs(self.floor_items) do
      item:die()
    end
    self.floor_items = {}
  end
end

function BaseLevel:on_character_selected(character)
  main.current:replace_first_unit(character)
  self:remove_all_character_items()
  -- Override this in subclasses to handle character selection
end

function BaseLevel:quit()
  if self.died then return end

  self.quitting = true
  if IS_DEMO and self.level == DEMO_END_LEVEL then
    print('end of demo')
    self:demo_end()
  else
    print('beat level')
    if Is_Boss_Level(self.level) then
      if self.level == 6 then USER_STATS.stompy_defeated = USER_STATS.stompy_defeated + 1
      elseif self.level == 11 then USER_STATS.dragon_defeated = USER_STATS.dragon_defeated + 1
      elseif self.level == 16 then USER_STATS.heigan_defeated = USER_STATS.heigan_defeated + 1
      elseif self.level == 21 then USER_STATS.final_boss_defeated = USER_STATS.final_boss_defeated + 1
      end
    end
    system.save_stats()
    Check_All_Achievements()

    if not self.arena_clear_text then self.arena_clear_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = gh/2 - 48 + self.offset_y, lines = {{text = '[wavy_mid, cbyc]arena clear!', font = fat_font, alignment = 'center'}}} end
    self:gain_gold(ARENA_TRANSITION_TIME)
    self.t:after(ARENA_TRANSITION_TIME, function()
      self.slow_transitioning = true
      self.t:tween(0.7, self, {main_slow_amount = 0}, math.linear, function() self.main_slow_amount = 0 end)
    end)
      self.t:after(3, function()
      self:transition()
    end, 'transition')
  end
end

function BaseLevel:transition()
  self.transitioning = true
  ui_transition2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  
  -- Check if this level grants a perk
  if LEVEL_TO_PERKS[self.level] then
    -- Create perk floor items instead of overlay
    self:create_perk_floor_items()
    return
  end
  
  -- Normal transition to buy screen
  TransitionEffect{group = main.transitions, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, color = state.dark_transitions and bg[-2] or self.color, transition_action = function(t)

    -- Update units with combat data before transitioning
    self:update_units_with_combat_data()

    Reset_Global_Proc_List()
    slow_amount = 1
    music_slow_amount = 1
    main:add(BuyScreen'buy_screen')
    local save_data = Collect_Save_Data_From_State(self)

    save_data.level = save_data.level + 1
    save_data.reroll_shop = true
    save_data.times_rerolled = 0

    Stats_Level_Complete()
    Stats_Max_Gold()

    system.save_run(save_data)

    main:go_to('buy_screen', save_data)

  end, nil}
end

function BaseLevel:destroy()
  -- Clean up level-specific resources
  self:remove_all_floor_items()
  self:remove_all_character_items()
  
  if self.door then
    self.door.dead = true
    self.door = nil
  end
  
  -- Call parent destroy
  BaseLevel.super.destroy(self)
end 
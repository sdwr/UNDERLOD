CombatLevel = BaseLevel:extend()

function CombatLevel:init(args)
  CombatLevel.super.init(self, args)
end

function CombatLevel:purchase_character()
  CombatLevel.super.purchase_character(self)
  --hide the floor items and text while the character is being purchased
  self:remove_all_floor_items()
end

function CombatLevel:on_character_selected(character)
  CombatLevel.super.on_character_selected(self, character)

  main.current:add_unit(character)
  self:remove_tutorial_text()
  --self:create_floor_items()

  self.t:after(1, function()
    self:open_door()
  end)
end

function CombatLevel:level_clear()
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

function CombatLevel:create_floor_items()
  self.floor_items = {}
  
  -- Generate 3 random items using the new V2 system
  if not self.items then
    self.items = {}
    for i = 1, 3 do
      local tier = LEVEL_TO_TIER(self.level or 1)
      local item = nil
      if self.level == 1 then
        item = create_random_item(tier, 'common')
      else
        item = create_random_item(tier)
      end
      if item then
        table.insert(self.items, item)
      end
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

  for i, item in ipairs(self.items) do
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

function CombatLevel:create_perk_floor_items()
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
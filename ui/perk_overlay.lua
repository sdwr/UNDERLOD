-- Perk selection overlay
PerkOverlay = Object:extend()
PerkOverlay:implement(GameObject)

function PerkOverlay:init(args)
  self:init_game_object(args)
  self.cards = {}
  self.player_perks = args.player_perks or {}
  
  main.current.choosing_perks = true
  
  -- Freeze the arena while perk overlay is active
  Helper.Unit:disable_unit_controls()
  -- Make overlay (opaque bg)
  

  -- Get perk choices
  self.perk_choices = Get_Random_Perk_Choices(self.player_perks)
  
  -- Dimensions for the cards (same as item cards)
  local w = CARD_WIDTH
  local w_between = 30
  local h = CARD_HEIGHT

  local x1 = gw/2 - w - w_between
  local x2 = gw/2
  local x3 = gw/2 + w + w_between
  local card_y = gh/2

  -- Create perk cards
  for i, perk in ipairs(self.perk_choices) do
    local x = x1 + (i-1) * (w + w_between)
    self.t:after(0.3 * i, function()
      self.cards[i] = PerkCard{
        group = self.group, 
          x = x, y = card_y, w = w, h = h, 
          perk = perk, parent = self, i = i,
          interact_with_mouse = false -- Disable interaction initially
        }
    end)
  end

  -- Calculate when all cards are created and enable interactions
  local last_card_time = 0.3 * #self.perk_choices
  local enable_time = last_card_time + 0.2 -- Add small buffer after last card
  
  -- Disable clicking for the overlay and cards during creation
  self.interact_with_mouse = false
  self.t:after(enable_time, function() 
    self.interact_with_mouse = true
    -- Enable interaction for all cards
    for _, card in ipairs(self.cards) do
      if card and not card.dead then
        card.interact_with_mouse = true
      end
    end
  end)
end

function PerkOverlay:on_perk_selected(perk_key)

  local new_perk = Create_Perk(perk_key, 1) -- Start at level 1
  table.insert(main.current.perks, new_perk)
  Save_Run_From_Current()
  ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}

  self:destroy_unbought_perks()
  self.t:after(1, function()
    self:die()
  end)
  
  -- Continue to buy screen after perk selection
  main.current:transition_to_next_level_buy_screen(0)
end

function PerkOverlay:destroy_unbought_perks()

  for _, card in ipairs(self.cards) do
    if not card.is_bought then
      card:die()
    end
  end
end

function PerkOverlay:create_tutorial_text()
  self:remove_tutorial_text()
  local lines = {
    {text = '[wavy_mid, fg]Choose a Perk', font = fat_font, alignment = 'center'},
  }
  self.tutorial_text = Text2{group = self.floor, x = gw/2, y = ARENA_TITLE_TEXT_Y, lines = lines}
end

function PerkOverlay:remove_tutorial_text()
  if self.tutorial_text then
    self.tutorial_text.dead = true
    self.tutorial_text = nil
  end
end

function PerkOverlay:draw()
  --pass
end

function PerkOverlay:update(dt)
  self:update_game_object(dt)
end

function PerkOverlay:die(index_selected)
  self:remove_tutorial_text()
  self.dead = true
  
  Helper.Unit:enable_unit_controls()
  
  for i, card in ipairs(self.cards) do 
    if card and not card.dead then
      card.dead = true
      card:die()
    end
  end
end


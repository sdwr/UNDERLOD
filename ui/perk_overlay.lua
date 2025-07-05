-- Perk selection overlay
PerkOverlay = Object:extend()
PerkOverlay:implement(GameObject)

function PerkOverlay:init(args)
  self:init_game_object(args)
  self.cards = {}
  self.player_perks = args.player_perks or {}
  
  main.current.choosing_perks = true

  -- Make overlay (opaque bg)
  self.overlay = PerkOverlayBackground{
    group = self.group,
    x = gw/2,
    y = gh/2,
    w = gw,
    h = gh
  }

  -- Get perk choices
  self.perk_choices = Get_Random_Perk_Choices(self.player_perks)
  
  -- Dimensions for the cards
  local w = 100
  local w_between = 30
  local h = 140

  local x1 = gw/2 - w - w_between
  local x2 = gw/2
  local x3 = gw/2 + w + w_between
  local card_y = gh/2

  -- Create perk cards
  for i, perk in ipairs(self.perk_choices) do
    local x = x1 + (i-1) * (w + w_between)
    self.cards[i] = PerkCard{
      group = self.group, 
      x = x, y = card_y, w = w, h = h, 
      perk = perk, parent = self, i = i
    }
  end

  -- Disable clicking for the first .25 seconds
  self.interact_with_mouse = false
  self.t:after(0.25, function() self.interact_with_mouse = true end)
end

function PerkOverlay:draw()
  -- Title text - made larger and positioned to draw over background
  graphics.set_color(fg[0])
  graphics.print_centered("Choose a Perk", fat_font, gw/2, gh/2 - 120, 0, 1.5, 1.5, nil, nil, fg[0])
end

function PerkOverlay:update(dt)
  self:update_game_object(dt)
end

function PerkOverlay:die(index_selected)
  self.dead = true
  self.overlay:die()
  for i, card in ipairs(self.cards) do 
    local not_selected = index_selected ~= i
    card:die(not_selected) 
  end
end

-- Overlay background
PerkOverlayBackground = Object:extend()
PerkOverlayBackground:implement(GameObject)

function PerkOverlayBackground:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
end

function PerkOverlayBackground:draw()
  local color = bg[1]:clone()
  color.a = 0.8
  graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, color)
end

function PerkOverlayBackground:update(dt)
  self:update_game_object(dt)
end

function PerkOverlayBackground:die()
  self.dead = true
  main.current.choosing_perks = false
end

-- Perk card
PerkCard = Object:extend()
PerkCard:implement(GameObject)

function PerkCard:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.perk = args.perk
  
  -- Initialize properties used in tweening
  self.sx, self.sy = 1, 1
  self.plus_r = 0
  
  -- Create perk icon (placeholder for now)
  self.perk_icon = PerkIcon{
    group = self.group, 
    x = self.x, y = self.y - 30, 
    perk = self.perk, parent = self
  }
  
  -- Create perk name text above the icon
  self.perk_name_text = Text2{
    group = self.group,
    x = self.x, y = self.y - 50,
    lines = {{text = '[fg]' .. self.perk.name, font = pixul_font, alignment = 'center'}}
  }

  local desc_text = {}
  local desc_lines = self:wrap_text(self.perk.description, self.w - 10, pixul_font)
  for i, line in ipairs(desc_lines) do
    table.insert(desc_text, {text = '[fg2]' .. line, font = pixul_font, alignment = 'center'})
  end

  self.desc_text = Text(desc_text, global_text_tags)
  
  self.spring:pull(0.2, 200, 10)
end

function PerkCard:update(dt)
  self:update_game_object(dt)

  if (self.selected and input.m1.pressed and self.parent.interact_with_mouse) then
    -- Add the perk to the player's perks
    local perk_key = nil
    for key, def in pairs(PERK_DEFINITIONS) do
      if def.name == self.perk.name then
        perk_key = key
        break
      end
    end
    
    if perk_key then
      local new_perk = Create_Perk(perk_key, 1) -- Start at level 1
      table.insert(main.current.perks, new_perk)
      
      ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
      self.parent:die(self.i)
      
      -- Continue to buy screen after perk selection
      main.current:on_perk_selected()
    end
  end
end

function PerkCard:select()
  self.selected = true
  self.spring:pull(0.2, 200, 10)
  self.t:every_immediate(1.4, function()
    if self.selected then
      self.t:tween(0.7, self, {sx = 0.97, sy = 0.97, plus_r = -math.pi/32}, math.linear, function()
        self.t:tween(0.7, self, {sx = 1.03, sy = 1.03, plus_r = math.pi/32}, math.linear, nil, 'pulse_1')
      end, 'pulse_2')
    end
  end, nil, nil, 'pulse')
end

function PerkCard:unselect()
  self.selected = false
  self.t:cancel'pulse'
  self.t:cancel'pulse_1'
  self.t:cancel'pulse_2'
  self.t:tween(0.1, self, {sx = 1, sy = 1, plus_r = 0}, math.linear, function() self.sx, self.sy, self.plus_r = 1, 1, 0 end, 'pulse')
end

function PerkCard:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    if self.selected then
      graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, bg[0])
    else
      graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, bg[2])
    end
    graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, bg[1], 5)
    
    -- Draw perk description text on the card
    
    self.desc_text:draw(self.x, self.y + 15)

    
    -- Draw rarity indicator
    local rarity_color = self:get_rarity_color(self.perk.rarity)
    graphics.set_color(rarity_color)
    graphics.rectangle(self.x, self.y + self.h/2 + 20, self.w - 10, 3, 1, 1, rarity_color)
    
  graphics.pop()
end

function PerkCard:wrap_text(text, max_width, font)
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

function PerkCard:get_rarity_color(rarity)
  if rarity == "common" then
    return fg[0]
  elseif rarity == "uncommon" then
    return green[0]
  elseif rarity == "rare" then
    return blue[0]
  else
    return fg[0]
  end
end



function PerkCard:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self:select()
  self.perk_icon.spring:pull(0.1, 200, 10)
  self.perk_name_text.spring:pull(0.1, 200, 10)
end

function PerkCard:on_mouse_exit()
  self:unselect()
  self.perk_icon.spring:pull(0.1, 200, 10)
  self.perk_name_text.spring:pull(0.1, 200, 10)
end

function PerkCard:die(not_selected)
  self.dead = true
  if not_selected then
    self.t:tween(0.2, self, {sx = 0, sy = 0}, math.linear)
  end
  
  -- Clean up text objects
  if self.perk_name_text then
    self.perk_name_text.dead = true
  end
  
  self.dead = true
end

-- Perk icon (placeholder)
PerkIcon = Object:extend()
PerkIcon:implement(GameObject)

function PerkIcon:init(args)
  self:init_game_object(args)
  self.perk = args.perk
  self.spring:pull(0.2, 200, 10)
end

function PerkIcon:update(dt)
  self:update_game_object(dt)
end

function PerkIcon:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
    -- Placeholder icon - just a colored circle
    local color = self.parent:get_rarity_color(self.perk.rarity)
    graphics.circle(self.x, self.y, 15, color)
  graphics.pop()
end 
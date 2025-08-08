PerkCard = BaseCard:extend()

function PerkCard:init(args)
  -- Set up perk-specific properties before calling super
  self.perk = args.perk
  args.image = self:find_perk_image(self.perk)
  args.colors = nil -- Perks don't use color bands
  args.tier_color = self:get_rarity_color(self.perk.rarity)
  args.name = self.perk.name
  
  -- Call parent constructor
  PerkCard.super.init(self, args)
  
  -- Perk-specific properties
  self.plus_r = 0 -- For pulsing animation
  self.selected = false
  self.description_tooltip = nil
  
  -- Create name text (wrapped, positioned below image)
  self:create_name_text()
  
  -- Play creation effect
  self:creation_effect()
end

function PerkCard:find_perk_image(perk)
  return find_perk_image(perk)
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

function PerkCard:create_name_text()
  if not self.perk or not self.perk.name then return end
  
  -- Wrap the name text to fit within the card width
  local wrapped_lines = self:wrap_text(self.perk.name, self.w - 10, pixul_font)
  
  -- Create text definitions for each line
  local text_definitions = {}
  for _, line in ipairs(wrapped_lines) do
    table.insert(text_definitions, {text = '[fg]' .. line, font = pixul_font, alignment = 'center'})
  end
  
  self.bottom_text = Text(text_definitions, global_text_tags)
end

function PerkCard:update(dt)
  PerkCard.super.update(self, dt)
  
  if self.dead then return end
  
  -- Handle perk selection on click
  if (self.selected and input.m1.pressed and self.parent.interact_with_mouse) then
    -- Find perk key and notify parent
    local perk_key = nil
    for key, def in pairs(PERK_DEFINITIONS) do
      if def.name == self.perk.name then
        perk_key = key
        break
      end
    end
    
    if perk_key then
      self.is_bought = true
      self:buy_animation()
      self.parent:on_perk_selected(perk_key)
    end
  end
end

function PerkCard:buy_animation()
  for i = 1, 10 do
    self.t:after(0.05 * i, function()
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color, size = 10}
    end)
  end
  self.t:tween(0.4, self, {sx = 0, sy = 0}, math.linear, function()
    self:die()
  end)
end

function PerkCard:draw()
  if not self.perk then return end
  
  -- Use BaseCard drawing with custom scaling and rotation for selection pulse
  local original_sx, original_sy = self.sx, self.sy
  
  if self.selected then
    -- Apply pulsing effect
    self.sx = self.sx * self.spring.x
    self.sy = self.sy * self.spring.x
    
    graphics.push(self.x, self.y, self.plus_r, self.sx, self.sy)
    self:draw_base_card()
    graphics.pop()
    
    -- Reset for next frame
    self.sx, self.sy = original_sx, original_sy
  else
    -- Normal drawing
    self:draw_base_card()
  end
end

function PerkCard:on_mouse_enter()
  PerkCard.super.on_mouse_enter(self)
  self:select_animation()
  self:show_description_tooltip()
end

function PerkCard:on_mouse_exit()
  PerkCard.super.on_mouse_exit(self)
  self:unselect_animation()
  self:hide_description_tooltip()
end

function PerkCard:select_animation()
  -- Start pulsing animation
  self.t:every_immediate(1.4, function()
    if self.selected then
      self.t:tween(0.7, self, {sx = 0.97, sy = 0.97, plus_r = -math.pi/32}, math.linear, function()
        self.t:tween(0.7, self, {sx = 1.03, sy = 1.03, plus_r = math.pi/32}, math.linear, nil, 'pulse_1')
      end, 'pulse_2')
    end
  end, nil, nil, 'pulse')
end

function PerkCard:unselect_animation()  
  -- Stop pulsing animation
  self.t:cancel'pulse'
  self.t:cancel'pulse_1'
  self.t:cancel'pulse_2'
  self.t:tween(0.1, self, {sx = 1, sy = 1, plus_r = 0}, math.linear, function() 
    self.sx, self.sy, self.plus_r = 1, 1, 0 
  end, 'pulse')
end

function PerkCard:show_description_tooltip()
  if self.description_tooltip then return end
  if not self.perk or not self.perk.description then return end
  
  -- Create wrapped description lines
  local desc_lines = self:wrap_text(self.perk.description, 200, pixul_font)
  local text_definitions = {}
  for _, line in ipairs(desc_lines) do
    table.insert(text_definitions, {text = '[fg2]' .. line, font = pixul_font, alignment = 'center'})
  end
  
  -- Create InfoText at default position
  self.description_tooltip = InfoText{group = self.group, force_update = false}
  self.description_tooltip:activate(text_definitions, nil, nil, nil, nil, 16, 4, nil, 2)
  
  local pos = Get_UI_Popup_Position('perk_overlay')
  self.description_tooltip.x = pos.x
  self.description_tooltip.y = pos.y
end

function PerkCard:hide_description_tooltip()
  if self.description_tooltip then
    self.description_tooltip:deactivate()
    self.description_tooltip:die()
    self.description_tooltip.dead = true
    self.description_tooltip = nil
  end
end

function PerkCard:die(not_selected)
  -- Handle death animation if not selected
  if not_selected then
    self.t:tween(0.2, self, {sx = 0, sy = 0}, math.linear)
  end
  
  -- Clean up tooltip
  self:hide_description_tooltip()
  
  -- Clean up animations
  self.t:cancel'pulse'
  self.t:cancel'pulse_1'
  self.t:cancel'pulse_2'
  
  -- Call parent die method
  PerkCard.super.die(self)
end
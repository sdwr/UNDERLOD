-- Base class for all card UI elements (ItemCard, PerkCard, etc.)
BaseCard = Object:extend()
BaseCard:implement(GameObject)

function BaseCard:init(args)
  self:init_game_object(args)
  
  -- Card dimensions
  self.w = args.w or CARD_WIDTH
  self.h = args.h or CARD_HEIGHT
  
  -- Visual properties
  self.image = args.image
  self.tier_color = args.tier_color or grey[0]
  self.colors = args.colors
  self.name = args.name
  
  -- Mouse interaction
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = default_to(args.interact_with_mouse, true)
  self.selected = false
  
  -- Text content (to be set by subclasses)
  self.title_text = nil
  self.bottom_text = nil
  self.cost_text = nil
  
  -- Animation effects
  self.creation_effect_played = false
end

function BaseCard:wrap_text(text, max_width, font)
  local lines = {}
  local current_line = ''
  -- Prevent errors if text is nil
  if not text then return {} end
  
  for word in text:gmatch("([^ ]+)") do
      local test_line = current_line == '' and word or current_line .. ' ' .. word
      
      if font:get_text_width(test_line) > max_width then
          if current_line == '' then
              -- If single word is too long, just use it as is
              table.insert(lines, word)
          else
              -- Add current line and start new one with current word
              table.insert(lines, current_line)
              current_line = word
          end
      else
          current_line = test_line
      end
  end
  
  -- Add remaining text
  if current_line ~= '' then
      table.insert(lines, current_line)
  end
  
  return lines
end

function BaseCard:creation_effect()
  if self.creation_effect_played then return end
  self.creation_effect_played = true
  
  local cost = self.cost or 0
  
  if cost <= 5 then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 10 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif cost <= 10 then
    pop2:play{pitch = random:float(0.95, 1.05), volume = 0.7}
    self.spring:pull(0.2, 200, 10)
    for i = 1, 20 do
      HitParticle{group = main.current.effects, x = self.x, y = self.y, color = self.tier_color}
    end
  elseif cost <= 15 then
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

function BaseCard:draw_base_card()
  local width = self.w
  local height = self.h
  
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

  -- Main background
  graphics.rectangle(self.x, self.y, width, height, 6, 6, bg[5])
  
  -- Set colors (like FloorItem) - only on top half
  if self.colors then
    local num_colors = #self.colors
    local top_half_height = height / 2 -- Only use top half
    local color_h = top_half_height / num_colors
    for i, color_name in ipairs(self.colors) do
      local color = _G[color_name] or _G['brown']
      color = color[0]:clone()
      color.a = 0.6
      local y = (self.y - height/2) + ((i-1) * color_h) + (color_h/2)
      graphics.rectangle(self.x, y, width, color_h, 6, 6, color)
    end
  end
  
  -- Draw the locked color under the border if locked
  if locked_state then
    local color = grey[0]:clone()
    color.a = 0.8
    graphics.rectangle(self.x, self.y, width, height, 6, 6, color)
  end
  
  -- Border
  graphics.rectangle(self.x, self.y, width, height, 6, 6, self.tier_color, 2)

  -- Cost text at top
  if self.cost_text then
    self.cost_text:draw(self.x + width/2 - 5, self.y - height/2 + 10)
  end
  
  -- Image in center-top area
  if self.image then
    self.image:draw(self.x, self.y - 20, 0, 0.8, 0.8)
  end
  
  -- Bottom text (stats, description, etc.)
  if self.bottom_text then
    local top_section_bottom = self.y + 7 -- The center of the card (boundary between top and bottom)
    local bottom_text_y = top_section_bottom + self.bottom_text.h/2 -- Position just below the top section with small padding
    self.bottom_text:draw(self.x, bottom_text_y)
  end

  graphics.pop()
end

function BaseCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end

function BaseCard:on_mouse_exit()
  self.selected = false
end

function BaseCard:update(dt)
  self:update_game_object(dt)
  
  if self.dead then return end
  
  -- Update shape position
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
end

function BaseCard:die()
  self.dead = true
  
  -- Clean up text objects
  if self.title_text then
    self.title_text.dead = true
    self.title_text = nil
  end
  if self.bottom_text then
    self.bottom_text.dead = true
    self.bottom_text = nil
  end
  if self.cost_text then
    self.cost_text.dead = true
    self.cost_text = nil
  end
end
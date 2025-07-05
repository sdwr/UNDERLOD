Active_Inventory_Slot = nil
Character_Cards = {}

--still have duplicate text bug 
--hack workaround: add all card texts to a global table
--and clear them all when refreshing

--looks like it only happens after losing/restarting a run,
--where the old cards are not killed until the new ones are created

ALL_CARD_TEXTS = {}

CharacterCardBuy = Object:extend()
CharacterCardBuy:implement(GameObject)
function CharacterCardBuy:init(args)
  self:init_game_object(args)
  self.parent = args.parent
  self.background_color = args.background_color or bg[0]
  
  self.unlock_level = args.unlock_level or 1
  self.is_unlocked = args.is_unlocked or false
  self.cost = args.cost or 10

  self.title_string = 'Buy new unit'
  self.text_color = yellow[0]
  self.text_color_string = 'yellow'

  self.text_color_unavailable = grey[0]
  self.text_color_unavailable_string = 'grey'

  self.buy_icon_string = '+'
  self.unavailable_string = 'Unlocks at level ' .. self.unlock_level 

  self.cost_string = 'Cost: ' .. self.cost


  
  self.w = CHARACTER_CARD_WIDTH
  self.h = CHARACTER_CARD_HEIGHT
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  
  self.interact_with_mouse = true

  self:initText()
  
  if self.spawn_effect then SpawnEffect{group = main.current.effects, x = self.x, y = self.y, color = self.character_color} end
end

function CharacterCardBuy:initText()
  local text_color_string = self.text_color_unavailable_string
  if self.is_unlocked and gold >= self.cost then
    text_color_string = self.text_color_string
  end

  self.title_text = Text({{text = '[' .. text_color_string .. '[3]]' .. self.title_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.buy_icon_text = Text({{text = '[' .. text_color_string .. '[3]]' .. self.buy_icon_string, font = pixul_font_huge, alignment = 'center'}}, global_text_tags)
  self.cost_text = Text({{text = '[' .. text_color_string .. '[3]]' .. self.cost_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
  if not self.is_unlocked then
    self.unavailable_text = Text({{text = '[' .. text_color_string .. '[3]]' .. self.unavailable_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
  end

  self.buy_icon_text.x = self.x
  self.buy_icon_text.y = self.y

  self.cost_text.x = self.x
  self.cost_text.y = self.y + 35

  if self.unavailable_text then
    self.unavailable_text.x = self.x
    self.unavailable_text.y = self.y + 50
  end
  
end


function CharacterCardBuy:refreshText()
  if self.buy_icon_text then
    self.buy_icon_text.dead = true
  end
  if self.unavailable_text then
    self.unavailable_text.dead = true
  end
  if self.cost_text then
    self.cost_text.dead = true
  end

  self:initText()

  table.insert(ALL_CARD_TEXTS, self.buy_icon_text)
  table.insert(ALL_CARD_TEXTS, self.cost_text)
  if self.unavailable_text then
    table.insert(ALL_CARD_TEXTS, self.unavailable_text)
  end

  
end

function CharacterCardBuy:draw()
  graphics.push(self.x, self.y, 0, self.spring.x, self.spring.x)
  --draw background
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, self.background_color)
  --draw text
  self.title_text:draw(self.x, self.y - (self.h/2) + 10)
  self.buy_icon_text:draw(self.buy_icon_text.x, self.buy_icon_text.y)
  self.cost_text:draw(self.cost_text.x, self.cost_text.y)
  if self.unavailable_text then
    self.unavailable_text:draw(self.unavailable_text.x, self.unavailable_text.y)
  end

  graphics.pop()
end

function CharacterCardBuy:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end

  
function CharacterCardBuy:update(dt)
  self:update_game_object(dt)

  if input.m1.pressed and self.colliding_with_mouse then
    self.parent:try_buy_unit(self.cost)
  end
end

function CharacterCardBuy:die()
  self.title_text.dead = true
  self.buy_icon_text.dead = true
  self.cost_text.dead = true
  if self.unavailable_text then
    self.unavailable_text.dead = true
  end
  self.dead = true
end
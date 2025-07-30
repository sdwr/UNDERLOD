Level0 = BaseLevel:extend()

function Level0:init(args)
  Level0.super.init(self, args)
  
  -- Level 0 specific properties
  self.level = 0
  self.is_tutorial = true
  
  -- Create tutorial text in the middle of the screen
  self:create_tutorial_text()
  
  -- Create BuyCharacter object instead of character floor items
  self:create_buy_character(NUMBER_OF_TROOPS_TO_CHARACTER_COST[0])
end

function Level0:create_tutorial_text()
  local lines = {
    {text = '[wavy_mid, cbyc3]Buy a character', font = fat_font, alignment = 'center'},
    {text = '[wavy_mid, cbyc3] <-', font = fat_font, alignment = 'center'},
  }
  self.tutorial_text = Text2{group = self.floor, x = gw/2 + self.offset_x, y = gh/2 + self.offset_y, lines = lines}
end

function Level0:create_combat_tutorial_text()
  self.tutorial_text = Text2{group = self.floor, x = gw/2 + self.offset_x, y = 100 + self.offset_y, 
  lines = {
    {text = '[wavy_mid, fg]Your units attack automatically', font = pixul_font, alignment = 'center'},
    {text = '', font = pixul_font, alignment = 'center'},
    {text = '[wavy_mid, fg]LMB to move', font = pixul_font, alignment = 'center'},
    {text = '[wavy_mid, fg]RMB to target', font = pixul_font, alignment = 'center'},
    {text = '', font = pixul_font, alignment = 'center'},
    {text = '[wavy_mid, fg]C to open inventory', font = pixul_font, alignment = 'center'},
    {text = '[wavy_mid, fg]ESC to pause', font = pixul_font, alignment = 'center'},
  }}
end

function Level0:on_buy_character_triggered()
  -- Call parent method first
  Level0.super.on_buy_character_triggered(self)

  -- Remove tutorial text
  self:remove_tutorial_text()
  
  -- Create new tutorial text for character selection
  self.tutorial_text = Text2{group = self.floor, x = gw/2 + self.offset_x, y = ARENA_TITLE_TEXT_Y + self.offset_y, lines = {{text = '[wavy_mid, cbyc3]Choose your character:', font = fat_font, alignment = 'center'}}}
end

function Level0:on_character_selected(character)
  -- Call parent method first
  Level0.super.on_character_selected(self, character)

  self:remove_tutorial_text()
  self:create_combat_tutorial_text()
  
  -- Open door after a short delay
  self.t:after(3, function()
    self:open_door()
  end)
end

function Level0:remove_tutorial_text()
  if self.tutorial_text then
    self.tutorial_text.dead = true
    self.tutorial_text = nil
  end
end

function Level0:remove_combat_tutorial_text()
  if self.combat_tutorial_text then
    self.combat_tutorial_text.dead = true
    self.combat_tutorial_text = nil
  end
end

function Level0:update(dt)
  Level0.super.update(self, dt)
end

function Level0:draw()
  Level0.super.draw(self)
end
 
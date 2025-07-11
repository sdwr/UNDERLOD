Level0 = Arena:extend()

function Level0:init(args)
  Level0.super.init(self, args)
  
  -- Level 0 specific properties
  self.level = 0
  self.is_tutorial = true
  
  -- Character selection
  self.character_options = {'swordsman', 'archer', 'laser'}
  self.selected_character = nil
  -- Create tutorial text
  self:create_tutorial_text()
  
  -- Create character selection
  self:create_character_selection()
end

function Level0:create_tutorial_text()
  self.tutorial_text = Text2{group = self.floor, x = gw/2 + self.offset_x, y = 50 + self.offset_y, lines = {{text = '[wavy_mid, fg]Choose your character:', font = fat_font, alignment = 'center'}}}
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

function Level0:create_character_selection()
  self.character_items = {}
  
  local positions = {
    {x = gw/2 - 100 + self.offset_x, y = gh/2 + self.offset_y},
    {x = gw/2 +   0 + self.offset_x, y = gh/2 + self.offset_y},
    {x = gw/2 + 100 + self.offset_x, y = gh/2 + self.offset_y}
  }
  
  for i, character in ipairs(self.character_options) do
    if positions[i] then
      local floor_item = FloorItem{
        group = self.floor,
        x = positions[i].x,
        y = positions[i].y,
        character = character,
        is_character_selection = true,
        parent = self
      }
      table.insert(self.character_items, floor_item)
    end
  end
end

function Level0:on_character_selected(character)
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  
  main.current:replace_first_unit(character)

  self:remove_all_character_items()
  self:remove_tutorial_text()
  self:create_combat_tutorial_text()
  
  -- Open door after a short delay
  self.t:after(3, function()
    self.door:open()
  end)
end

function Level0:remove_all_character_items()
  for _, item in ipairs(self.character_items) do
    item:die()
  end
  self.character_items = {}
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

function Level0:on_transition_start()
  self:remove_tutorial_text()
  self:create_combat_tutorial_text()
  self:remove_all_character_items()
end

function Level0:update(dt)
  Level0.super.update(self, dt)
end

function Level0:draw()
  Level0.super.draw(self)
end
 
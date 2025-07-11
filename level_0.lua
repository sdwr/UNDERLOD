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
  self.tutorial_text = Text2{group = self.ui, x = gw/2 + self.offset_x, y = 60 + self.offset_y, lines = {{text = '[wavy_mid, fg]Choose your character:', font = fat_font, alignment = 'center'}}}
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

function Level0:update(dt)
  Level0.super.update(self, dt)
end

function Level0:draw()
  Level0.super.draw(self)
end
 
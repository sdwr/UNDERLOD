CharacterTooltip = Object:extend()
CharacterTooltip.__class_name = 'CharacterTooltip'
CharacterTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local HEADER_HEIGHT = 8
local TOOLTIP_WIDTH = 220

function CharacterTooltip:init(args)
  self:init_game_object(args)
  self.character = args.character

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- Character info
  self.character_name = self.character:upper()
  self.character_color = character_to_color(self.character)
  
  -- Build text lines
  self:build_text_lines()
  
  -- Create info text
  self.info_text = InfoText{group = main.current.ui}
  self.info_text:activate(self.text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.info_text.x = self.x
  self.info_text.y = self.y
end

function CharacterTooltip:build_text_lines()
  self.text_lines = {}
  
  -- Character name
  table.insert(self.text_lines, {text = '[fg]' .. self.character_name, font = pixul_font, alignment = 'center'})
  
  -- Character description
  local description = self:get_character_description()
  if description then
    table.insert(self.text_lines, {text = '[fg]' .. description, font = pixul_font, alignment = 'center'})
  end
  
  -- Character stats
  local stats = self:get_character_stats()
  if stats and #stats > 0 then
    table.insert(self.text_lines, {text = '[fg]Stats:', font = pixul_font, alignment = 'center'})
    for stat, value in pairs(stats) do
      table.insert(self.text_lines, {text = '[fg]+' .. value .. ' ' .. stat, font = pixul_font, alignment = 'left'})
    end
  end
end

function CharacterTooltip:get_character_description()
  local descriptions = {
    ['archer'] = 'Basic ranged attacker',
    ['laser'] = 'Laser attack pierce enemies',
    ['swordsman'] = 'Basic melee attacker',
  }
  return descriptions[self.character] or 'A powerful warrior'
end

function CharacterTooltip:get_character_stats()
  local stats = {}
  return stats[self.character] or {}
end

function CharacterTooltip:update(dt)
  self:update_game_object(dt)
  
  -- Update spring animation
  self.spring:update(dt)
  self.sx = self.spring.x
  self.sy = self.spring.y
end

function CharacterTooltip:draw()
  -- The actual drawing is handled by InfoText
end

function CharacterTooltip:die()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
  self.dead = true
end 
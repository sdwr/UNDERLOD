SetBonusTooltip = Object:extend()
SetBonusTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local TOOLTIP_WIDTH = 250
local SET_SPACING = 12

function SetBonusTooltip:init(args)
  self:init_game_object(args)
  self.unit = args.unit
  if not self.unit then self.dead = true; return end

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- Build text lines
  self:build_text_lines()
  
  -- Create info text
  self.info_text = InfoText{group = main.current.world_ui}
  self.info_text:activate(self.text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  self.info_text.x = self.x
  self.info_text.y = self.y

  -- Start the activation animation
  self:activate()
end

function SetBonusTooltip:build_text_lines()
  self.text_lines = {}
  
  -- Get all sets the unit has items from
  local unit_sets = self:get_unit_sets()
  
  if #unit_sets == 0 then
    table.insert(self.text_lines, {text = '[fg]No set bonuses', font = pixul_font, alignment = 'center'})
    return
  end
  
  -- Sort sets by name for consistent display
  table.sort(unit_sets, function(a, b) return a.name < b.name end)
  
  for _, set_info in ipairs(unit_sets) do
    -- Set name header
    local set_color = set_info.color or 'fg'
    table.insert(self.text_lines, {
      text = '[' .. set_color .. ']' .. set_info.name:upper(), 
      font = pixul_font, 
      alignment = 'center'
    })
    
    -- Set bonuses
    for pieces, bonus in pairs(set_info.bonuses) do
      local is_reached = set_info.current_pieces >= pieces
      local color = is_reached and 'yellow' or 'fgm2'
      local checkmark = is_reached and 'X ' or 'O '
      
      table.insert(self.text_lines, {
        text = '[' .. color .. ']' .. checkmark .. pieces .. 'pc: ' .. bonus.desc, 
        font = pixul_font, 
        alignment = 'left'
      })
    end
    
    -- Add spacing between sets
    if _ < #unit_sets then
      table.insert(self.text_lines, {text = '', font = pixul_font, alignment = 'center'})
    end
  end
end

function SetBonusTooltip:get_unit_sets()
  local sets = {}
  local set_counts = {}
  
  -- Count items by set
  if self.unit.items then
    for _, item in ipairs(self.unit.items) do
      if item and item.sets then
        for _, set_name in ipairs(item.sets) do
          set_counts[set_name] = (set_counts[set_name] or 0) + 1
        end
      end
    end
  end
  
  -- Build set info
  for set_name, count in pairs(set_counts) do
    local set_def = ITEM_SETS[set_name]
    if set_def then
      table.insert(sets, {
        name = set_name,
        current_pieces = count,
        bonuses = set_def.bonuses,
        color = set_def.color
      })
    end
  end
  
  return sets
end

function SetBonusTooltip:draw()
  -- The InfoText handles its own drawing
end

function SetBonusTooltip:update(dt)
  self:update_game_object(dt)
  self.spring:update(dt)
end

function SetBonusTooltip:activate()
  self.t:cancel('deactivate')
  self.t:tween(0.1, self, {sx = 1, sy = 1}, math.cubic_in_out)
  self.spring:pull(0.075)
end

function SetBonusTooltip:deactivate()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
  self.t:cancel('activate')
  self.t:tween(0.05, self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end, 'deactivate')
end

function SetBonusTooltip:die()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
  self.dead = true
end 
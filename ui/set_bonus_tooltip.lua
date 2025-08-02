SetBonusTooltip = Object:extend()
SetBonusTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local TOOLTIP_WIDTH = 250
local SET_SPACING = 12

function SetBonusTooltip:init(args)
  self:init_game_object(args)
  self.item = args.item
  if not self.item then self.dead = true; return end

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
  
  -- Get all sets this item belongs to
  local item_sets = self:get_item_sets()
  
  if #item_sets == 0 then
    table.insert(self.text_lines, {text = '[fg]No set bonuses', font = pixul_font, alignment = 'center'})
    return
  end
  
  -- Sort sets by name for consistent display
  table.sort(item_sets, function(a, b) return a.name < b.name end)
  
  for _, set_info in ipairs(item_sets) do
    -- Set name header
    local set_color = set_info.color or 'fg'
    table.insert(self.text_lines, {
      text = '[' .. set_color .. ']' .. set_info.name:upper(), 
      font = pixul_font, 
      alignment = 'center'
    })
    
    -- Set bonuses
    for i = 1, MAX_SET_BONUS_PIECES do
      local bonus = set_info.bonuses[i]
      if bonus then

        local color = 'fgm2' -- Always show as unreached since we don't know current count
        
        -- Build bonus description from stats
        local bonus_desc = ""
        if bonus.stats then
          local stat_parts = {}
          for stat, value in pairs(bonus.stats) do
            local display_name = item_stat_lookup and item_stat_lookup[stat] or stat
            table.insert(stat_parts, "+" .. value .. " " .. display_name)
          end
          if bonus.procs then
            for _, proc in ipairs(bonus.procs) do
              table.insert(stat_parts, proc)
            end
          end
          bonus_desc = table.concat(stat_parts, ", ")
        end
        
        table.insert(self.text_lines, {
          text = '[' .. color .. ']' .. i .. 'pc: ' .. bonus_desc, 
          font = pixul_font, 
          alignment = 'left'
        })
      end
    end
    
    -- Add spacing between sets
    if _ < #item_sets then
      table.insert(self.text_lines, {text = '', font = pixul_font, alignment = 'center'})
    end
  end
end

function SetBonusTooltip:get_item_sets()
  local sets = {}
  
  -- Get all sets this item belongs to
  if self.item and self.item.sets then
    for _, set_name in ipairs(self.item.sets) do
      local set_def = ITEM_SETS[set_name]
      if set_def then
        table.insert(sets, {
          name = set_name,
          bonuses = set_def.bonuses,
          color = set_def.color
        })
      end
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
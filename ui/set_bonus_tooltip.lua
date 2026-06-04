SetBonusTooltip = Object:extend()
SetBonusTooltip.__class_name = 'SetBonusTooltip'
SetBonusTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local TOOLTIP_WIDTH = 250
local SET_SPACING = 12

function SetBonusTooltip:init(args)
  self:init_game_object(args)
  self.item = args.item
  self.unit = args.unit
  if not self.item then self.dead = true; return end

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- Build text lines
  self:build_text_lines()
  
  -- Create info text
  self.info_text = InfoText{group = self.group}
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

  -- Count current pieces per set for the equipping unit (if any). Drives
  -- per-row colouring (reached vs unreached) and the "X/N" header suffix.
  local set_counts = (self.unit and Helper.Unit:count_unit_set_pieces(self.unit)) or {}

  for set_index, set_info in ipairs(item_sets) do
    local set_color = set_info.color or 'fg'
    local current = set_counts[set_info.key or set_info.name] or 0
    local max_threshold = 0
    if set_info.bonuses then
      for i = 1, MAX_SET_BONUS_PIECES do
        if set_info.bonuses[i] then max_threshold = i end
      end
    end

    -- Header: SETNAME (current/max) when we know the unit's count.
    local header = '[' .. set_color .. ']' .. set_info.name:upper()
    if self.unit and max_threshold > 0 then
      header = header .. ' [fg](' .. current .. '/' .. max_threshold .. ')'
    end
    table.insert(self.text_lines, {text = header, font = pixul_font, alignment = 'center'})

    if set_info.bonuses and set_info.descriptions then
      for i = 1, MAX_SET_BONUS_PIECES do
        if set_info.bonuses[i] then
          local bonus = set_info.bonuses[i]
          local desc_text = set_info.descriptions[i]
          local stat_text = bonus.stats and self:get_bonus_stat_text(bonus.stats) or nil
          local bonus_text = desc_text or stat_text or ""

          local is_reached = current >= i
          -- Reached rows pop in the set's colour; unreached stay dim grey.
          local color = is_reached and set_color or 'fgm2'

          table.insert(self.text_lines, {
            text = '[' .. color .. ']' .. i .. ': ' .. bonus_text,
            font = pixul_font,
            alignment = 'left'
          })
        end
      end
    end

    if set_index < #item_sets then
      table.insert(self.text_lines, {text = '', font = pixul_font, alignment = 'center'})
    end
  end
end

function SetBonusTooltip:get_bonus_stat_text(bonus)
  local stat_text = nil
  if bonus then
    local color = 'fgm2' -- Always show as unreached since we don't know current count
    
    -- Build bonus description from stats
    local stat_parts = {}
    if bonus.stats then
      for stat, value in pairs(bonus.stats) do
        local display_name = item_stat_lookup and item_stat_lookup[stat] or stat
        table.insert(stat_parts, "+" .. value .. " " .. display_name)
      end
    end
    if bonus.procs then
      for _, proc in ipairs(bonus.procs) do
        table.insert(stat_parts, proc)
      end
    end
    
    stat_text = table.concat(stat_parts, ", ")
    
  end
  return stat_text
end

function SetBonusTooltip:get_item_sets()
  local sets = {}

  -- Get all sets this item belongs to. Each entry is a shallow copy of the
  -- set def with `key` attached so build_text_lines can look the unit's
  -- piece count up in set_counts (which is keyed by item.sets entries).
  if self.item and self.item.sets then
    for _, set_key in ipairs(self.item.sets) do
      local set_def = ITEM_SETS[set_key]
      if set_def then
        local entry = {key = set_key}
        for k, v in pairs(set_def) do entry[k] = v end
        table.insert(sets, entry)
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
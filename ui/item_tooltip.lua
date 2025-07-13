ItemTooltip = Object:extend()
ItemTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local HEADER_HEIGHT = 8
local STATS_DESC_PADDING = 16 -- New: Specific padding for this gap
local TOOLTIP_WIDTH = 220

function ItemTooltip:init(args)
  self:init_game_object(args)
  self.item = args.item
  
  -- Handle V2 items (which don't need conversion) vs legacy items
  if not self.item.name or not self.item.icon then
    -- Try to create legacy item
    self.item = Create_Item(self.item.name)
    if not self.item then self.dead = true; return end
  end

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- 1. HEADER TEXT (Cost and Triggers)
  self.cost_text = Text({{text ='[yellow]' .. (self.item.cost or 0), font = pixul_font}}, global_text_tags)
  local tag_lines = {}
  if self.item.tags then
      for _, tag in ipairs(self.item.tags) do 
        local text = '[' .. PROC_TYPE_TO_DISPLAY[tag].color .. ']' .. PROC_TYPE_TO_DISPLAY[tag].text
        table.insert(tag_lines, {text = text, font = pixul_font, alignment = 'left'}) 
      end
  end
  self.tags_text = Text(tag_lines, global_text_tags)

  -- 2. NAME TEXT
  local name = self.item.name or 'UNKNOWN ITEM'
  self.name_text = Text({{text ='[fg]' .. name:upper(), font = pixul_font, alignment = 'center'}}, global_text_tags)

  -- 3. ITEM SETS TEXT (New Section)
  local sets_text_definitions = {}
  if self.item.sets then
      for _, set_name in ipairs(self.item.sets) do
          local set_def = ITEM_SETS[set_name]
          if set_def then
              local color = set_def.color or 'fg'
              local text = '[' .. color .. ']' .. set_name:upper()
              table.insert(sets_text_definitions, { text = text, font = pixul_font, alignment = 'center' })
          end
      end
  end
  self.sets_text = Text(sets_text_definitions, global_text_tags)

  -- 4. STATS TEXT
  local stats_text_definitions = {}
  if self.item.stats then
      for key, val in pairs(self.item.stats) do
          local text = ''
          local display_name = item_stat_lookup and item_stat_lookup[key] or key
          
          -- Handle V2 item stats (numeric values)
          if type(val) == 'number' then
            local prefix, value, suffix, display_name = format_stat_display(key, val)
            text = '[yellow] ' .. prefix .. value .. suffix .. display_name
          else
            -- Handle legacy item stats (boolean values)
            text = '[yellow] ' .. display_name
          end
          table.insert(stats_text_definitions, { text = text, font = pixul_font, alignment = 'center' })
      end
  end
  self.stats_text = Text(stats_text_definitions, global_text_tags)

  -- 5. Calculate total dimensions for the background
  self.w = TOOLTIP_WIDTH
  self.h = self.name_text.h + self.sets_text.h + self.stats_text.h + (PADDING * 4)

  -- Start the activation animation
  self:activate()
end


function ItemTooltip:draw()
  if not self.item then return end

  local cx, cy = self.x, self.y
  graphics.push(cx, cy, 0, self.sx * self.spring.x, self.sy * self.spring.x)
  graphics.rectangle(cx, cy, self.w, self.h, 8, 8, bg[-2])

  local top_y = cy - self.h/2
  local left_x = cx - self.w/2
  local right_x = cx + self.w/2
  
  -- current_y will always represent the top boundary for the next element.
  local current_y = top_y

  -- 1. Draw Header
  -- Your header has custom left/right alignment, so we'll treat it specially.
  self.tags_text:draw(left_x + self.tags_text.w/2 + PADDING/2, current_y + self.tags_text.h/2 + PADDING/2)
  self.cost_text:draw(right_x - PADDING, current_y + PADDING)
  -- Advance past the header section.
  current_y = current_y + PADDING

  -- 2. Draw Name
  -- Advance to the vertical center of the Name text for drawing.
  self.name_text:draw(cx, current_y + self.name_text.h / 2)
  -- Advance past the Name text.
  current_y = current_y + self.name_text.h + PADDING

  -- 3. Draw Item Sets (if any)
  if self.sets_text.h > 0 then
      -- Advance to the vertical center of the Sets text.
      self.sets_text:draw(cx, current_y + self.sets_text.h / 2)
      -- Advance past the Sets text.
      current_y = current_y + self.sets_text.h + PADDING
  end

  -- 4. Draw Stats
  if self.stats_text.h > 0 then
      -- Advance to the vertical center of the Stats text.
      self.stats_text:draw(cx, current_y + self.stats_text.h / 2)
      -- Advance past the Stats text.
      current_y = current_y + self.stats_text.h + PADDING
  end

  self.h = current_y - top_y

  graphics.pop()
end

-- A helper function to wrap text to a certain pixel width
  function ItemTooltip:wrap_text(text, max_width, font)
    local lines = {}
    local current_line = ''
    -- Prevent errors if text is nil
    if not text then return {} end
    
    for word in text:gmatch("([^ ]+)") do
        local test_line = current_line == '' and word or current_line .. ' ' .. word
        
        if font:get_text_width(test_line) > max_width then
            table.insert(lines, current_line)
            current_line = word
        else
            current_line = test_line
        end
    end
    table.insert(lines, current_line)
    
    return lines
end


function ItemTooltip:update(dt)
  self:update_game_object(dt)
  self.spring:update(dt)
end

function ItemTooltip:activate()
  self.t:cancel('deactivate')
  self.t:tween(0.1, self, {sx = 1, sy = 1}, math.cubic_in_out)
  self.spring:pull(0.075)
end

function ItemTooltip:deactivate()
  self.t:cancel('activate')
  self.t:tween(0.05, self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end, 'deactivate')
end

function ItemTooltip:die()
  self.dead = true
  if self.item and self.item.die then self.item:die() end
end
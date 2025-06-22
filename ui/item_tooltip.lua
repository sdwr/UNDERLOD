ItemTooltip = Object:extend()
ItemTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local HEADER_HEIGHT = 8
local TOOLTIP_WIDTH = 220 -- A fixed width makes layout much easier

function ItemTooltip:init(args)
  self:init_game_object(args)
  self.item = args.item
  self.item = Create_Item(self.item.name)
  if not self.item then self.dead = true; return end

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- 1. HEADER TEXT (Cost and Triggers)
  self.cost_text = Text({{text ='[yellow]' .. (self.item.cost or 0), font = pixul_font}}, global_text_tags)
  local tag_lines = {}
  if self.item.tags then
      for _, tag in ipairs(self.item.tags) do table.insert(tag_lines, '[' .. PROC_TYPE_TO_DISPLAY[tag].color .. ']' .. PROC_TYPE_TO_DISPLAY[tag].text) end
  end
  self.tags_text = Text({{text = table.concat(tag_lines, '\n'), font = pixul_font, alignment = 'right'}}, global_text_tags)
  self.tags_text_width = 0
  for _, line in ipairs(self.tags_text.text_data) do
    self.tags_text_width = math.max(self.tags_text_width, pixul_font:get_text_width(line.text))
  end

  -- 2. NAME TEXT
  local name = self.item.name or 'UNKNOWN ITEM'
  self.name_text = Text({{text ='[fg]' .. name:upper(), font = pixul_font, alignment = 'center'}}, global_text_tags)

  -- 3. STATS TEXT (New Section)
  local stats_text_definitions = {}
  if self.item.stats then
      for key, val in pairs(self.item.stats) do
          local text = ''
          if key == 'gold' then
              text = '[yellow] ' .. val .. ' ' .. (item_stat_lookup[key] or '')
          elseif key == 'enrage' or key == 'ghost' then
              text = '[yellow] ' .. (item_stat_lookup[key] or '')
          elseif key == 'proc' then
              text = '[yellow]' .. 'custom proc... add later'
          else
              text = '[yellow] ' .. val * 100 .. '% ' .. (item_stat_lookup[key] or '')
          end
          table.insert(stats_text_definitions, { text = text, font = pixul_font, alignment = 'center' })
      end
  end
  self.stats_text = Text(stats_text_definitions, global_text_tags)

  -- 4. DESCRIPTION TEXT
  local desc = self.item.desc or 'No description available.'
  local wrapped_lines = self:wrap_text(desc, TOOLTIP_WIDTH - PADDING*2, pixul_font)
  
  -- Convert the table of strings into a table of text definitions
  local desc_text_definitions = {}
  for _, line in ipairs(wrapped_lines) do
      table.insert(desc_text_definitions, { text = '[fgm2]' .. line, font = pixul_font, alignment = 'center' })
  end
  self.desc_text = Text(desc_text_definitions, global_text_tags)

  -- 5. Calculate total dimensions for the background
  self.w = TOOLTIP_WIDTH
  self.h = self.name_text.h + self.stats_text.h + self.desc_text.h + PADDING * 5

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
  
  -- Start drawing from the top
  local current_y = top_y

  -- Draw Header
  self.tags_text:draw(left_x + self.tags_text_width/3, current_y + PADDING)
  self.cost_text:draw(right_x - PADDING, current_y + PADDING)
  current_y = current_y + PADDING + HEADER_HEIGHT

  -- Draw Name
  self.name_text:draw(cx, current_y)
  current_y = current_y + self.name_text.h + PADDING

  -- Draw Stats
  if self.stats_text.h > 0 then
      self.stats_text:draw(cx, current_y)
      current_y = current_y + self.stats_text.h + PADDING
  end
  
  -- Draw Description
  self.desc_text:draw(cx, current_y)

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
  if self.item then self.item:die() end
end
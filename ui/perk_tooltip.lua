PerkTooltip = Object:extend()
PerkTooltip:implement(GameObject)

-- Constants for layout
local PADDING = 8
local HEADER_HEIGHT = 8
local STATS_DESC_PADDING = 16
local TOOLTIP_WIDTH = 220

function PerkTooltip:init(args)
  self:init_game_object(args)
  self.perk = args.perk
  if not self.perk then self.dead = true; return end

  -- Animation and positioning
  self.spring = Spring(1, 150, 20)
  self.sx, self.sy = 0, 0 -- Scale for animations
  self.x = args.x or gw/2
  self.y = args.y or gh/2

  -- 1. HEADER TEXT (Rarity)
  local rarity_color = get_rarity_color(self.perk.rarity or 'common')
  local rarity_text = '[' .. (self.perk.rarity or 'common'):upper() .. ']'
  self.rarity_text = Text({{text = rarity_text, font = pixul_font}}, global_text_tags)

  -- 2. NAME TEXT
  local name = self.perk.name or 'UNKNOWN PERK'
  self.name_text = Text({{text ='[fg]' .. name:upper(), font = pixul_font, alignment = 'center'}}, global_text_tags)

  -- 3. STATS TEXT
  local stats_text_definitions = {}
  --don't show perk stats, the description is enough
  -- local perk_stats = Get_Perk_Stats(self.perk)
  -- if perk_stats then
  --     for key, val in pairs(perk_stats) do
  --         local text = ''
  --         if key == 'gold' then
  --             text = '[yellow] ' .. val .. ' ' .. (item_stat_lookup[key] or '')
  --         elseif key == 'enrage' or key == 'ghost' then
  --             text = '[yellow] ' .. (item_stat_lookup[key] or '')
  --         elseif key == 'proc' then
  --             text = '[yellow]' .. 'custom proc... add later'
  --         else
  --             local prefix, value, suffix, display_name = format_stat_display(key, val)
  --             text = '[yellow] ' .. prefix .. value .. suffix .. display_name
  --         end
  --         table.insert(stats_text_definitions, { text = text, font = pixul_font, alignment = 'center' })
  --     end
  -- end
  self.stats_text = Text(stats_text_definitions, global_text_tags)

  -- 4. DESCRIPTION TEXT
  local desc = self.perk.description or 'No description available.'
  local wrapped_lines = self:wrap_text(desc, TOOLTIP_WIDTH - PADDING*2, pixul_font)
  
  -- Convert the table of strings into a table of text definitions
  local desc_text_definitions = {}
  for _, line in ipairs(wrapped_lines) do
      table.insert(desc_text_definitions, { text = '[fgm2]' .. line, font = pixul_font, alignment = 'center' })
  end
  self.desc_text = Text(desc_text_definitions, global_text_tags)

  -- 5. Calculate total dimensions for the background
  self.w = TOOLTIP_WIDTH
  self.h = self.name_text.h + self.stats_text.h + self.desc_text.h + (PADDING * 4)

  -- Start the activation animation
  self:activate()
end

function PerkTooltip:draw()
  if not self.perk then return end

  local cx, cy = self.x, self.y
  graphics.push(cx, cy, 0, self.sx * self.spring.x, self.sy * self.spring.x)
  graphics.rectangle(cx, cy, self.w, self.h, 8, 8, bg[-2])

  local top_y = cy - self.h/2
  local left_x = cx - self.w/2
  local right_x = cx + self.w/2
  
  -- current_y will always represent the top boundary for the next element.
  local current_y = top_y

  -- 1. Draw Header (Rarity)
  self.rarity_text:draw(left_x + PADDING, current_y + PADDING)
  -- Advance past the header section.
  current_y = current_y + PADDING

  -- 2. Draw Name
  -- Advance to the vertical center of the Name text for drawing.
  self.name_text:draw(cx, current_y + self.name_text.h / 2)
  -- Advance past the Name text.
  current_y = current_y + self.name_text.h + PADDING

  -- 3. Draw Stats
  if self.stats_text.h > 0 then
      -- Advance to the vertical center of the Stats text.
      self.stats_text:draw(cx, current_y + self.stats_text.h / 2)
      -- Advance past the Stats text.
      current_y = current_y + self.stats_text.h + PADDING
  end
  
  -- Advance to the vertical center of the Description text.
  self.desc_text:draw(cx, current_y + self.desc_text.h / 2)
  current_y = current_y + self.desc_text.h + PADDING
  -- No need to advance current_y further, as this is the last element.

  self.h = current_y - top_y

  graphics.pop()
end

-- A helper function to wrap text to a certain pixel width
function PerkTooltip:wrap_text(text, max_width, font)
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

function PerkTooltip:update(dt)
  self:update_game_object(dt)
  self.spring:update(dt)
end

function PerkTooltip:activate()
  self.t:cancel('deactivate')
  self.t:tween(0.1, self, {sx = 1, sy = 1}, math.cubic_in_out)
  self.spring:pull(0.075)
end

function PerkTooltip:deactivate()
  self.t:cancel('activate')
  self.t:tween(0.05, self, {sx = 0, sy = 0}, math.linear, function() self.dead = true end, 'deactivate')
end

function PerkTooltip:die()
  self.dead = true
end 
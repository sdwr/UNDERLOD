-- MetaPanel
-- Buy-screen column showing team-wide color totals and active meta tiers.
-- Replaces PerksPanel. Reads the current team's items via get_team_units()
-- and computes thresholds with get_team_meta_stats helpers.

MetaPanel = Object:extend()
MetaPanel.__class_name = 'MetaPanel'
MetaPanel:implement(GameObject)

local ROW_HEIGHT = 30
local SWATCH_SIZE = 18

function MetaPanel:init(args)
  self:init_game_object(args)

  self.x = args.x or gw - 100
  self.y = args.y or 20
  self.width = args.width or 80

  self.title = Text2{
    group = self.group,
    x = self.x + self.width/2,
    y = self.y,
    lines = {{text = 'meta', font = pixul_font, alignment = 'center'}},
    fg_color = 'white'
  }

  self.rows = {}
  for i, color in ipairs(META_COLORS) do
    local row_y = self.y + 25 + (i-1) * ROW_HEIGHT
    self.rows[i] = MetaRow{
      group = self.group,
      x = self.x + 15 + (self.width - SWATCH_SIZE) / 2,
      y = row_y,
      w = self.width - 20,
      color_name = color,
      parent = self,
    }
  end
end

function MetaPanel:update(dt)
  self:update_game_object(dt)
  -- Counts only need to be computed once per frame; each row reads from
  -- here instead of walking the full team for itself.
  self.counts = count_team_meta_colors(get_team_units())
end

function MetaPanel:draw()
  if self.title then self.title:draw() end
end

function MetaPanel:die()
  for _, row in ipairs(self.rows) do row:die() end
  if self.title then self.title.dead = true end
  self.dead = true
end


MetaRow = Object:extend()
MetaRow.__class_name = 'MetaRow'
MetaRow:implement(GameObject)

function MetaRow:init(args)
  self:init_game_object(args)
  self.color_name = args.color_name
  self.w = args.w or 60
  self.h = SWATCH_SIZE
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.parent = args.parent
  self.spring:pull(0.1, 200, 10)

  -- Resolve once: the color global doesn't change, and draw() reads it
  -- twice per frame.
  local c = _G[self.color_name]
  self.color = (c and c[0]) or fg[0]
end

function MetaRow:current_count()
  local counts = self.parent and self.parent.counts
  if not counts then return 0 end
  return counts[self.color_name] or 0
end

function MetaRow:update(dt)
  self:update_game_object(dt)
  self.shape:move_to(self.x, self.y)
end

function MetaRow:draw()
  graphics.push(self.x, self.y, 0, self.sx * self.spring.x, self.sy * self.spring.x)

    local swatch_x = self.x - self.w/2 + SWATCH_SIZE/2
    graphics.rectangle(swatch_x, self.y, SWATCH_SIZE, SWATCH_SIZE, 3, 3, self.color)

    self:draw_pips()

  graphics.pop()
end

-- One pip per item up to the top threshold, arranged in rows of 3/3/2.
-- Filling matches the team's current count of items of this color.
MetaRow.PIP_ROWS = {3, 3, 2}

function MetaRow:draw_pips()
  local count = self:current_count()
  local pip_w, pip_h = 5, 5
  local h_spacing, v_spacing = 2, 2
  local rows = MetaRow.PIP_ROWS

  -- Block centered vertically on self.y, anchored just right of the swatch.
  local block_h = #rows * pip_h + (#rows - 1) * v_spacing
  local top_y = self.y - block_h/2 + pip_h/2
  local left_x = self.x - self.w/2 + SWATCH_SIZE + 6 + pip_w/2

  local filled_color = self.color
  local pip_idx = 0
  for row_i, n in ipairs(rows) do
    local row_y = top_y + (row_i - 1) * (pip_h + v_spacing)
    for col_i = 1, n do
      pip_idx = pip_idx + 1
      local pip_x = left_x + (col_i - 1) * (pip_w + h_spacing)
      local color = pip_idx <= count and filled_color or bg[5]
      graphics.rectangle(pip_x, row_y, pip_w, pip_h, 1, 1, color)
    end
  end
end

function MetaRow:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
  self:highlight_matching_items(true)
  self:show_tooltip()
end

function MetaRow:on_mouse_exit()
  self.spring:pull(0.1, 200, 10)
  self:highlight_matching_items(false)
  self:hide_tooltip()
end

function MetaRow:highlight_matching_items(on)
  if not Character_Cards then return end
  for _, card in ipairs(Character_Cards) do
    if card and card.items then
      for _, part in ipairs(card.items) do
        local item = part.getItem and part:getItem() or nil
        local matches = false
        if item and item.colors then
          for _, c in ipairs(item.colors) do
            if c == self.color_name then matches = true; break end
          end
        end
        if matches then
          if on then part:highlight() else part:unhighlight() end
        end
      end
    end
  end
end

function MetaRow:show_tooltip()
  local label = META_COLOR_LABEL[self.color_name] or self.color_name
  local count = self:current_count()
  local lines = {
    {text = '[fg]' .. label, font = pixul_font, alignment = 'center'},
  }
  for _, t in ipairs(META_THRESHOLDS) do
    local prefix = count >= t.count and '[yellow]' or '[fg]'
    local pct = math.floor(t.bonus * 100 + 0.5)
    table.insert(lines, {text = prefix .. t.count .. ' = +' .. pct .. '%', font = pixul_font, alignment = 'center'})
  end

  self.info_text = InfoText{group = main.current.world_ui or main.current.ui}
  self.info_text:activate(lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position()
  self.info_text.x, self.info_text.y = pos.x, pos.y
  global_info_text = self.info_text.cost_text_object
end

function MetaRow:hide_tooltip()
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end

function MetaRow:die()
  self:hide_tooltip()
  self.dead = true
end

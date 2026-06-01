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

local color_globals = {
  red    = function() return red    end,
  yellow = function() return yellow end,
  blue   = function() return blue   end,
  brown  = function() return brown  end,
  purple = function() return purple end,
}

function MetaRow:init(args)
  self:init_game_object(args)
  self.color_name = args.color_name
  self.w = args.w or 60
  self.h = SWATCH_SIZE
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.parent = args.parent
  self.spring:pull(0.1, 200, 10)
end

function MetaRow:current_count()
  local counts = count_team_meta_colors(get_team_units())
  return counts[self.color_name] or 0
end

function MetaRow:active_tier_index()
  local n = self:current_count()
  local idx = 0
  for i, t in ipairs(META_THRESHOLDS) do
    if n >= t.count then idx = i end
  end
  return idx
end

function MetaRow:update(dt)
  self:update_game_object(dt)
  self.shape:move_to(self.x, self.y)
end

function MetaRow:swatch_color()
  local getter = color_globals[self.color_name]
  if getter and getter() then return getter()[0] end
  return fg[0]
end

function MetaRow:draw()
  graphics.push(self.x, self.y, 0, self.sx * self.spring.x, self.sy * self.spring.x)

    local swatch_x = self.x - self.w/2 + SWATCH_SIZE/2
    graphics.rectangle(swatch_x, self.y, SWATCH_SIZE, SWATCH_SIZE, 3, 3, self:swatch_color())

    self:draw_tier_pips()

  graphics.pop()
end

function MetaRow:draw_tier_pips()
  local active = self:active_tier_index()
  local pip_w, pip_h, pip_spacing = 6, 6, 3

  -- Pips sit just to the right of the swatch.
  local start_x = self.x - self.w/2 + SWATCH_SIZE + 6 + pip_w/2

  for i, _ in ipairs(META_THRESHOLDS) do
    local pip_x = start_x + (i - 1) * (pip_w + pip_spacing)
    graphics.rectangle(pip_x, self.y, pip_w, pip_h, 1, 1, bg[5])
    if i <= active then
      graphics.rectangle(pip_x, self.y, pip_w, pip_h, 1, 1, self:swatch_color())
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

-- Bottom-center team hotbar: SPACE / 1 / 2 / ... One button per player unit
-- (team). Click a button or press its hotkey (1..9) to choose which unit(s)
-- receive mouse commands; clicking SPACE selects all. Holding spacebar moves
-- every unit toward the cursor and lights the SPACE button while held.
-- Selection state itself lives in Helper.Unit.selected_team_index; this
-- object is just the view + click input.
TeamHotbar = Object:extend()
TeamHotbar.__class_name = 'TeamHotbar'
TeamHotbar:implement(GameObject)
function TeamHotbar:init(args)
  self:init_game_object(args)
  self.button_w = 26
  self.space_button_w = 38
  self.button_h = 14
  self.gap = 4
  self.hovered = false
  self.texts = {}
end

-- Layout is computed fresh each call so the bar adapts if the number of teams
-- changes (teams are rebuilt every level).
function TeamHotbar:get_buttons()
  local teams = Helper.Unit.teams or {}
  local n = math.min(#teams, 9)
  local ox = (self.parent and self.parent.offset_x) or 0
  local oy = (self.parent and self.parent.offset_y) or 0
  local total = self.space_button_w + n * (self.button_w + self.gap)
  local x = gw / 2 - total / 2
  local buttons = {}
  for i = 0, n do
    local w = (i == 0) and self.space_button_w or self.button_w
    table.insert(buttons, {
      index = i,
      x = x + w / 2 + ox,
      y = self.y + oy,
      w = w,
      team = (i > 0) and teams[i] or nil,
    })
    x = x + w + self.gap
  end
  return buttons
end

function TeamHotbar:update(dt)
  self:update_game_object(dt)
  if #(Helper.Unit.teams or {}) == 0 then return end

  local mx, my = Helper.mousex, Helper.mousey
  local was_hovered = self.hovered
  self.hovered = false
  for _, b in ipairs(self:get_buttons()) do
    if math.abs(mx - b.x) <= b.w / 2 + self.gap / 2
      and math.abs(my - b.y) <= self.button_h / 2 + self.gap / 2 then
      self.hovered = true
      if input.m1.pressed then
        Helper.Unit:set_selected_team(b.index)
      end
    end
  end

  -- Swallow rally/attack clicks while the mouse is over the bar. Only touch
  -- the shared flag on transitions so other UI's hover handling still works.
  if self.hovered ~= was_hovered then
    Helper.disable_unit_controls = self.hovered
    if self.hovered then
      ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.3}
    end
  end
end

function TeamHotbar:get_text(label, color)
  local key = label .. color
  if not self.texts[key] then
    self.texts[key] = Text({{text = '[' .. color .. ']' .. label, font = pixul_font, alignment = 'center'}}, global_text_tags)
  end
  return self.texts[key]
end

function TeamHotbar:draw()
  if #(Helper.Unit.teams or {}) == 0 then return end

  local selected_index = Helper.Unit.selected_team_index or 0
  for _, b in ipairs(self:get_buttons()) do
    local selected = (selected_index == b.index)
      or (b.index == 0 and Helper.Unit.space_all_override)
    graphics.rectangle(b.x, b.y, b.w, self.button_h, 3, 3, bg[0])
    if selected then
      graphics.rectangle(b.x, b.y, b.w, self.button_h, 3, 3, yellow[0], 1)
    end

    local label = (b.index == 0) and 'SPACE' or tostring(b.index)
    local team_wiped = b.team and b.team.center_marker and b.team.center_marker.dead
    local color = selected and 'yellow[0]' or (team_wiped and 'bg[5]' or 'white[0]')
    self:get_text(label, color):draw(b.x, b.y + 1)

    -- Unit color chip so buttons are readable at a glance.
    if b.team then
      graphics.rectangle(b.x, b.y + self.button_h / 2 + 2, b.w - 6, 2, 1, 1, b.team.color)
    end
  end
end

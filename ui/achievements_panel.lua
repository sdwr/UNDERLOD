

AchievementsPanel = Object:extend()
AchievementsPanel:implement(GameObject)
function AchievementsPanel:init(args)
  self:init_game_object(args)
  
  self.x = gw/2
  self.y = gh/2
  self.w = gw - 230
  self.h = gh - 100

  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true

  --memory
  self.scroll_location = 0
  self.mouse_over = false
  self.achievement_locations = {}
  self.popup_text = nil

end

function AchievementsPanel:update(dt)
  self:update_mouseover()
  self:updateScroll()
  self:updateClose()
end

function AchievementsPanel:update_mouseover()
  local x, y = self.group:get_mouse_position()

  if self.shape:is_colliding_with_point(x, y) then
    self.mouse_over = true
  else
    self.mouse_over = false
  end
  if not self:highlightedAchievement() then
    self:clearPopupText()
  end
end

function AchievementsPanel:updateScroll()
  if not self.mouse_over then return end

  if input.wheel_up.pressed then
    self.scroll_location = self.scroll_location + SCROLL_SPEED
    self.scroll_location = math.min(self.scroll_location, MAX_SCROLL_LOCATION)
  end
  if input.wheel_down.pressed then
    self.scroll_location = self.scroll_location - SCROLL_SPEED
    self.scroll_location = math.max(self.scroll_location, MIN_SCROLL_LOCATION)
  end
end

function AchievementsPanel:updateClose()
  if not self.mouse_over then return end
  local x, y = self.group:get_mouse_position()
  if x > self.x + self.w/2 - 15 and x < self.x + self.w/2 + 5 and y > self.y - self.h/2 - 5  and y < self.y - self.h/2 + 15 then
    if input.m1.pressed then
      close_achievements(main.current)
    end
  end
end

function AchievementsPanel:draw()

  local mask = function()
    graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, white[1])
  end

  local drawAll = function()
    self:drawAll()
  end

  graphics.push(self.x, self.y, 0, self.sx * self.spring.x, self.sy * self.spring.x)
    graphics.draw_with_mask(drawAll, mask)
    self:drawCloseButton()
  graphics.pop()
  self:drawPopupText()
end

--happens inside the push
function AchievementsPanel:drawCloseButton()
  graphics.rectangle(self.x + self.w/2 - 5, self.y - self.h/2 + 5, 20, 20, nil, nil, white[3])
  graphics.print("X", pixul_font, self.x + self.w/2 - 12, self.y - self.h/2 - 4, nil, 2, 2, nil, nil, red[2])
end

function AchievementsPanel:drawPopupText()
  if not self.mouse_over then return end
  local achievement = self:highlightedAchievement()
  if not achievement then return end

  self:clearPopupText()

  self.popup_text = InfoText{group = main.current.options_ui, force_update = true}
  self.popup_text:activate(build_achievement_text(achievement), nil, nil, nil, nil, 16, 4, nil, 2)
  self.popup_text.x, self.popup_text.y = gw/2, gh/2
end

function AchievementsPanel:clearPopupText()
  if not self.popup_text then return end
  self.popup_text.dead = true
  self.popup_text = nil
end

function AchievementsPanel:drawAll()
  local color = bg[1]:clone()
  color.a = 0.8
  graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, color)
  
  local start_x = (self.x - self.w / 2) + ACHIEVEMENT_SIZE/2 + ACHIEVEMENT_SPACING
  local start_y = (self.y - self.h / 2) +  ACHIEVEMENT_SIZE/2 + ACHIEVEMENT_SPACING

  local computed_y = start_y + (self.scroll_location * SCROLL_SPEED)

  local space_between = ACHIEVEMENT_SIZE + ACHIEVEMENT_SPACING

  local x = start_x
  local y = computed_y
  local count = 0

  self.achievement_locations = {}
  for i, achievement_name in ipairs(ACHIEVEMENTS_INDEX) do
    self.achievement_locations[achievement_name] = {x = x, y = y}
    local achievement = ACHIEVEMENTS_TABLE[achievement_name]
    local unlocked = ACHIEVEMENTS_UNLOCKED[achievement_name]

    --should calculate whether they are visible on screen before drawing
    local color = white[1]:clone()
    local borderColor = fg[0]:clone()

    if unlocked then
      color = green[0]:clone()
      borderColor = yellow[0]:clone()
    end

    color.a = 0.5
    graphics.rectangle(x , y, ACHIEVEMENT_SIZE, ACHIEVEMENT_SIZE, nil, nil, color)
    local image = find_item_image(achievement.icon)

    image:draw(x, y, 0, 0.7, 0.7)

    graphics.rectangle(x, y, ACHIEVEMENT_SIZE, ACHIEVEMENT_SIZE, nil, nil, borderColor, 3)

    x = x + space_between
    count = count + 1

    if count % ACHIEVEMENTS_PER_ROW == 0 then
      x = start_x
      y = y + space_between
    end
  end
end

function AchievementsPanel:highlightedAchievement()
  local x, y = self.group:get_mouse_position()
  for achievement_name, location in pairs(self.achievement_locations) do
    local x1 = location.x - ACHIEVEMENT_SIZE/2
    local y1 = location.y - ACHIEVEMENT_SIZE/2
    local x2 = x1 + ACHIEVEMENT_SIZE
    local y2 = y1 + ACHIEVEMENT_SIZE

    if x > x1 and x < x2 and y > y1 and y < y2 then
      return ACHIEVEMENTS_TABLE[achievement_name]
    end
  end
  return nil
end

function AchievementsPanel:die()
  self:clearPopupText()
  self.dead = true
end


AchievementToast = Object:extend()
AchievementToast:implement(GameObject)
function AchievementToast:init(args)
  self:init_game_object(args)
  
  self.w = 130
  self.h = 50
  self.x = gw - self.w/2
  self.y = gh - self.h/2

  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true

  self.bg_color = bg[1]

  --memory
  self.scroll_location = 0
  self.mouse_over = false

  self.achievement = args.achievement
  self.duration = 3 or args.duration
end

function AchievementToast:update(dt)
  self.duration = self.duration - dt
  if self.duration < 0 then
    self:die()
  end
end

function AchievementToast:draw()

  local image = find_item_image(self.achievement.icon)

  graphics.push(self.x, self.y, 0, self.sx * self.spring.x, self.sy * self.spring.x)
    graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, self.bg_color)
    graphics.print(self.achievement.name, pixul_font, self.x - 30, self.y - 20, nil, 1, 1, nil, nil, white[1])
    graphics.print(self.achievement.desc, pixul_font, self.x - 30, self.y, nil, 0.9, 0.9, nil, nil, white[1])
    image:draw(self.x - 50, self.y, 0, 0.7, 0.7)
  graphics.pop()
end

function AchievementToast:die()
  self.dead = true
end

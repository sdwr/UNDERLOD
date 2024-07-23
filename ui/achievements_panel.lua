

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

end

function AchievementsPanel:update(dt)
  self:update_game_object(dt)
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
    

  graphics.pop()
end

function AchievementsPanel:drawAll()
  local color = bg[1]:clone()
  color.a = 0.8
  graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, color)

  local achievement_size = 50
  local spacing = 10
  local achievements_per_row = 4
  
  local start_x = (self.x - self.w / 2) + achievement_size/2 + spacing
  local start_y = (self.y - self.h / 2) +  achievement_size/2 + spacing

  local space_between = achievement_size + spacing

  local x = start_x
  local y = start_y
  local count = 0

  for achievement in pairs(ACHIEVEMENTS_TABLE) do
    local color = white[1]:clone()
    color.a = 0.8
    graphics.rectangle(x , y, achievement_size, achievement_size, nil, nil, color)

    local color = green[1]:clone()
    color.a = 1

    x = x + space_between
    count = count + 1

    if count % achievements_per_row == 0 then
      x = start_x
      y = y + space_between
    end
  end
end



function AchievementsPanel:die()
  self.dead = true
end
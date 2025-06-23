
FloatingText = Object:extend()
FloatingText:implement(GameObject)
function FloatingText:init(args)
  self:init_game_object(args)
  self.text = Text(self.lines, global_text_tags)
  self.w, self.h = self.text.w, self.text.h

  self.color = self.color or white[0]
  self.color = self.color:clone()

  self.duration = self.duration or 0
  self.fade_duration = self.fade_duration or 1
  self.start_time = Helper.Time.time
  self.scale = self.scale or 1
end

function FloatingText:update(dt)
  if self.dead then return end
  self.text:update(dt)
  
  local time_passed = Helper.Time.time - self.start_time
  if time_passed > self.duration + self.fade_duration then
    self:destroy()
  elseif time_passed > self.duration then
    local percentDissolved = (time_passed - self.duration) / self.fade_duration
    self.color.a = 1 - (1 * percentDissolved)
  end
end

function FloatingText:draw()
  if self.dead then return end
  graphics.set_color(self.color)
  self.text:draw(self.x, self.y, 0, self.scale, self.scale)
end

function FloatingText:destroy()
  self.text = nil
  self.dead = true
end
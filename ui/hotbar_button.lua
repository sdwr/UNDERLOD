

--hotbar helper functions
HotbarGlobals = Object:extend()
function HotbarGlobals:init(args)
  self.hotbar_by_index = {}
  self.selected_character = nil
  self.selected_index = nil
end

function HotbarGlobals:clear_hotbar()
  if self.hotbar_by_index then
    for i, button in ipairs(self.hotbar_by_index) do
      if button then
        button.dead = true
      end
    end
  end
  self.hotbar_by_index = {}
  
end

function HotbarGlobals:add_button(i, b)
  if not self.hotbar_by_index then self.hotbar_by_index = {} end

  if self.hotbar_by_index[i] then
    print('hotbar button already exists for index ' .. i)
    return
  end

  self.hotbar_by_index[i] = b
end

--need to deselect the previous button as well
--so store the index of the selected button
--but what is stored right now is the selected character
-- and used for movement etc

function HotbarGlobals:select_by_index(index)
  if not self.hotbar_by_index[index] then
    print('hotbar button does not exist for index ' .. index)
    return
  end

  if self.selected_index then
    self.hotbar_by_index[self.selected_index].selected = false
    self.hotbar_by_index[self.selected_index]:update_text()
  end
  self.selected_index = index
  self.hotbar_by_index[index].selected = true
  self.hotbar_by_index[index]:action()
  self.hotbar_by_index[index]:update_text()
end




--Hotbar button class
HotbarButton = Object:extend()
HotbarButton:implement(GameObject)
function HotbarButton:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, args.w or (pixul_font:get_text_width(self.button_text) + 8), pixul_font.h + 4)
  self.interact_with_mouse = true
  self.text = Text({{text = '[' .. self.fg_color .. ']' .. self.button_text, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.selected = false

  self.color_marks = args.color_marks or {}
  self.visible = args.visible or true
end

--clicking on buttons doesn't work
function HotbarButton:update(dt)
  if self.visible then
    self:update_game_object(dt)

    if self.hold_button then
      if self.selected and input.m1.pressed then
        self.press_time = love.timer.getTime()
        self.spring:pull(0.2, 200, 10)
      end
      if self.press_time then
        if input.m1.down and love.timer.getTime() - self.press_time > self.hold_button then
          self:action()
          self.press_time = nil
          self.spring:pull(0.1, 200, 10)
        end
      end
      if input.m1.released then
        self.press_time = nil
        self.spring:pull(0.1, 200, 10)
      end
    else
      if self.selected and input.m1.pressed then
        if self.action then
          self:action()
        end
      end
      if self.selected and input.m2.pressed then
        if self.action_2 then
          self:action_2()
        end
      end
    end
  end
end


function HotbarButton:draw()
  if self.visible then
    graphics.push(self.x, self.y, 0, self.spring.x, self.spring.y)
      if self.selected then
        graphics.rectangle(self.x, self.y, self.shape.w+2, self.shape.h+2, 4,4,  _G['white'][0], 3)
      end
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 4, 4, bg[0])
      
      self.text:draw(self.x, self.y + 1, 0, 1, 1)
      
    graphics.pop()

    for i, color_mark in ipairs(self.color_marks) do
      love.graphics.setColor(color_mark.r, color_mark.g, color_mark.b, 1)
      love.graphics.circle('fill', self.x - self.shape.w/2 + 10 + 8*(i - 1), self.y, 3)
    end
  end
end

function HotbarButton:action_animation()
  if main.current.in_credits and not self.credits_button then return end
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  
end

function HotbarButton:on_mouse_enter()
  Helper.mouse_on_button = true
  self:action_animation()
end


function HotbarButton:on_mouse_exit()
  if main.current.in_credits and not self.credits_button then return end

  Helper.mouse_on_button = false
end    


function HotbarButton:set_text(text)
  self.button_text = text
  self:update_text()
  self.spring:pull(0.2, 200, 10)
end

--for when selection changes, color of text changes
function HotbarButton:update_text()
  local color = self.selected and "yellow[0]" or "white[0]"
  self.text:set_text{{text = '[' .. color .. ']' .. self.button_text, font = pixul_font, alignment = 'center'}}
end
OwnedWeaponCard = Object:extend()
OwnedWeaponCard.__class_name = 'OwnedWeaponCard'
OwnedWeaponCard:implement(GameObject)

function OwnedWeaponCard:init(args)
  self:init_game_object(args)
  
  self.weapon_name = args.weapon_name
  self.level = args.level or 1
  self.count = args.count or 1
  self.index = args.index or 1
  
  -- Get weapon definition
  self.weapon_def = Get_Weapon_Definition(self.weapon_name)
  
  -- Card dimensions
  self.w = 50
  self.h = 20
  
  -- Position based on index
  self.x = args.x
  self.y = args.y
  
  -- Create shape for interaction
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  
  -- Title text showing level and name
  local level_text = self.level .. ' '
  local title_string = level_text .. self.weapon_name
  self.title_text = Text({{text = '[yellow]' .. title_string, font = pixul_font, alignment = 'center'}}, global_text_tags)
  
end

function OwnedWeaponCard:update(dt)
  self:update_game_object(dt)
  
  if self.shape then
    self.shape:move_to(self.x, self.y)
  end
end

function OwnedWeaponCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.2, 200, 10)
end

function OwnedWeaponCard:on_mouse_exit()
  self.selected = false
end

function OwnedWeaponCard:draw()
  graphics.push(self.x, self.y, 0, self.spring.x * self.sx, self.spring.x * self.sy)
  
  -- Background based on weapon level
  local bg_color = bg[2]
  if self.level == 2 then
    bg_color = green[-5]
  elseif self.level == 3 then
    bg_color = blue[-5]
  end
  
  -- Draw card background
  graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, bg_color)
  
  -- Draw border
  local border_color = self.selected and yellow[0] or fg[0]
  graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, nil, 2, border_color)
  
  -- Draw texts
  if self.title_text then
    self.title_text:draw(self.x, self.y - self.h/2 + 10)
  end
  
  graphics.pop()
end

function OwnedWeaponCard:die()
  self.dead = true
  
  if self.title_text then
    self.title_text.dead = true
    self.title_text = nil
  end
  
end
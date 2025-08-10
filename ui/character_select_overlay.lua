
--character select overlay
CharacterSelectOverlay = Object:extend()
CharacterSelectOverlay.__class_name = 'CharacterSelectOverlay'
CharacterSelectOverlay:implement(GameObject)
function CharacterSelectOverlay:init(args)
  self:init_game_object(args)
  self.cards = {}

  main.current.choose_character = true

  local unit1 = 'swordsman'
  local unit2 = 'archer'
  local unit3 = 'laser'

  --make overlay (opaque bg)
  self.overlay = Overlay{
    group = self.group,
    x = gw/2,
    y = gh/2,
    w = gw,
    h = gh
  }

  --dimensions for the cards
  local w = 80
  local w_between = 20
  local h = 120

  local x1 = gw/2 - w - w_between
  local x2 = gw/2
  local x3 = gw/2 + w + w_between
  local card_y = gh/2

  local unit1_locked = true
  local unit3_locked = true
  
  if USER_STATS.stompy_defeated >= 1 then
    unit1_locked = false
  end
  if USER_STATS.dragon_defeated >= 1 then
    unit3_locked = false
  end

  self.cards[1] = ShopCard{group = self.group, 
  x = x1, y = card_y, w = w, h = h, 
  unit = unit1, parent = self, i = 1, locked = unit1_locked}

  self.cards[2] = ShopCard{group = self.group, x = x2, y = card_y, w = w, h = h, unit = unit2, parent = self, i = 2}

  self.cards[3] = ShopCard{group = self.group, 
  x = x3, y = card_y, w = w, h = h, 
  unit = unit3, parent = self, i = 3, locked = unit3_locked}

  --disable clicking for the first .25 seconds
  self.interact_with_mouse = false
  self.t:after(0.25, function() self.interact_with_mouse = true end)
end

function CharacterSelectOverlay:draw()
  --pass
end

function CharacterSelectOverlay:update(dt)
  self:update_game_object(dt)
end

function CharacterSelectOverlay:die(index_selected)
  self.dead = true
  self.overlay:die()
  for i, card in ipairs(self.cards) do 
    local not_selected = index_selected ~= i
    card:die(not_selected) 
  end
end

Overlay = Object:extend()
Overlay.__class_name = 'Overlay'
Overlay:implement(GameObject)
function Overlay:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
end

function Overlay:draw()
  local color = bg[1]:clone()
  color.a = 0.8
  graphics.rectangle(self.x, self.y, self.w, self.h, nil, nil, color)
end

function Overlay:update(dt)
  self:update_game_object(dt)
end

function Overlay:die()
  self.dead = true

  main.current.choose_character = false
end


ShopCard = Object:extend()
ShopCard.__class_name = 'ShopCard'
ShopCard:implement(GameObject)
function ShopCard:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, self.w, self.h)
  self.interact_with_mouse = true
  self.character_icon = CharacterIcon{group = self.group, x = self.x, y = self.y - 26, character = self.unit, parent = self,
    text_on_mouseover = false}
  self.type_icons = {}
  local type = character_types[self.unit]
  local x = self.x
  table.insert(self.type_icons, TypeIcon{group = self.group, x = x + (0-1)*20, y = self.y + 6, type = type, character = self.unit, units = self.parent.units, parent = self})

  self.spring:pull(0.2, 200, 10)
end


function ShopCard:update(dt)
  self:update_game_object(dt)

  if (self.selected and input.m1.pressed and self.parent.interact_with_mouse) then
    if not main.current.buy_unit then
      print('cant buy unit')
      return
    end

    if self.locked then
      print('cant buy unit')
      return
    end

    main.current:buy_unit(self.unit)
    ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    _G[random:table{'coins1', 'coins2', 'coins3'}]:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.parent:die(self.i)
  end
end


function ShopCard:select()
  self.selected = true
  self.spring:pull(0.2, 200, 10)
  self.t:every_immediate(1.4, function()
    if self.selected then
      self.t:tween(0.7, self, {sx = 0.97, sy = 0.97, plus_r = -math.pi/32}, math.linear, function()
        self.t:tween(0.7, self, {sx = 1.03, sy = 1.03, plus_r = math.pi/32}, math.linear, nil, 'pulse_1')
      end, 'pulse_2')
    end
  end, nil, nil, 'pulse')
end


function ShopCard:unselect()
  self.selected = false
  self.t:cancel'pulse'
  self.t:cancel'pulse_1'
  self.t:cancel'pulse_2'
  self.t:tween(0.1, self, {sx = 1, sy = 1, plus_r = 0}, math.linear, function() self.sx, self.sy, self.plus_r = 1, 1, 0 end, 'pulse')
end


function ShopCard:draw()
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    if self.selected then
      graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, bg[0])
    else
      graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, bg[2])
    end
    graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, bg[1], 5)

    if self.locked then
      self.locked_size = self.w * 0.5
      self.locked_scale_x = (self.locked_size / LOCKED_W) * LOCKED_SCALE
      self.locked_scale_y = (self.locked_size / LOCKED_H) * LOCKED_SCALE
      locked_image:draw(self.x, self.y + 10, 0, self.locked_scale_x, self.locked_scale_y, 0, 0, bg[1])
    end
  graphics.pop()
end


function ShopCard:on_mouse_enter()
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  pop2:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  self.selected = true
  self.spring:pull(0.1)
  self.character_icon.spring:pull(0.1, 200, 10)
  for _, type_icon in ipairs(self.type_icons) do
    type_icon.selected = true
    type_icon.spring:pull(0.1, 200, 10)
  end
  
  -- Show info text for locked cards
  if self.locked then
    local unlock_text = ""
    if self.i == 1 then
      unlock_text = "Defeat Stompy (level 6) to unlock"
    elseif self.i == 3 then
      unlock_text = "Defeat the Dragon (level 11) to unlock"
    end
    
    if unlock_text ~= "" then
      self.info_text = InfoText{group = self.group, force_update = true}
      self.info_text:activate({
        {text = '[fg]' .. unlock_text, font = pixul_font, alignment = 'center'},
      }, nil, nil, nil, nil, 16, 4, nil, 2)
      self.info_text.x, self.info_text.y = self.x, self.y
    end
  end
end


function ShopCard:on_mouse_exit()
  self.selected = false
  for _, type_icon in ipairs(self.type_icons) do type_icon.selected = false end
  
  -- Remove info text when mouse leaves
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end


function ShopCard:die(dont_spawn_effect)
  self.dead = true
  self.character_icon:die(dont_spawn_effect)
  for _, type_icon in ipairs(self.type_icons) do type_icon:die(dont_spawn_effect) end
  if self.info_text then
    self.info_text:deactivate()
    self.info_text.dead = true
    self.info_text = nil
  end
end
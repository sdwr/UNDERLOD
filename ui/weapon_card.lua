require 'combat_stats/weapon_list'

WeaponCard = BaseCard:extend()
WeaponCard.__class_name = 'WeaponCard'

function WeaponCard:init(args)
  self.weapon_name = args.weapon_name
  self.weapon_def = Get_Weapon_Definition(self.weapon_name)
  
  -- Set up BaseCard properties (matching ItemCard pattern)
  args.name = self.weapon_def.display_name
  
  -- Try to find an image based on the icon field
  if self.weapon_def.icon then
    args.image = item_images[self.weapon_def.icon] or item_images['default']
  else
    args.image = item_images['default']
  end
  
  args.tier_color = fg[0]
  
  WeaponCard.super.init(self, args)
  
  -- Set cost after parent init
  self.cost = Get_Weapon_Cost(self.weapon_name)
  self.can_afford = gold >= self.cost
  
  -- Create cost text like ItemCard
  if self.cost > 0 then
    self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)
  end
  
  -- Create description text
  if self.weapon_def.description then
    self.bottom_text = Text({{text = '[fg]' .. self.weapon_def.description, font = pixul_font, alignment = 'center'}}, global_text_tags)
  end
  
  self.owned_count = self:get_owned_count()
  self.owned_level = self:get_owned_level()

  -- Check if this is an upgrade or new weapon
  self.is_upgrade = self.owned_count > 0 and self.owned_level < WEAPON_MAX_LEVEL
  self.is_maxed = self.owned_level >= WEAPON_MAX_LEVEL

  -- Update description with upgrade status
  local desc_lines = {}
  if self.weapon_def.description then
    table.insert(desc_lines, {text = '[fg]' .. self.weapon_def.description, font = pixul_font, alignment = 'center'})
  end
  if #desc_lines > 0 then
    self.bottom_text = Text(desc_lines, global_text_tags)
  end

  -- Update every frame to check affordability
  self.t:every(0.1, function()
    self.can_afford = gold >= self.cost
    if self.cost_text then
      local color = self.can_afford and '[yellow]' or '[red]'
      self.cost_text:set_text{{text = color .. self.cost, font = pixul_font, alignment = 'center'}}
    end
  end)
end

function WeaponCard:get_owned_count()
  if not self.parent or not self.parent.weapons then return 0 end
  
  for _, weapon in ipairs(self.parent.weapons) do
    if weapon.name == self.weapon_name then
      return weapon.count or 1
    end
  end
  return 0
end

function WeaponCard:get_owned_level()
  if not self.parent or not self.parent.weapons then return 0 end
  
  for _, weapon in ipairs(self.parent.weapons) do
    if weapon.name == self.weapon_name then
      return weapon.level or 1
    end
  end
  return 0
end

function WeaponCard:update(dt)
  WeaponCard.super.update(self, dt)
  
  -- Update owned count/level
  self.owned_count = self:get_owned_count()
  self.owned_level = self:get_owned_level()
  
  -- Handle clicking
  if input.m1.pressed and self.selected then
    self:on_click()
  end
end

function WeaponCard:on_click()
  -- Check if weapon is already at max level
  if self.owned_level >= WEAPON_MAX_LEVEL then
    error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)

    if not self.error_text then
      self.error_text = InfoText{group = main.current.ui}
      self.error_text:activate({
        {text = '[fg]weapon at max level', font = pixul_font, alignment = 'center'},
      }, nil, nil, nil, nil, 16, 4, nil, 2)
      self.error_text.x, self.error_text.y = self.x, self.y - 40
      self.t:after(1.5, function()
        if self.error_text then
          self.error_text:deactivate()
          self.error_text.dead = true
          self.error_text = nil
        end
      end)
    end
    return
  end

  if self.can_afford then
    self:buy()
  else
    -- Not enough gold feedback
    error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)

    -- Show not enough gold text
    if not self.error_text then
      self.error_text = InfoText{group = main.current.ui}
      self.error_text:activate({
        {text = '[fg]not enough gold', font = pixul_font, alignment = 'center'},
      }, nil, nil, nil, nil, 16, 4, nil, 2)
      self.error_text.x, self.error_text.y = self.x, self.y - 40
      self.t:after(1.5, function()
        if self.error_text then
          self.error_text:deactivate()
          self.error_text.dead = true
          self.error_text = nil
        end
      end)
    end
  end
end

function WeaponCard:buy()
  if gold < self.cost then return end

  -- Check if weapon is already at max level
  if self.owned_level >= WEAPON_MAX_LEVEL then
    Create_Info_Text('weapon at max level', self, 'error')
    error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    return
  end

  -- Deduct gold
  gold = gold - self.cost
  self.parent.gold = gold

  -- Add weapon to parent's weapons
  if self.parent then
    self.parent:add_weapon(self.weapon_name)
  end
  
  -- Sound effect
  if gold1 then
    gold1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
  end
  
  -- Update state
  self.owned_count = self:get_owned_count()
  self.owned_level = self:get_owned_level()

  -- Clear shop data and refresh cards (like ItemCard does)
  if self.parent then
    self.parent.shop_weapon_data[self.i] = nil
    self.parent:save_run()
    if self.parent.set_party then
      self.parent:set_party()
    end
  end

  if self.parent.on_item_purchased then
    self.parent:on_item_purchased(nil, nil, self.weapon_name)
  end

  self:die()
  return true
end

function WeaponCard:on_mouse_enter()
  WeaponCard.super.on_mouse_enter(self)

  -- Highlight target slot if can afford
  if self.can_afford and self.parent and self.parent.get_weapon_target_slot then
    local target_card, is_upgrade = self.parent:get_weapon_target_slot(self.weapon_name)
    if target_card then
      target_card.highlight_target = true
    end
  end
end

function WeaponCard:on_mouse_exit()
  WeaponCard.super.on_mouse_exit(self)

  -- Clear highlights
  if self.parent and self.parent.clear_all_highlights then
    self.parent:clear_all_highlights()
  end
end

function WeaponCard:draw()
  -- Let BaseCard handle the main drawing
  self:draw_base_card()

  -- Draw upgradeable glow border if this weapon can upgrade an existing one
  if self.owned_count > 0 and self.owned_level < WEAPON_MAX_LEVEL then
    -- Draw a glowing green border overlay
    local glow_color = green[0]:clone()
    glow_color.a = 0.3  -- Slightly brighter
    graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)
    graphics.rectangle(self.x, self.y, self.w, self.h, 6, 6, nil, 3, glow_color)  -- Border only
    graphics.pop()
  end
end

function WeaponCard:die()
  WeaponCard.super.die(self)
end
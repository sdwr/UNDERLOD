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
  
  -- Set tier color based on cost
  if self.weapon_def.cost <= 2 then
    args.tier_color = fg[0]  -- Common
  elseif self.weapon_def.cost <= 4 then
    args.tier_color = green[0]  -- Uncommon
  else
    args.tier_color = blue[0]  -- Rare
  end
  
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
end

function WeaponCard:on_click()
  if self.can_afford then
    self:buy()
  else
    -- Not enough gold feedback
    error1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    self.spring:pull(0.2, 200, 10)
  end
end

function WeaponCard:buy()
  if gold < self.cost then return end
  
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
end

function WeaponCard:draw()
  -- Let BaseCard handle the main drawing
  self:draw_base_card()
end

function WeaponCard:die()
  self.dead = true
end
PerksPanel = Object:extend()
PerksPanel:implement(GameObject)

function PerksPanel:init(args)
  self:init_game_object(args)
  
  -- Panel properties
  self.x = args.x or gw - 100
  self.y = args.y or 20
  self.width = args.width or 80
  self.slot_size = 32
  self.slot_spacing = 8
  self.perks = args.perks or {}
  
  -- Create title text
  self.title = Text2{
    group = self.group,
    x = self.x + self.width/2,
    y = self.y,
    lines = {{text = 'perks', font = pixul_font, alignment = 'center'}},
    fg_color = 'white'
  }
  
  -- Create perk slots
  self.slots = {}
  for i = 1, 5 do
    local slot_y = self.y + 20 + (i-1) * (self.slot_size + self.slot_spacing)
    self.slots[i] = {
      x = self.x + (self.width - self.slot_size) / 2,
      y = slot_y,
      perk = nil
    }
  end
end

function PerksPanel:update(dt)
  self:update_game_object(dt)
end

function PerksPanel:draw()
  -- Draw title (handled by Text2 object)
  
  -- Draw perk slots
  for i, slot in ipairs(self.slots) do
    -- Draw slot background (empty slot)
    graphics.rectangle(slot.x + self.slot_size/2, slot.y + self.slot_size/2, 
                      self.slot_size, self.slot_size, 4, 4, 
                      bg[0])
    
    -- Draw slot border
    graphics.rectangle(slot.x + self.slot_size/2, slot.y + self.slot_size/2, 
                      self.slot_size, self.slot_size, 4, 4, 
                      slot.perk and fg[0] or bg[5], 1)
    
    -- Draw perk if it exists
    if slot.perk then
      -- TODO: Draw perk icon/name
      graphics.rectangle(slot.x + self.slot_size/2, slot.y + self.slot_size/2, 
                        self.slot_size - 4, self.slot_size - 4, 3, 3, 
                        fg[0])
    end
  end
end

function PerksPanel:set_perks(perks)
  self.perks = perks or {}
  
  -- Update slots with perks
  for i, slot in ipairs(self.slots) do
    slot.perk = self.perks[i]
  end
end

function PerksPanel:add_perk(perk)
  -- Find first empty slot
  for i, slot in ipairs(self.slots) do
    if not slot.perk then
      slot.perk = perk
      table.insert(self.perks, perk)
      return true
    end
  end
  return false -- No empty slots
end

function PerksPanel:remove_perk(index)
  if self.perks[index] then
    table.remove(self.perks, index)
    -- Rebuild slots
    for i, slot in ipairs(self.slots) do
      slot.perk = self.perks[i]
    end
    return true
  end
  return false
end 
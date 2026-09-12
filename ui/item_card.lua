local card_theme
local function get_card_theme()
  if not card_theme then
    card_theme = {
      common = Color('#1f2125'), rare = Color('#302d24'), border = Color('#61666b'),
      gold = Color('#deb561'), text = Color('#dadad4'), muted = Color('#888d90'),
      shadow = Color('#141619'), divider = Color('#434749'),
      fonts = {[4] = Font('PixulBrush', 4), [5] = Font('PixulBrush', 5),
        [6] = Font('PixulBrush', 6), [8] = Font('PixulBrush', 8), [10] = Font('PixulBrush', 10)},
    }
  end
  return card_theme
end

local function card_box(x, y, w, h, color)
  local c = math.min(3, w/4, h/4)
  graphics.polygon({x+c,y, x+w-c,y, x+w,y+c, x+w,y+h-c,
    x+w-c,y+h, x+c,y+h, x,y+h-c, x,y+c}, color)
end

local function card_print(text, font, x, y, color, max_width)
  local scale = math.min(1, (max_width or math.huge) / math.max(font:get_text_width(text), 1))
  graphics.print(text, font, x, y, 0, scale, scale, 0, 0, color)
end

local function card_wrap(text, font, width)
  local lines = {}
  for paragraph in (text .. string.char(10)):gmatch('(.-)' .. string.char(10)) do
    local line = ''
    for word in paragraph:gmatch('%S+') do
      if line ~= '' and font:get_text_width(line .. ' ' .. word) > width then
        lines[#lines+1], line = line, word
      else
        line = line == '' and word or line .. ' ' .. word
      end
    end
    if line ~= '' then lines[#lines+1] = line end
  end
  return lines
end

local function card_set_color(theme, name)
  theme.set_colors = theme.set_colors or {}
  if not theme.set_colors[name] then
    local color = (_G[name] or orange)[0]:clone()
    if name == 'purple' or name == 'brown' then
      color.r, color.g, color.b = math.min(1,color.r+0.16), math.min(1,color.g+0.16), math.min(1,color.b+0.16)
    end
    theme.set_colors[name] = color
  end
  return theme.set_colors[name]
end

--find a way for clicks to buy into first empty slot
--need either a time check or distance check
--so that if you click and drag, you can drop halfway to cancel the buy
ItemCard = BaseCard:extend()
function ItemCard:init(args)
  -- Set up item-specific properties before calling super
  self.item = args.item
  args.image = nil  -- item cards no longer show the icon; set name/summary instead
  args.colors = nil  -- no colored stripe on the top half
  self.card_theme = get_card_theme()
  args.tier_color = self.item.rarity == ITEM_RARITY.RARE and self.card_theme.gold or self.card_theme.border
  args.name = self.item.name
  
  -- Call parent constructor
  ItemCard.super.init(self, args)
  
  -- Item-specific properties
  self.cost = self.item.cost or 0
  self.stats = self.item.stats
  self.sets = self.item.sets
  self.origX = self.x
  self.origY = self.y

  -- Item card specific behavior
  self.timeGrabbed = 0
  self.buyTimer = 0.2
  self.grabbed = false
  self.grab_offset_x = 0
  self.grab_offset_y = 0
  
  -- Scaling behavior near character slots
  self.base_scale = 1
  self.current_scale = 1
  self.shrink_threshold_y = gh/2 - 25 + 80 -- Character card Y + some buffer

  -- Title hover regions and card content.
  self.set_bonus_elements = {}
  self.set_defs = {}
  self.set_keys = {}
  self.set_desc_texts = {}
  self.set_layout = {}
  if self.sets then
    self:create_set_bonus_elements()
  end
  self.set_button_hovered = false

  -- Setless items (or items whose sets were removed) fall back to the old stat
  -- line so the card is not blank.
  if #self.set_bonus_elements == 0 then
    self:create_stats_text()
  else
    self:layout_set_summaries()
  end

  -- Play creation effect
  self:creation_effect()
end

function ItemCard:create_set_bonus_elements()
  for _, set_key in pairs(self.sets) do
    local def = ITEM_SETS[set_key]
    if def then
      table.insert(self.set_defs, def)
      table.insert(self.set_keys, set_key)
      table.insert(self.set_bonus_elements, {
        set_info = def, set_key = set_key, selected = false,
        shape = Rectangle(self.x, self.y, self.w - 10, 12),
      })
    end
  end
end

function ItemCard:build_set_summary(set_def)
  local description = (set_def.descriptions and set_def.descriptions[1]) or ''
  if set_def.rarity == ITEM_RARITY.COMMON then
    local short = description:match('^[^;]+') or description
    short = short:gsub('%s*%b()', '')
    local amount, detail = short:match('^(%+[%d%.]+%%?)%s+(.+)$')
    if amount then return detail:gsub('damage per hit', 'damage / hit'), amount end
  end
  if set_def.summary == 'chain lightning' then
    local chance = description:match('^(%d+%%)')
    local count = description:match('through (%d+) enemies')
    if chance and count then return 'Chain to ' .. count .. string.char(10) .. 'enemies' .. string.char(10) .. chance .. ' on hit' end
  end
  local summary = set_def.summary or description
  return (summary:gsub('^%l', string.upper))
end

function ItemCard:layout_set_summaries()
  local n = #self.set_defs
  self.set_layout = {}
  for i, def in ipairs(self.set_defs) do
    local summary, amount = self:build_set_summary(def)
    local region = 46 / n
    local title_font = self.card_theme.fonts[n == 1 and 8 or 6]
    if title_font:get_text_width(def.name) > self.w - 10 then title_font = self.card_theme.fonts[6] end
    local description_font = self.card_theme.fonts[n == 1 and 5 or 4]
    if n > 1 and amount then summary, amount = amount .. ' ' .. summary, nil end
    self.set_layout[i] = {
      top = 19 + (i-1)*region, description_offset = n == 1 and 15 or 9, title_font = title_font, description_font = description_font,
      amount = amount, lines = card_wrap(summary, description_font, self.w - 10),
      description_room = n == 1 and (amount and 18 or 30) or region - 9,
    }
  end
end

function ItemCard:compute_set_progress(set_key, set_def)
  local total, owned = 0, 0
  for k in pairs(set_def.descriptions or set_def.bonuses or {}) do
    if type(k) == 'number' then total = math.max(total, k) end
  end
  if self.preview_unit then
    owned = Helper.Unit:count_unit_set_pieces(self.preview_unit)[set_key] or 0
  elseif self.parent and self.parent.units then
    for _, unit in ipairs(self.parent.units) do
      owned = math.max(owned, Helper.Unit:count_unit_set_pieces(unit)[set_key] or 0)
    end
  end
  return math.min(owned + 1, total), total, math.min(owned, total)
end

function ItemCard:create_stats_text()
  local stats_lines = {}

  --add blank lines so the stats show up below the set buttons
  if self.sets then
    for _, set_key in pairs(self.sets) do
      local set_def = ITEM_SETS[set_key]
      if set_def then
        table.insert(stats_lines, {text = '', font = pixul_font, alignment = 'center'})
      end
    end
  end

  if self.stats then
    for key, val in pairs(self.stats) do
      local text = ''
      local display_name = item_stat_lookup and item_stat_lookup[key] or key
      if type(val) == 'number' then
        if key == 'gold' then
          text = '[yellow]+' .. val .. ' ' .. display_name
        elseif ITEM_STATS and ITEM_STATS[key] and ITEM_STATS[key].increment then
          text = '[yellow]+' .. val .. ' ' .. display_name
        else
          text = '[yellow]+' .. val .. ' ' .. display_name
        end
      else
        text = '[yellow]+' .. display_name
      end
      table.insert(stats_lines, {text = text, font = pixul_font, alignment = 'center'})
    end
  end
  
  if #stats_lines > 0 then
    self.bottom_text = Text(stats_lines, global_text_tags)
  else
    self.bottom_text = nil
  end
end

-- wrap_text is now inherited from BaseCard

-- creation_effect is now inherited from BaseCard

function ItemCard:find_item_part_at_position(x, y)
  -- Check all character cards for ItemParts at this position
  if not Character_Cards then return nil, nil end
  
  for _, card in ipairs(Character_Cards) do
    if card.items then
      for _, item_part in ipairs(card.items) do
        if item_part.shape and item_part.shape:is_colliding_with_point(x, y) then
          return item_part, card.unit
        end
      end
    end
  end
  return nil, nil
end

function ItemCard:handle_purchase_transaction()
  -- One-shot: mark this card spent so a second quick click during the fly-out
  -- animation can't buy it again (double-buy).
  self.purchased = true

  -- Handle the gold transaction and bookkeeping
  gold2:play{pitch = random:float(0.95, 1.05), volume = 1}
  gold = gold - self.cost

  if self.cost > 10 then
    Stats_Current_Run_Over10Cost_Items_Purchased()
  end
  self.parent.shop_item_data[self.i] = nil
  self.parent:save_run()
end

function ItemCard:buy_item_to_slot(item_part, unit)
  -- Guard against a second purchase from the same card (double-buy).
  if self.purchased or self.flying_to_slot then return false end

  -- Use the same logic as the existing buy_item but for a specific slot
  local slot_index = item_part.i
  
  -- Check if this unit has this slot and it's empty
  if unit.items[slot_index] then
    Create_Info_Text('slot occupied', self, 'error')
    return false
  end

  -- Distinct-item cap / per-item stack cap.
  local why = Helper.Unit:item_blocked_reason_for_unit(unit, self.item)
  if why then
    Create_Info_Text(Helper.Unit:blocked_reason_text(why), self, 'error')
    return false
  end

  -- Check gold (same as existing)
  if gold < self.cost then
    Create_Info_Text('not enough gold', self, 'error')
    return false
  end
  
  -- Handle purchase transaction
  self:handle_purchase_transaction()
  unit.items[slot_index] = self.item

  -- Create particle effect at the target slot
  item_part:create_item_added_effect(self.item)

  -- Notify buy screen that an item was purchased
  if self.parent.on_item_purchased then
    self.parent:on_item_purchased(unit, slot_index, self.item)
  end

  self:die()
  return true
end

function ItemCard:update_scale_based_on_position()
  if not self.grabbed then return end
  
  local character_y = gh/2 - 25 -- Character card Y position from buy_screen.lua:359
  local distance_to_chars = math.abs(self.y - character_y)
  
  -- Also check radius from character card area
  local char_area_x = gw/2 -- Approximate center of character area
  local char_area_y = character_y
  local radius_to_chars = math.sqrt((self.x - char_area_x)^2 + (self.y - char_area_y)^2)
  
  -- Use whichever distance is smaller (y-axis or radius)
  local effective_distance = math.min(distance_to_chars, radius_to_chars)
  
  -- Scale from 1.0 to ItemPart size based on distance (closer = smaller)
  local max_distance = 100 -- Distance at which scaling begins
  local min_scale = ITEM_PART_WIDTH / self.w -- ItemPart size / ItemCard size
  local max_scale = 1.0
  
  if effective_distance < max_distance then
    local scale_factor = effective_distance / max_distance
    self.current_scale = min_scale + (max_scale - min_scale) * scale_factor
  else
    self.current_scale = max_scale
  end
  
  -- Make it squish to square when shrinking (adjust height scale)
  local target_aspect_ratio = ITEM_PART_WIDTH / ITEM_PART_HEIGHT -- Should be 1.0 (square)
  local current_aspect_ratio = self.w / self.h -- 60/80 = 0.75
  
  if self.current_scale < 1.0 then
    -- Adjust height scaling to make it more square-like as it shrinks
    local square_factor = 1.0 - (1.0 - self.current_scale) * 0.5 -- Gentler height adjustment
    self.sx = self.current_scale
    self.sy = self.current_scale * (current_aspect_ratio / target_aspect_ratio) * square_factor
  else
    self.sx = self.current_scale
    self.sy = self.current_scale
  end
end

function ItemCard:buy_item()
  -- Guard against a second purchase from the same card (double-buy).
  if self.purchased or self.flying_to_slot then return end

  -- Use Helper.Unit to find available slot
  local unit, slot_index = Helper.Unit:find_available_inventory_slot(self.parent.units, self.item)

  if not unit or not slot_index then
    Create_Info_Text(Helper.Unit:item_blocked_text(self.parent.units, self.item) .. ' - drag to a unit title for xp', self, 'error')
    self.x = self.origX
    self.y = self.origY
    return
  end
  
  -- Find the target ItemPart for animation
  local target_item_part = nil
  if Character_Cards then
    for _, card in ipairs(Character_Cards) do
      if card.unit == unit and card.items then
        for _, item_part in ipairs(card.items) do
          if item_part.i == slot_index then
            target_item_part = item_part
            break
          end
        end
      end
      if target_item_part then break end
    end
  end
  
  if target_item_part then
    -- Start flying animation
    self:start_buy_animation(target_item_part, unit, slot_index)
  else
    -- Fallback to immediate purchase if can't find target
    self:complete_purchase(unit, slot_index)
  end
end

function ItemCard:start_buy_animation(target_item_part, unit, slot_index)
  -- Handle purchase transaction immediately
  self:handle_purchase_transaction()

  -- Assign the item to the slot NOW, not when the fly-in animation finishes.
  -- Otherwise a second quick purchase runs find_available_inventory_slot while
  -- this slot still reads empty, picks it too, and overwrites this item. The
  -- ItemPart stays hidden during the flight; the callback just reveals it.
  unit.items[slot_index] = self.item
  target_item_part.hide_item_display = true
  -- Tie the hide to this flier so the slot self-heals if we die before arriving.
  target_item_part.incoming_flier = self

  -- Disable mouse interaction during animation
  self.interact_with_mouse = false
  self.flying_to_slot = true

  -- Animate towards the target slot
  local duration = 0.2
  self.t:tween(duration, self, {
    x = target_item_part.x,
    y = target_item_part.y,
    sx = ITEM_PART_WIDTH / self.w,
    sy = ITEM_PART_HEIGHT / self.h
  }, math.out_cubic, function()
    -- Animation complete - reveal the item and fire the effects.
    target_item_part.hide_item_display = false

    -- Create particle effect at the target slot
    target_item_part:create_item_added_effect(self.item)

    -- Notify buy screen that an item was purchased
    if self.parent.on_item_purchased then
      self.parent:on_item_purchased(unit, slot_index, self.item)
    end

    self:die()
  end)
end

-- Buys the item straight into xp: costs gold, grants ITEM_SELL_XP to the
-- unit whose title it was dropped on. No item changes hands.
function ItemCard:convert_to_xp(card)
  if self.purchased or self.flying_to_slot then return false end
  if not card or not card.unit then return false end
  if gold < self.cost then
    Create_Info_Text('not enough gold', self, 'error')
    self.x = self.origX
    self.y = self.origY
    return false
  end

  coins1:play{pitch = random:float(0.8, 1.2), volume = 1}
  Add_Unit_XP(card.unit, ITEM_SELL_XP)
  Stats_Sell_Item()
  -- Transaction after the xp so the save it triggers captures the new xp/level.
  self:handle_purchase_transaction()
  self:die()
  return true
end

function ItemCard:complete_purchase(unit, slot_index)
  -- Immediate purchase without animation
  self:handle_purchase_transaction()
  unit.items[slot_index] = self.item

  -- Notify buy screen that an item was purchased
  if self.parent.on_item_purchased then
    self.parent:on_item_purchased(unit, slot_index, self.item)
  end

  self:die()
end

function ItemCard:update(dt)
  if self.dead then return end
  ItemCard.super.update(self, dt)

  if input.m1.pressed and self.colliding_with_mouse and not self.grabbed
     and not self.purchased and not self.flying_to_slot then
    -- Grabbing only needs gold; a full inventory can still drag onto a unit
    -- title to convert the item into xp.
    if gold >= self.cost then
      self.timeGrabbed = love.timer.getTime()
      self.grabbed = true
      Grabbed_Shop_Card = self

      -- Store the mouse offset from card center when grabbing
      local mouse_x, mouse_y = camera:get_mouse_position()
      self.grab_offset_x = mouse_x - self.x
      self.grab_offset_y = mouse_y - self.y

      self:remove_set_bonus_tooltip()

    else
      self:remove_set_bonus_tooltip()
      Create_Info_Text('not enough gold', self, 'error')

    end
  end

  --determine when to purchase the item vs when to cancel the purchase
  --should be able to click to buy?
  --but also cancel by letting go if you drag it halfway
  --leave this for now, kinda confusing to track the mouse position or duration of click
  -- and have 2 different ways to cancel the purchase
  if self.grabbed and input.m1.released then
    self.grabbed = false
    if Grabbed_Shop_Card == self then Grabbed_Shop_Card = nil end

    -- Check if dropped over an item slot or a card title
    local mouse_x, mouse_y = camera:get_mouse_position()
    local item_part, unit = self:find_item_part_at_position(mouse_x, mouse_y)
    local title_card = Find_Character_Card_Title_At(mouse_x, mouse_y)

    -- Reset scaling when released
    self.current_scale = 1.0
    self.sx = 1.0
    self.sy = 1.0

    if love.timer.getTime() - self.timeGrabbed < self.buyTimer then
      -- Quick click - use normal buy logic
      self:buy_item()
    elseif title_card then
      -- Dropped on a unit title - buy straight into xp
      self:convert_to_xp(title_card)
    elseif item_part and unit then
      -- Dropped over an item slot - try to buy to that specific slot
      if not self:buy_item_to_slot(item_part, unit) then
        self.x = self.origX
        self.y = self.origY
      end
    else
      -- Dropped anywhere else on a unit card - buy into its first empty slot
      local card = Find_Character_Card_At(mouse_x, mouse_y)
      local target_part = card and card:first_empty_item_part()
      if target_part and self:buy_item_to_slot(target_part, card.unit) then
        -- bought
      elseif card then
        if not target_part then
          Create_Info_Text('no room - drop on the title for xp', self, 'error')
        end
        self.x = self.origX
        self.y = self.origY
      else
        -- Dropped elsewhere - return to original position
        self.x = self.origX
        self.y = self.origY
      end
    end
  end

  if self.grabbed then
    local mouse_x, mouse_y = camera:get_mouse_position()
    self.x = mouse_x - self.grab_offset_x
    self.y = mouse_y - self.grab_offset_y
    
    -- Calculate scaling based on proximity to character slots
    self:update_scale_based_on_position()
    
    self:remove_set_bonus_tooltip()
  end

  self.preview_unit = nil
  if self.grabbed then
    local card = Find_Character_Card_At(camera:get_mouse_position())
    self.preview_unit = card and card.unit
  end

  local x, y, sx, sy = self:card_transform()
  local hovered
  for i, button in ipairs(self.set_bonus_elements) do
    local layout = self.set_layout[i]
    button.x = x
    button.y = y + (-self.h/2 + layout.top + 5) * sy
    button.shape:move_to(button.x, button.y)
    button.selected = not self.grabbed and not self.flying_to_slot
      and button.shape:is_colliding_with_point(camera:get_mouse_position())
    if button.selected then hovered = button end
  end
  if hovered then
    local progress = self:compute_set_progress(hovered.set_key, hovered.set_info)
    if self.tooltip_set_key ~= hovered.set_key or self.tooltip_progress ~= progress then
      self:show_set_bonus_tooltip(hovered.set_info, hovered.set_key)
      self.tooltip_set_key, self.tooltip_progress = hovered.set_key, progress
    end
    self.set_button_hovered = true
  else
    self:remove_set_bonus_tooltip()
  end
end

function ItemCard:show_set_bonus_tooltip(set_info, set_key)
  if self.dead then return end

  -- Preview the tier this purchase would reach: the expected after-buy bonuses
  -- are colored the set color, the rest greyed.
  local pieces = 0
  if set_key then
    pieces = (self:compute_set_progress(set_key, set_info))
  end
  local text_lines = DrawUtils.build_set_bonus_tooltip_text(set_info, pieces)

  self:remove_set_bonus_tooltip()

  self.set_bonus_tooltip = InfoText{group = self.parent.ui_top or self.group, force_update = false}
  self.set_bonus_tooltip:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local tooltip_height = self.set_bonus_tooltip.text.h + 4
  local pos = {x = gw/2, y = math.max(tooltip_height/2+4, gh-90-tooltip_height/2)}
  self.set_bonus_tooltip.x = pos.x
  self.set_bonus_tooltip.y = pos.y
end

function ItemCard:card_transform()
  local x, y = self.x, self.y
  if self.grabbed and self.current_scale < 1 then
    local mx, my = camera:get_mouse_position()
    x, y = x + (mx-x)*(1-self.current_scale), y + (my-y)*(1-self.current_scale)
  elseif self.selected and not self.flying_to_slot then
    y = y - 2
  end
  return x, y, self.sx*self.spring.x, self.sy*self.spring.x
end

function ItemCard:draw()
  if not self.item then return end
  local cx, cy, sx, sy = self:card_transform()
  graphics.push(cx, cy, 0, sx, sy)
  self:draw_card_contents(cx-self.w/2, cy-self.h/2)
  graphics.pop()
end

function ItemCard:draw_card_contents(x, y)
  local theme, fonts = self.card_theme, self.card_theme.fonts
  local rare = self.item.rarity == ITEM_RARITY.RARE
  local background = rare and theme.rare or theme.common
  local border = rare and theme.gold or theme.border
  local w, h = self.w, self.h
  card_box(x+1, y+2, w, h, theme.shadow)
  if self.selected and not self.flying_to_slot then card_box(x-1,y-1,w+2,h+2,theme.text) end
  card_box(x,y,w,h,border)
  card_box(x+1,y+1,w-2,h-2,background)
  if rare then
    graphics.rectangle(x+w/2,y+8,w-6,10,0,0,theme.gold)
    graphics.polygon({x+7,y+6, x+9,y+8, x+7,y+10, x+5,y+8}, theme.common)
    card_print('RARE',fonts[5],x+11,y+4,theme.common,w-30)
    graphics.rectangle(x+7,y+h-4,8,1,0,0,theme.gold)
    graphics.rectangle(x+w-7,y+h-4,8,1,0,0,theme.gold)
  else
    card_print('COMMON',fonts[5],x+5,y+4,theme.muted,w-23)
  end
  local price_width = math.max(14, fonts[6]:get_text_width(tostring(self.cost))+9)
  graphics.rectangle(x+w-3-price_width/2,y+8,price_width,10,0,0,theme.common)
  local price_color = gold and gold < self.cost and theme.muted or yellow[0]
  graphics.circle(x+w-price_width,y+8,2,price_color)
  graphics.line(x+w-price_width,y+7,x+w-price_width,y+9,theme.common,1)
  card_print(tostring(self.cost),fonts[6],x+w-price_width+4,y+4,price_color)

  for i, def in ipairs(self.set_defs) do
    local layout = self.set_layout[i]
    local color = card_set_color(theme, def.color or 'orange')
    card_print(def.name,layout.title_font,x+5,y+layout.top,color,w-10)
    local desc_y = y+layout.top+layout.description_offset
    if layout.amount then
      card_print(layout.amount,fonts[10],x+5,desc_y,theme.text,w-10)
      desc_y = desc_y+12
    end
    local line_height = layout.description_font.h
    local scale = math.min(1, layout.description_room / math.max(#layout.lines*line_height,1))
    for j, line in ipairs(layout.lines) do
      graphics.push(x+5,desc_y,0,1,scale)
      card_print(line,layout.description_font,x+5,desc_y+(j-1)*line_height,theme.text,w-10)
      graphics.pop()
    end
  end
  if #self.set_defs == 0 then
    card_print(self.item.name or 'Item',fonts[6],x+5,y+20,theme.text,w-10)
    if self.bottom_text then
      local scale = math.min(1,(w-10)/math.max(self.bottom_text.w,1),36/math.max(self.bottom_text.h,1))
      graphics.push(x+w/2,y+43,0,scale,scale)
      self.bottom_text:draw(x+w/2,y+43)
      graphics.pop()
    end
  end
  graphics.rectangle(x+w/2,y+h-14,w-10,1,0,0,theme.divider)
  for i, def in ipairs(self.set_defs) do
    local next_piece, total, owned = self:compute_set_progress(self.set_keys[i], def)
    local color = card_set_color(theme, def.color or 'orange')
    local spacing = math.min(9,(w-12)/math.max(total,1))
    local left = x+w/2-(total-1)*spacing/2
    local py = y+h-7-(#self.set_defs-i)*5
    for n=1,total do
      local px = left+(n-1)*spacing
      graphics.rectangle(px,py,6,3,0,0,n <= next_piece and color or theme.border)
      if n > owned and n <= next_piece then
        graphics.rectangle(px,py,4,1,0,0,background)
      end
    end
  end
end

function ItemCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.5}
  self.spring:pull(0.06, 200, 10)

  -- Light up every set-bonus cell on every unit card whose set this shop item
  -- contributes to. Mirrors ItemPart's same-card behaviour, but spans all
  -- units since a shop item can be bought onto any of them.
  if self.item and self.item.sets and Character_Cards then
    for _, set_key in ipairs(self.item.sets) do
      for _, card in ipairs(Character_Cards) do
        if card.set_bonus_elements then
          for _, cell in ipairs(card.set_bonus_elements) do
            if cell.set_info and cell.set_info.key == set_key then
              cell.highlighted = true
            end
          end
        end
      end
    end
  end
end

function ItemCard:on_mouse_exit()
  ItemCard.super.on_mouse_exit(self)
  self:remove_set_bonus_tooltip()

  -- Clear set-bonus highlights on every unit card. Idempotent and cheap.
  if Character_Cards then
    for _, card in ipairs(Character_Cards) do
      if card.set_bonus_elements then
        for _, cell in ipairs(card.set_bonus_elements) do
          cell.highlighted = false
        end
      end
    end
  end
end

function ItemCard:die()
  if Grabbed_Shop_Card == self then Grabbed_Shop_Card = nil end
  -- Clean up ItemCard-specific elements
  self:remove_set_bonus_tooltip()
  for _, set_button in ipairs(self.set_bonus_elements) do
    set_button.dead = true
  end
  for _, t in pairs(self.set_desc_texts or {}) do
    t.dead = true
  end
  self.set_desc_texts = {}
  if self.progress_text then
    self.progress_text.dead = true
    self.progress_text = nil
  end

  -- Call parent die method
  ItemCard.super.die(self)
end

function ItemCard:remove_set_bonus_tooltip()
  self.tooltip_set_key, self.tooltip_progress = nil, nil
  self.set_button_hovered = false

  if self.set_bonus_tooltip then
    self.set_bonus_tooltip:deactivate()
    self.set_bonus_tooltip:die()
    self.set_bonus_tooltip.dead = true
    self.set_bonus_tooltip = nil
  end
end
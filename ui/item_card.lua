--find a way for clicks to buy into first empty slot
--need either a time check or distance check
--so that if you click and drag, you can drop halfway to cancel the buy
ItemCard = BaseCard:extend()
function ItemCard:init(args)
  -- Set up item-specific properties before calling super
  self.item = args.item
  args.image = nil  -- item cards no longer show the icon; set name/summary instead
  args.colors = nil  -- no colored stripe on the top half
  args.tier_color = self.item.tier_color or item_to_color(self.item)
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

  -- Create cost text, pinned to the very top-right corner
  if self.cost > 0 then
    self.cost_text = Text({{text = '[yellow]' .. self.cost, font = pixul_font, alignment = 'center'}}, global_text_tags)
    self.cost_offset_x = self.w/2 - 5
    self.cost_offset_y = -self.h/2 + 6
  end

  -- Set bonus elements (hoverable title buttons) + per-set summary text
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
  -- line so the card isn't blank; set items use the name/summary/x-of-x layout.
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
    local set_def = ITEM_SETS[set_key]
    -- Item rolled with a set that has since been removed from ITEM_SETS
    -- (e.g. an older save's stone_cold/blazin reference). Skip silently
    -- rather than crashing the buy screen.
    if not set_def then goto continue end
    local color = set_def.color or 'orange'

    local set_button = Button{
      group = self.group,
      parent = self,
      x = 0, -- positioned each frame in update()
      y = 0,
      bg_color = 'bg',
      selected_bg_color = fg[-5],
      fg_color = color,
      button_text = set_def.name or "unknown set",
      action = function() end, -- No action on click, just hover
      set_info = set_def, -- Store set info for hover
      set_key = set_key, -- Used to compute the expected-after-purchase tier
      no_spring = true, -- Keep no_spring since we'll handle positioning manually
    }

    table.insert(self.set_bonus_elements, set_button)
    table.insert(self.set_defs, set_def)
    table.insert(self.set_keys, set_key)

    -- Terse summary ("+fire", "+damage"). Full per-tier breakdown still shows
    -- in the hover tooltip on the title. Same color for every item.
    local idx = #self.set_bonus_elements
    local summary = self:build_set_summary(set_def)
    local lines = {}
    for _, line in ipairs(self:wrap_text(summary, self.w - 8, pixul_font)) do
      table.insert(lines, {text = '[fg]' .. line, font = pixul_font, alignment = 'center'})
    end
    self.set_desc_texts[idx] = (#lines > 0) and Text(lines, global_text_tags) or nil
    ::continue::
  end
end

-- A very short blurb for the set: prefer a stat-based form built from the set's
-- bonus stats ("+fire", "+damage", "+crit"); fall back to the first clause of
-- the tier-1 description for proc-only sets that grant no flat stats.
function ItemCard:build_set_summary(set_def)
  -- An authored `summary` on the set wins (see ITEM_SETS).
  if set_def.summary then return set_def.summary end

  local names, seen = {}, {}
  for _, tier in pairs(set_def.bonuses or {}) do
    if tier.stats then
      for key, _ in pairs(tier.stats) do
        local dn = (item_stat_lookup and item_stat_lookup[key]) or key
        if not seen[dn] then seen[dn] = true; table.insert(names, dn) end
      end
    end
  end
  if #names > 0 then
    return '+' .. table.concat(names, ', ')
  end

  local d = (set_def.descriptions and set_def.descriptions[1]) or ''
  return (d:match('^[^;,(]+') or d):gsub('%s+$', '')
end

-- Vertical offsets (relative to card center) for each set's title button and
-- its summary text. Titles stack from just below the cost; the summary block is
-- centered in the room between the titles and the bottom x/x. Used by both
-- update() (button position) and draw() (summary position) so they stay aligned.
function ItemCard:layout_set_summaries()
  local n = #self.set_bonus_elements
  local title_h = 9

  -- Titles stacked from the top.
  local y = -self.h/2 + 14
  for i = 1, n do
    self.set_layout[i] = {title_dy = y + title_h/2}
    y = y + title_h + 1
  end
  local titles_bottom = y

  -- Center the summary text(s) in the gap between the titles and the x/x.
  local xx_top = self.h/2 - 12
  local total_desc_h = 0
  for i = 1, n do
    local desc = self.set_desc_texts[i]
    total_desc_h = total_desc_h + (desc and desc.h or 0)
  end
  local dy = (titles_bottom + xx_top) / 2 - total_desc_h/2
  for i = 1, n do
    local desc = self.set_desc_texts[i]
    local dh = desc and desc.h or 0
    self.set_layout[i].desc_dy = dy + dh/2
    dy = dy + dh
  end
end

-- x/x for a set: the tier this purchase would land on (max pieces any unit
-- already owns + 1) over the set's full size. 1/3 when nobody owns it, 2/3
-- when a unit already has one piece, etc.
function ItemCard:compute_set_progress(set_key, set_def)
  local denom = 0
  local tiers = set_def.descriptions or set_def.bonuses or {}
  for k, _ in pairs(tiers) do
    if type(k) == 'number' and k > denom then denom = k end
  end

  local max_existing = 0
  if self.parent and self.parent.units then
    for _, unit in ipairs(self.parent.units) do
      local c = Helper.Unit:count_unit_set_pieces(unit)[set_key] or 0
      if c > max_existing then max_existing = c end
    end
  end

  return math.min(max_existing + 1, denom), denom
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
    Create_Info_Text('no empty slots - drag to a unit title for xp', self, 'error')
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
      self:buy_item_to_slot(item_part, unit)
    else
      -- Dropped anywhere else on a unit card - buy into its first empty slot
      local card = Find_Character_Card_At(mouse_x, mouse_y)
      local target_part = card and card:first_empty_item_part()
      if target_part then
        self:buy_item_to_slot(target_part, card.unit)
      elseif card then
        Create_Info_Text('no empty slots - drop on the title for xp', self, 'error')
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

  -- Update set title button positions to move with the ItemCard (top of the
  -- card, below the cost), accounting for grab scaling.
  for i, set_button in ipairs(self.set_bonus_elements) do
    local layout = self.set_layout[i]
    local base_x = self.x
    local base_y = self.y + (layout and layout.title_dy or 0)

    -- If grabbed and scaling, apply the same scaling offset as in draw method
    if self.grabbed and self.current_scale < 1.0 then
      local mouse_x, mouse_y = camera:get_mouse_position()
      local scale_offset_x = (mouse_x - self.x) * (1 - self.current_scale)
      local scale_offset_y = (mouse_y - self.y) * (1 - self.current_scale)
      base_x = base_x + scale_offset_x
      base_y = base_y + scale_offset_y
    end

    set_button.x = base_x
    set_button.y = base_y
    if set_button.shape then
      set_button.shape:move_to(set_button.x, set_button.y)
    end
  end

  -- Recompute the x/x for the primary set each frame (buying onto a unit from a
  -- sibling card changes the count while this card is still on screen). The
  -- current count is yellow, the denominator neutral; only rebuilt on change.
  if self.set_keys[1] then
    self.progress_num, self.progress_denom = self:compute_set_progress(self.set_keys[1], self.set_defs[1])
    local str = self.progress_num .. '/' .. self.progress_denom
    if str ~= self.progress_str then
      self.progress_str = str
      if self.progress_text then self.progress_text.dead = true end
      self.progress_text = Text({{text = '[yellow]' .. self.progress_num .. '[fg]/' .. self.progress_denom, font = pixul_font, alignment = 'center'}}, global_text_tags)
    end
  end

  --check if the set buttons are hovered
  for _, set_button in ipairs(self.set_bonus_elements) do
    if set_button.shape:is_colliding_with_point(camera:get_mouse_position()) then
      set_button.selected = true
    else
      set_button.selected = false
    end
  end

  self.set_button_hovered = false

  if not self.grabbed then
    for _, set_button in ipairs(self.set_bonus_elements) do
      if set_button.selected then
        self:show_set_bonus_tooltip(set_button.set_info, set_button.set_key)
        self.set_button_hovered = true
      end
    end
  end

  if not self.set_button_hovered then
    self:remove_set_bonus_tooltip()
  end

end

function ItemCard:show_set_bonus_tooltip(set_info, set_key)
  if self.dead then return end

  -- Preview the tier this purchase would reach: the expected after-buy bonuses
  -- are colored the set color, the rest greyed (same as the card's x/x).
  local pieces = 0
  if set_key then
    pieces = (self:compute_set_progress(set_key, set_info))
  end
  local text_lines = DrawUtils.build_set_bonus_tooltip_text(set_info, pieces)

  self:remove_set_bonus_tooltip()

  self.set_bonus_tooltip = InfoText{group = self.parent.ui_top or self.group, force_update = false}
  self.set_bonus_tooltip:activate(text_lines, nil, nil, nil, nil, 16, 4, nil, 2)
  local pos = Get_UI_Popup_Position()
  self.set_bonus_tooltip.x = pos.x
  self.set_bonus_tooltip.y = pos.y
end

function ItemCard:draw()
  if not self.item then return end
  
  -- If grabbed and scaling, we need to handle the scaling towards mouse cursor
  if self.grabbed and self.current_scale < 1.0 then
    local mouse_x, mouse_y = camera:get_mouse_position()
    
    -- Calculate offset from card center to mouse for scaling origin
    local scale_offset_x = (mouse_x - self.x) * (1 - self.current_scale)
    local scale_offset_y = (mouse_y - self.y) * (1 - self.current_scale)
    
    -- Temporarily adjust position for scaling towards mouse
    local original_x, original_y = self.x, self.y
    self.x = self.x + scale_offset_x
    self.y = self.y + scale_offset_y
    
    -- Override the spring scaling with our custom scaling
    local original_sx, original_sy = self.sx, self.sy
    self.sx = self.current_scale * self.spring.x
    self.sy = self.current_scale * self.spring.x
    
    -- Draw base card
    self:draw_base_card()
    
    -- Restore original values
    self.x, self.y = original_x, original_y
    self.sx, self.sy = original_sx, original_sy
  else
    -- Normal drawing
    self:draw_base_card()
  end

  self:draw_set_summaries()
end

-- Per-set summary description under each title, plus the x/x set progress at the
-- bottom. Drawn in screen space (like the title buttons), so skipped while the
-- card is shrinking into a slot to avoid full-size text floating over it.
function ItemCard:draw_set_summaries()
  if #self.set_bonus_elements == 0 then return end
  if self.flying_to_slot then return end
  if self.current_scale and self.current_scale < 0.999 then return end

  -- Draw inside the card's spring transform so the text wiggles with the card
  -- on hover, just like the cost.
  graphics.push(self.x, self.y, 0, self.sx*self.spring.x, self.sy*self.spring.x)

  for i, layout in pairs(self.set_layout) do
    local desc = self.set_desc_texts[i]
    if desc and layout.desc_dy then
      desc:draw(self.x, self.y + layout.desc_dy)
    end
  end

  if self.progress_text then
    self.progress_text:draw(self.x, self.y + self.h/2 - 6)
  end

  graphics.pop()
end

function ItemCard:on_mouse_enter()
  ItemCard.super.on_mouse_enter(self)

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
  self.set_button_hovered = false

  if self.set_bonus_tooltip then
    self.set_bonus_tooltip:deactivate()
    self.set_bonus_tooltip:die()
    self.set_bonus_tooltip.dead = true
    self.set_bonus_tooltip = nil
  end
end
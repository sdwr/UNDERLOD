-- Between-substage upgrade picker for sequence stages (A_0/B_0/C_0).
-- Presents three choices: a random new perk, a sword level-up, and a random sword-friendly proc.

UpgradeOverlay = Object:extend()
UpgradeOverlay.__class_name = 'UpgradeOverlay'
UpgradeOverlay:implement(GameObject)

SWORD_FRIENDLY_PROCS = {
  {name = 'splash',       label = 'Splash',       desc = 'AOE damage on swing hit'},
  {name = 'bloodlust',    label = 'Bloodlust',    desc = 'Attack speed stacks on kill'},
  {name = 'overkill',     label = 'Overkill',     desc = 'Extra damage on overkill'},
  {name = 'shock',        label = 'Shock',        desc = 'Shock on hit'},
  {name = 'blazin',       label = 'Blazin',       desc = 'Burn on hit'},
  {name = 'craggy',       label = 'Craggy',       desc = 'Damage attackers'},
  {name = 'spikedcollar', label = 'Spiked Collar',desc = 'Reflect contact damage'},
  {name = 'shieldslam',   label = 'Shield Slam',  desc = 'Knockback on hit'},
}

local function pick_random_proc(used)
  used = used or {}
  local pool = {}
  for _, p in ipairs(SWORD_FRIENDLY_PROCS) do
    if not used[p.name] then table.insert(pool, p) end
  end
  if #pool == 0 then return SWORD_FRIENDLY_PROCS[random:int(1, #SWORD_FRIENDLY_PROCS)] end
  return pool[random:int(1, #pool)]
end

local function pick_random_perk_key(existing_names)
  local available = {}
  for key, def in pairs(PERK_DEFINITIONS) do
    if not (existing_names and existing_names[def.name]) then
      table.insert(available, key)
    end
  end
  if #available == 0 then return nil end
  return available[random:int(1, #available)]
end

function UpgradeOverlay:init(args)
  self:init_game_object(args)
  self.world_manager = args.world_manager
  self.cards = {}
  self.selected_index = nil

  main.current.choosing_perks = true
  Helper.Unit:disable_unit_controls()

  -- Build three choices
  self.choices = {}

  local perk_key = pick_random_perk_key(args.existing_perk_names)
  if perk_key then
    local def = PERK_DEFINITIONS[perk_key]
    table.insert(self.choices, {
      kind = 'perk',
      perk_key = perk_key,
      label = def.name,
      desc = def.description,
    })
  end

  local at_max = (args.weapon_level_bonus or 0) >= (WEAPON_MAX_LEVEL - 1)
  if not at_max then
    table.insert(self.choices, {
      kind = 'weapon_level',
      label = 'Sword Level +1',
      desc = '+25% damage, -10% cooldown',
    })
  end

  local proc_pick = pick_random_proc(args.used_procs)
  table.insert(self.choices, {
    kind = 'proc',
    proc_name = proc_pick.name,
    label = proc_pick.label,
    desc = proc_pick.desc,
  })

  -- If perk pool was empty AND weapon at max, pad with a second proc so the player always has 3
  while #self.choices < 3 do
    local extra = pick_random_proc({[proc_pick.name] = true})
    table.insert(self.choices, {
      kind = 'proc',
      proc_name = extra.name,
      label = extra.label,
      desc = extra.desc,
    })
  end

  self:create_cards()

  -- Title
  self.title_text = Text2{
    group = self.group, x = gw/2, y = gh/2 - 80,
    lines = {{text = '[wavy_mid, fg]Choose an Upgrade', font = fat_font, alignment = 'center'}}
  }
end

function UpgradeOverlay:create_cards()
  local card_w, card_h, gap = 110, 70, 24
  local total_w = #self.choices * card_w + (#self.choices - 1) * gap
  local start_x = gw/2 - total_w/2 + card_w/2
  local card_y = gh/2

  for i, choice in ipairs(self.choices) do
    local cx = start_x + (i - 1) * (card_w + gap)
    self.t:after(0.15 * (i - 1), function()
      local card = UpgradeCard{
        group = self.group,
        x = cx, y = card_y, w = card_w, h = card_h,
        choice = choice,
        parent = self,
        index = i,
      }
      self.cards[i] = card
    end)
  end
end

function UpgradeOverlay:on_choice_selected(index)
  if self.selected_index then return end
  self.selected_index = index
  local choice = self.choices[index]
  ui_switch1:play{pitch = random:float(0.95, 1.05), volume = 0.5}

  if self.world_manager then
    self.world_manager:apply_upgrade_choice(choice)
  end

  for i, card in ipairs(self.cards) do
    if card and not card.dead and i ~= index then card:die() end
  end

  Helper.Unit:enable_unit_controls()
  main.current.choosing_perks = false

  self.t:after(0.6, function()
    self:die()
    if self.world_manager then
      self.world_manager:proceed_to_next_substage()
    end
  end)
end

function UpgradeOverlay:update(dt)
  self:update_game_object(dt)
end

function UpgradeOverlay:draw()
end

function UpgradeOverlay:die()
  self.dead = true
  if self.title_text then self.title_text.dead = true; self.title_text = nil end
  for _, card in ipairs(self.cards) do
    if card and not card.dead then card.dead = true end
  end
  Helper.Unit:enable_unit_controls()
  main.current.choosing_perks = false
end


-- Simple card widget for the upgrade overlay.
UpgradeCard = Object:extend()
UpgradeCard.__class_name = 'UpgradeCard'
UpgradeCard:implement(GameObject)

function UpgradeCard:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, args.w, args.h)
  self.w = args.w
  self.h = args.h
  self.choice = args.choice
  self.parent = args.parent
  self.index = args.index
  self.interact_with_mouse = true
  self.selected = false

  local kind = self.choice.kind
  local kind_color = (kind == 'perk') and 'yellow' or (kind == 'weapon_level') and 'orange' or 'blue'
  self.kind_color_name = kind_color

  self.label_text = Text({{text = '[fg]' .. self.choice.label, font = pixul_font, alignment = 'center'}}, global_text_tags)
  self.desc_text = Text({{text = '[fgm5]' .. self.choice.desc, font = pixul_font, alignment = 'center'}}, global_text_tags)
end

function UpgradeCard:update(dt)
  self:update_game_object(dt)
  if self.dead then return end
  if self.selected and input.m1.pressed and self.parent and not self.parent.selected_index then
    self.parent:on_choice_selected(self.index)
  end
end

function UpgradeCard:draw()
  local bg_color = self.selected and fg[-3] or bg[-2]
  local accent = _G[self.kind_color_name] and _G[self.kind_color_name][0] or fg[0]
  graphics.rectangle(self.x, self.y, self.w, self.h, 4, 4, bg_color)
  graphics.rectangle(self.x, self.y - self.h/2 + 4, self.w, 4, 0, 0, accent)
  self.label_text:draw(self.x, self.y - 10, 0, 1, 1)
  self.desc_text:draw(self.x, self.y + 14, 0, 1, 1)
end

function UpgradeCard:on_mouse_enter()
  self.selected = true
  ui_hover1:play{pitch = random:float(1.3, 1.5), volume = 0.4}
end

function UpgradeCard:on_mouse_exit()
  self.selected = false
end

function UpgradeCard:die()
  self.dead = true
end

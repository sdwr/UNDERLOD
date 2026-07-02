-- Announcement shown when a boss spawns: a dark letterbox band expands from a
-- horizontal line, the boss name and subtitle fade in, hold, then the whole
-- card fades out and destroys itself. Purely visual.

BOSS_TITLES = {
  ['stompy'] = {name = 'STOMPY', subtitle = 'the ancient golem'},
  ['dragon'] = {name = 'DRAGON', subtitle = 'mother of the brood'},
  ['heigan'] = {name = 'HEIGAN', subtitle = 'the unclean'},
}

BOSS_TITLE_CARD_DURATION = 3.0
BOSS_TITLE_CARD_FADE_OUT = 0.6
-- When the boss becomes visible during the card (see spawn_boss_immediately).
BOSS_POP_IN_DELAY = 1.0

BossTitleCard = Object:extend()
BossTitleCard.__class_name = 'BossTitleCard'
BossTitleCard:implement(GameObject)
function BossTitleCard:init(args)
  self:init_game_object(args)
  self.interact_with_mouse = false

  local title = BOSS_TITLES[self.boss_name] or {name = string.upper(self.boss_name or 'BOSS'), subtitle = ''}
  self.name_text = title.name
  self.subtitle_text = title.subtitle

  self.x = gw/2
  self.y = gh/2 - 30

  self.band_h = 0
  self.band_target_h = 44
  self.band_alpha = 0.55
  self.name_alpha = 0
  self.subtitle_alpha = 0
  self.fade = 1

  spawn_mark2:play{pitch = 0.6, volume = 0.8}
  camera:shake(5, 0.4)

  self.t:tween(0.35, self, {band_h = self.band_target_h}, math.expo_out)
  self.t:after(0.2, function() self.t:tween(0.35, self, {name_alpha = 1}, math.linear) end)
  self.t:after(0.45, function() self.t:tween(0.3, self, {subtitle_alpha = 1}, math.linear) end)

  self.t:after(BOSS_TITLE_CARD_DURATION, function()
    self.t:tween(BOSS_TITLE_CARD_FADE_OUT, self, {fade = 0}, math.linear)
  end)
  self.t:after(BOSS_TITLE_CARD_DURATION + BOSS_TITLE_CARD_FADE_OUT + 0.1, function() self.dead = true end)
end

function BossTitleCard:update(dt)
  self:update_game_object(dt)
end

function BossTitleCard:draw()
  if self.band_h > 0.5 then
    local band_color = black[0]:clone()
    band_color.a = self.band_alpha*self.fade
    graphics.rectangle(self.x, self.y, gw + 10, self.band_h, nil, nil, band_color)
  end

  if self.name_alpha > 0 then
    local name_color = fg[0]:clone()
    name_color.a = self.name_alpha*self.fade
    graphics.print_centered(self.name_text, pixul_font_huge, self.x, self.y - 6, 0, 1, 1, nil, nil, name_color)
  end

  if self.subtitle_alpha > 0 and self.subtitle_text ~= '' then
    local subtitle_color = fg[0]:clone()
    subtitle_color.a = 0.7*self.subtitle_alpha*self.fade
    graphics.print_centered(self.subtitle_text, pixul_font, self.x, self.y + 14, 0, 1, 1, nil, nil, subtitle_color)
  end
end

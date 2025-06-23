
local fns = {}
fns['attack'] = function(self, mods, color)
  mods = mods or {}
  local t = {team = "enemy", group = main.current.effects, x = mods.x or self.x, y = mods.y or self.y, r = self.r, w = self.area_size_m*(20), color = color or self.color, dmg = self.dmg,
    character = self.character, level = self.level, parent = self}

  Helper.Unit:set_state(self, unit_states['frozen'])

  self.t:after(0.3, function() 
    Helper.Unit:set_state(self, unit_states['stopped'])
    Area(table.merge(t, mods))
    _G[random:table{'swordsman1', 'swordsman2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.75}
  end, 'stopped')
  self.t:after(0.4 + .4, function() Helper.Unit:set_state(self, unit_states['normal']) end, 'normal')
end

fns['init_enemy'] = function(self)
  
  --set extra data from variables
  self.data = self.data or {}
  self.size = self.data.size or 'regular'
  self.icon = 'skeleton'

  --create shape
  self.color = grey[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'regular_enemy'

  self.base_mvspd = 40

end

fns['draw_enemy'] = function(self)

  graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

  local sx = (self.shape.w / SKELETON_SPRITE_W) * SKELETON_SPRITE_SCALE
  local sy = (self.shape.h / SKELETON_SPRITE_H) * SKELETON_SPRITE_SCALE
  
  if self:is_facing_left() then
    sx = -sx
  end
  
  local animation_success = self:draw_animation(self.state, self.x, self.y, 0, sx, sy)

  if not animation_success then
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
  end

  graphics.pop()

end

enemy_to_class['seeker'] = fns
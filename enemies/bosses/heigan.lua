

local fns = {}

fns['init_enemy'] = function(self)

  --set extra variables from data
  self.data = self.data or {}
  self.size = self.data.size or 'heigan'

  --create shape
  self.color = orange[-2]:clone()
  Set_Enemy_Shape(self, self.size)
  
  self.class = 'boss'
  self.icon = 'beholder'

  --set sensors
  self.attack_sensor = Circle(self.x, self.y, 80)

  --set attacks
  self.attack_options = {}
  

  local safety_dance = {
    name = 'safety_dance',
    viable = function () return true end,
    castcooldown = 1,
    cast = function()
      Helper.Spell.SafetyDance:create_all(self, orange[-5], true, 'one_safe', 4, 25)
    end
  }

  local laser_ball = {
    name = 'laser_ball',
    viable = function () return true end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    spellclass = LaserBall,
    instantspell = true,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      color = purple[-5],
      damage = 20,
      parent = self
    },
  }

  --spell ends after # of balls, not duration
  local plasma_barrage_spiral = {
    name = 'plasma_barrage',
    viable = function () return true end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    spellclass = Plasma_Barrage,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = 100,
      x = self.x,
      y = self.y,
      movement_type = 'spiral',
      rotation_speed = 1,
      color = purple[-5],
      damage = 20,
      parent = self
    },
  }

  --spell ends after # of balls, not duration
  local plasma_barrage_straight = {
    name = 'plasma_barrage_straight',
    viable = function () return true end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    spellclass = Plasma_Barrage,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      spell_duration = 100,
      x = self.x,
      y = self.y,
      movement_type = 'straight',
      color = purple[-5],
      damage = 20,
      parent = self
    },
  }

  local plasma_ball = {
    name = 'plasma_ball',
    viable = function () return true end,
    castcooldown = 1,
    instantspell = true,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    spellclass = PlasmaBall,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      r = self.r,
      color = purple[-5],
      damage = 20,
      parent = self
    },
  }

  local quick_stomp = {
    name = 'quick_stomp',
    viable = function() return self:get_random_object_in_shape(self.attack_sensor, main.current.friendlies) end,
    castcooldown = 1,
    oncast = function() end,
    cast_length = BEHOLDER_CAST_TIME,
    spellclass = Stomp_Spell,
    spelldata = {
      group = main.current.main,
      team = "enemy",
      x = self.x,
      y = self.y,
      color = orange[-5],
      rs = 50,
      dmg = 50,
      parent = self,
    }
  }

  -- table.insert(self.attack_options, plasma_barrage_spiral)
  -- table.insert(self.attack_options, plasma_barrage_straight)
  table.insert(self.attack_options, safety_dance)
  -- table.insert(self.attack_options, laser_ball)
  -- table.insert(self.attack_options, plasma_ball)
  -- table.insert(self.attack_options, quick_stomp)
end

fns['draw_enemy'] = function(self)
    graphics.push(self.x, self.y, 0, self.hfx.hit.x, self.hfx.hit.x)

    local sx = (self.shape.w / BEHOLDER_SPRITE_W) * BEHOLDER_SPRITE_SCALE
    local sy = (self.shape.h / BEHOLDER_SPRITE_H) * BEHOLDER_SPRITE_SCALE
    local animation_success = self:draw_animation(self.state, self.x, self.y, 0, sx, sy)

    if not animation_success then
      graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 10, 10, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
    end

    graphics.pop()
end

enemy_to_class['heigan'] = fns
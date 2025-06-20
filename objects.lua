SpawnMarker = Object:extend()
SpawnMarker:implement(GameObject)
function SpawnMarker:init(args)
  self:init_game_object(args)
  self.color = red[0]
  self.r = random:float(0, 2*math.pi)
  self.spring:pull(random:float(0.4, 0.6), 200, 10)
  self.t:after(1.125, function() self.dead = true end)
  self.m = 1
  self.n = 0
  pop3:play{pitch = 1, volume = 0.15}
  self.t:every({0.195, 0.24}, function()
    self.hidden = not self.hidden
    self.m = self.m*random:float(0.84, 0.87)
  end, nil, nil, 'blink')
end


function SpawnMarker:update(dt)
  self:update_game_object(dt)
  self.t:set_every_multiplier('blink', self.m)
end


function SpawnMarker:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.spring.x, self.spring.x)
    graphics.push(self.x, self.y, self.r + math.pi/4)
      graphics.rectangle(self.x, self.y, 24, 6, 4, 4, self.color)
    graphics.pop()
    graphics.push(self.x, self.y, self.r + 3*math.pi/4)
      graphics.rectangle(self.x, self.y, 24, 6, 4, 4, self.color)
    graphics.pop()
  graphics.pop()
end




LightningLine = Object:extend()
LightningLine:implement(GameObject)
function LightningLine:init(args)
  self:init_game_object(args)
  self.lines = {}
  table.insert(self.lines, {x1 = self.src.x, y1 = self.src.y, x2 = self.dst.x, y2 = self.dst.y})
  self.w = 3
  self.generations = args.generations or 3
  self.max_offset = args.max_offset or 8
  self:generate()
  self.t:tween(self.duration or 0.1, self, {w = 1}, math.linear, function() self.dead = true end)
  self.color = args.color or blue[0]
  HitCircle{group = main.current.effects, x = self.src.x, y = self.src.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
  for i = 1, 2 do HitParticle{group = main.current.effects, x = self.src.x, y = self.src.y, color = self.color} end
  HitCircle{group = main.current.effects, x = self.dst.x, y = self.dst.y, rs = 6, color = fg[0], duration = self.duration or 0.1}
  HitParticle{group = main.current.effects, x = self.dst.x, y = self.dst.y, color = self.color}
end


function LightningLine:update(dt)
  self:update_game_object(dt)
end


function LightningLine:draw()
  graphics.polyline(self.color, self.w, unpack(self.points))
end


function LightningLine:generate()
  local offset_amount = self.max_offset
  local lines = self.lines

  for j = 1, self.generations do
    for i = #self.lines, 1, -1 do
      local x1, y1 = self.lines[i].x1, self.lines[i].y1
      local x2, y2 = self.lines[i].x2, self.lines[i].y2
      table.remove(self.lines, i)

      local x, y = (x1+x2)/2, (y1+y2)/2
      local p = Vector(x2-x1, y2-y1):normalize():perpendicular()
      x = x + p.x*random:float(-offset_amount, offset_amount)
      y = y + p.y*random:float(-offset_amount, offset_amount)
      table.insert(self.lines, {x1 = x1, y1 = y1, x2 = x, y2 = y})
      table.insert(self.lines, {x1 = x, y1 = y, x2 = x2, y2 = y2})
    end
    offset_amount = offset_amount/2
  end

  self.points = {}
  while #self.lines > 0 do
    local min_d, min_i = 1000000, 0
    for i, line in ipairs(self.lines) do
      local d = math.distance(self.src.x, self.src.y, line.x1, line.y1)
      if d < min_d then
        min_d = d
        min_i = i
      end
    end
    local line = table.remove(self.lines, min_i)
    if line then
      table.insert(self.points, line.x1)
      table.insert(self.points, line.y1)
    end
  end
end




WallKnife = Object:extend()
WallKnife:implement(GameObject)
WallKnife:implement(Physics)
function WallKnife:init(args)
  self:init_game_object(args)
  self:set_as_rectangle(10, 4, 'dynamic', 'projectile')
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:tween({0.8, 1.6}, self, {v = 0}, math.linear, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)

  self.vr = self.r
  self.dvr = random:table{random:float(-8*math.pi, -4*math.pi), random:float(4*math.pi, 8*math.pi)}
end


function WallKnife:update(dt)
  self:update_game_object(dt)

  self:set_angle(self.r)
  self:move_along_angle(self.v, self.r)
  self.vr = self.vr + self.dvr*dt
end


function WallKnife:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.vr, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end




WallArrow = Object:extend()
WallArrow:implement(GameObject)
function WallArrow:init(args)
  self:init_game_object(args)
  self.shape = Rectangle(self.x, self.y, 10, 4)
  self.hfx:add('hit', 1)
  self.hfx:use('hit', 0.25)
  self.t:after({0.8, 2}, function()
    self.t:every_immediate(0.05, function() self.hidden = not self.hidden end, 7, function() self.dead = true end)
  end)
end


function WallArrow:update(dt)
  self:update_game_object(dt)
end


function WallArrow:draw()
  if self.hidden then return end
  graphics.push(self.x, self.y, self.r, self.hfx.hit.x, self.hfx.hit.x)
  graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 2, 2, self.hfx.hit.f and fg[0] or self.color)
  graphics.pop()
end





Unit = Object:extend()
function Unit:init_unit()
  self.level = self.level or 1

  self:config_physics_object()

  --also set in child classes
  self.castcooldown = 0
  self.total_castcooldown = 0

  self.target = nil
  self.assigned_target = nil
  self.buffs = {}
  self.toggles = {}
  self.hfx:add('hit', 1)
  self.hfx:add('shoot', 1)
  self.hp_bar = HPBar{group = main.current.effects, parent = self, isBoss = self.isBoss}
  self.effect_bar = EffectBar{group = main.current.effects, parent = self}
  
  self.state = unit_states['normal']
end

function Unit:config_physics_object()
  

  if self.class == 'boss' then

    self:set_damping(BOSS_DAMPING)
    self:set_restitution(BOSS_RESTITUTION)

    self:set_mass(BOSS_MASS)

    --heigan had 1000, stompy had 10000, dragon had default
    self:set_as_steerable(self.v, 1000, 2*math.pi, 2)

  elseif self.class == 'miniboss' then
    --ignore for now
  elseif self.class == 'special_enemy' then

    self:set_damping(SPECIAL_ENEMY_DAMPING)
    self:set_restitution(SPECIAL_ENEMY_RESTITUTION)

    self:set_mass(SPECIAL_ENEMY_MASS)

    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  elseif self.class == 'regular_enemy' then
    
    self:set_damping(REGULAR_ENEMY_DAMPING)
    self:set_restitution(REGULAR_ENEMY_RESTITUTION)

    self:set_mass(REGULAR_ENEMY_MASS)

    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  
  elseif self.class == 'enemy_critter' then
    self:set_damping(CRITTER_DAMPING)
    self:set_restitution(CRITTER_RESTITUTION)

    self:set_mass(CRITTER_MASS)
    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
  elseif self.class =='critter' then
    self:set_damping(CRITTER_DAMPING)
    self:set_restitution(CRITTER_RESTITUTION)

    self:set_mass(CRITTER_MASS)
    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  elseif self.class == 'troop' then
    if self.ghost == true then
      self:set_as_rectangle(self.size, self.size,'dynamic', 'ghost')
    else
      self:set_as_rectangle(self.size, self.size,'dynamic', 'troop')
    end

    self:set_damping(TROOP_DAMPING)
    self:set_restitution(TROOP_RESITUTION)

    self:set_mass(TROOP_MASS)

    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)

  end
  
end

function Unit:init_hitbox_points()
  
  if self.boss_name == 'stompy' then
    local step = (self.shape.w - 4) / 5
    for x = -self.shape.w/2 + 2, self.shape.w/2 - 2, step do
      for y = -self.shape.h/2 + 2, self.shape.h/2 - 2, step do
        if x == -self.shape.w/2 + 2 and y == -self.shape.h/2 + 2 then
          Helper.Unit:add_point(self, x + 2, y + 2)
        elseif x == -self.shape.w/2 + 2 and near(y, self.shape.h/2 - 2, 0.01) then
          Helper.Unit:add_point(self, x + 2, y - 2)
        elseif near(x, self.shape.w/2 - 2, 0.01) and y == -self.shape.h/2 + 2 then
          Helper.Unit:add_point(self, x - 2, y + 2)
        elseif near(x, self.shape.w/2 - 2, 0.01) and near(y, self.shape.h/2 - 2, 0.01) then
          Helper.Unit:add_point(self, x - 2, y - 2)
        else
          Helper.Unit:add_point(self, x, y)
        end
      end
    end
  end

  --if enemy is dragon
  if self.boss_name == 'dragon' then
    self.hitbox_points_can_rotate = true
    Helper.Unit:add_point(self, 32, 0)
    Helper.Unit:add_point(self, -15, 27)
    Helper.Unit:add_point(self, -15, -27)
    Helper.Unit:add_point(self, 23, 5)
    Helper.Unit:add_point(self, 23, -5)
    Helper.Unit:add_point(self, 16, 9)
    Helper.Unit:add_point(self, 16, -9)
    Helper.Unit:add_point(self, 10, 12)
    Helper.Unit:add_point(self, 10, -12)
    Helper.Unit:add_point(self, -9, 23)
    Helper.Unit:add_point(self, -9, -23)
    Helper.Unit:add_point(self, -3, 19)
    Helper.Unit:add_point(self, -3, -19)
    Helper.Unit:add_point(self, 3, 16)
    Helper.Unit:add_point(self, 3, -16)
    Helper.Unit:add_point(self, -16, 21)
    Helper.Unit:add_point(self, -16, -21)
    Helper.Unit:add_point(self, -16, 14)
    Helper.Unit:add_point(self, -16, -14)
    Helper.Unit:add_point(self, -16, 6)
    Helper.Unit:add_point(self, -16, -6)
    Helper.Unit:add_point(self, -16, 0)
    Helper.Unit:add_point(self, -9, 16)
    Helper.Unit:add_point(self, -9, -16)
    Helper.Unit:add_point(self, -9, 7)
    Helper.Unit:add_point(self, -9, -7)
    Helper.Unit:add_point(self, -9, 0)
    Helper.Unit:add_point(self, -2, 11)
    Helper.Unit:add_point(self, -2, -11)
    Helper.Unit:add_point(self, -2, 3)
    Helper.Unit:add_point(self, -2, -3)
    Helper.Unit:add_point(self, 5, 8)
    Helper.Unit:add_point(self, 5, -8)
    Helper.Unit:add_point(self, 5, -0)
    Helper.Unit:add_point(self, 10, 4)
    Helper.Unit:add_point(self, 10, -4)
    Helper.Unit:add_point(self, 18, -3)
    Helper.Unit:add_point(self, 18, 3)
    Helper.Unit:add_point(self, 25, 0)
  end
end




function Unit:bounce(nx, ny)
  local vx, vy = self:get_velocity()
  if nx == 0 then
    self:set_velocity(vx, -vy)
    self.r = 2*math.pi - self.r
  end
  if ny == 0 then
    self:set_velocity(-vx, vy)
    self.r = math.pi - self.r
  end
  return self.r
end

--self is enemy, other is player
function Unit:on_trigger_enter(other)
end

function Unit:on_trigger_exit(other)

end


function Unit:show_hp(n)
  self.hp_bar.hidden = false
  self.hp_bar.color = red[0]
  --self.t:after(n or 2, function() self.hp_bar.hidden = true end, 'hp_bar')
end

function Unit:hide_hp()
  self.hp_bar.hidden = true
end

--have full data passed in instead of just type?
function Unit:show_damage_number(dmg, damagetype)
  if not state.show_damage_numbers then return end
  
  local color = damage_type_to_color[damagetype] or white[0]
  local roundedDmg = math.floor(dmg)

  local data = {
    group = main.current.effects,
    color = color,
    x = self.x + random_offset(4),
    y = self.y + random_offset(4),
    rs = 6,
    lines = {{text =  '' .. roundedDmg, font = pixul_mini}},
  }
  FloatingText(data)
end

function Unit:heal(amount)
  self.hp = math.min(self.hp + amount, self.max_hp)
  self.hfx:use('hit', 0.25, 200, 10)
  --missing effect here
end


function Unit:show_heal(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = green[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end


function Unit:show_infused(n)
  self.effect_bar.hidden = false
  self.effect_bar.color = blue[0]
  self.t:after(n or 4, function() self.effect_bar.hidden = true end, 'effect_bar')
end

function Unit:calculate_damage(dmg)
  if self.def >= 0 then dmg = dmg*(100/(100+self.def))
  else dmg = dmg*(2 - 100/(100+self.def)) end
  return dmg
end

--can only have 1 buff with the each name
--if a buff with the same name is added, the duration is updated
--but stats are not added together yet (will need for slow stacking etc.)

--add toggles for buffs that have a binary effect
--increment when a new buff is added, decrement when it is removed
--don't increment if the buff is already present and we are just updating the duration

--don't need to deep copy the buff, since a new proc is created each time
--will need to when the proc starts reapplying the buff?
function Unit:get_buff_names()
  local buff_names = {}
  for k, v in pairs(self.buffs) do
    table.insert(buff_names, k)
  end
  return buff_names
end

function Unit:has_buff(buffName)
  return self.buffs[buffName] ~= nil
end

function Unit:get_buff(buffName)
  return self.buffs[buffName]
end

function Unit:add_buff(buff)
  --copy the buff so we don't modify the original (procs are reusing the same buff data object)
  local buffCopy = {}
  for k, v in pairs(buff) do
    buffCopy[k] = v
  end

  local existing_buff = self.buffs[buffCopy.name]

  --overwrite duration and nextTick if the buff is already present
  if existing_buff then
    self.buffs[buffCopy.name].duration = math.max(existing_buff.duration, buffCopy.duration)
    if buffCopy.nextTick then
      self.buffs[buffCopy.name].nextTick = buffCopy.nextTick
    end
  else
    if buffCopy.color then
      local color = buffCopy.color:clone()
      color.a = 0.6
      buffCopy.color = color
    end
    self.buffs[buffCopy.name] = buffCopy
    self:increment_buff_toggles(buffCopy)
  end
end

function Unit:remove_buff(buffName)
  local existing_buff = self.buffs[buffName]
  if existing_buff then
    self.buffs[buffName] = nil
  end
  if buffName == 'shield' then
    self:remove_shield()
  end
  if existing_buff then
    self:decrement_buff_toggles(existing_buff)
  end
end

function Unit:draw_buffs()
  local i = 0.5
  for _ , buff in pairs(self.buffs) do
    if buff.color then
      graphics.circle(self.x, self.y, ((self.shape.w) / 2) + (i), buff.color, 1)
      i = i + 1
    end
  end
end

function Unit:draw_launching()
  if self.is_launching then
    graphics.circle(self.x, self.y, self.shape.w/2 + 2, orange_transparent)
  end
end

function Unit:draw_targeted()
  if self:has_buff('targeted') then
    graphics.circle(self.x, self.y, ((self.shape.w) / 2) + 3, yellow[0], 1)
  end
end

function Unit:draw_channeling()
  -- if self.state == unit_states['channeling'] then
  --   local bodySize = self.shape.rs or self.shape.w/2 or 5
  --   graphics.circle(self.x, self.y, bodySize, blue_transparent)
  -- end
end

function Unit:draw_cast_timer()
  if self.state == unit_states['casting'] then
    if self.castObject and self.castObject.hide_cast_timer then return end

    local currentTime = love.timer.getTime()
    local time = currentTime - self.last_attack_started
    local pct = 0
    if self.castObject then
      pct = self.castObject:get_cast_percentage()
    else
      local pct = time / self.castTime
    end
    local bodySize = self.shape.rs or self.shape.w/2 or 5
    local rs = pct * bodySize
    if pct < 1 then
      graphics.circle(self.x, self.y, rs, white_transparent)
    end
  end
end

--should move this somewhere, maybe to the proc class
-- dont want to have a bunch of if statements in here
-- with special logic for each buff
function Unit:update_buffs(dt)
  for k, v in pairs(self.buffs) do
    --on buff start
    if k == 'stunned' then
      self.state = unit_states['frozen']
    end
    if k == 'rooted' then
      self.state = unit_states['stopped']
    end
    if k == 'frozen' then
      self.state = unit_states['frozen']
    end
    if k == 'invulnerable' then
      self.invulnerable = true
    end

    --dec duration
    v.duration = v.duration - dt

    --on buff tick
    if k == 'burn' then
      if v.duration <= v.nextTick then
        --add a really quiet short sound here, becauseit'll be playing all the time
        fire3:play{pitch = random:float(0.8, 1.2), volume = 0.25}
        self:hit((v.dps/2), nil, DAMAGE_TYPE_PHYSICAL, false)
        --1 second tick, could be changed
        v.nextTick = v.nextTick - 0.5
      end
    end

    --on buff end
    if v.duration < 0 then
      if k == 'bash_cd' then
        self.canBash = true
      elseif k == 'stunned' then
        if self.state == unit_states['frozen'] then
          self.state = unit_states['normal']
        end
      elseif k == 'rooted' then
        if self.state == unit_states['stopped'] then
          self.state = unit_states['normal']
        end
      elseif k == 'frozen' then
        if self.state == unit_states['frozen'] then
          self.state = unit_states['normal']
        end
      elseif k == 'invulnerable' then
        self.invulnerable = false
      elseif k == 'shield' then
        self:remove_shield()
      end
      --this is where buff stacks tick down
      if v.stacks and v.stacks > 1 and not v.stacks_expire_together then
        v.stacks = v.stacks - 1
        v.duration = v.maxDuration
      else
        self.buffs[k] = nil
      end
    end
  end
end

function Unit:has_toggle(name)
  return self.toggles[name] and self.toggles[name] > 0
end

function Unit:increment_buff_toggles(buff)
  if buff.toggles then
    for k, v in pairs(buff.toggles) do
      self.toggles[k] = (self.toggles[k] or 0) + v
    end
  end
end

function Unit:decrement_buff_toggles(buff)
  if buff.toggles then
    for k, v in pairs(buff.toggles) do
      self.toggles[k] = self.toggles[k] - v
    end
  end
end


function Unit:init_stats()

  _set_unit_base_stats(self)

  _set_unit_item_config(self)
end

--different from calculate_stats :( 
--used for the character tooltip in buy screen
function Unit:get_item_stats()
  local stats = {}

  for i = 1, 6 do
    local item = self.items[i]
    if item and item.stats then
      for stat, amt in pairs(item.stats) do
        if stat == buff_types['dmg'] then
          stats.dmg = (stats.dmg or 0) + amt
        elseif stat == buff_types['flat_def'] then
          stats.flat_def = (stats.flat_def or 0) + amt
        elseif stat == buff_types['percent_def'] then
          stats.percent_def = (stats.percent_def or 0) + amt
        elseif stat == buff_types['mvspd'] then
          stats.mvspd = (stats.mvspd or 0) + amt
        elseif stat == buff_types['aspd'] then
          stats.aspd = (stats.aspd or 0) + amt
        elseif stat == buff_types['range'] then
          stats.range = (stats.range or 0) + amt
        elseif stat == buff_types['area_dmg'] then
          stats.area_dmg = (stats.area_dmg or 0) + amt
        elseif stat == buff_types['area_size'] then
          stats.area_size = (stats.area_size or 0) + amt
        elseif stat == buff_types['hp'] then
          stats.hp = (stats.hp or 0) + amt
        end
      end
    end
  end

  -- if stats.hp and stats.hp == 0 then
  --   Stats_Max_Dmg_Without_Hp(stats.dmg or 0)
  -- end

  -- Stats_Max_Aspd(stats.aspd or 0)
  return stats

end

function Unit:calculate_stats(first_run)
  local level = self.level or 1
  local hpMod = 1 + ((level - 1) / 2)
  local dmgMod = 1 + ((level - 1) / 2)
  local spdMod = 1

  --set base stats to default values
  --and add procs (+buffs) from items
  if(first_run) then
    self:init_stats()
  end

  self.base_aspd_m = 1
  self.base_area_dmg_m = 1
  self.base_area_size_m = 1
  self.base_def = 25
  self.class_hp_a = 0
  self.class_dmg_a = 0
  self.class_def_a = 0
  self.class_mvspd_a = 0
  self.class_hp_m = 1
  self.class_dmg_m = 1
  if self.type == 'laser' then
    self.class_dmg_m = 2
  end
  self.class_aspd_m = 1
  self.class_area_dmg_m = 1
  self.class_area_size_m = 1
  self.class_def_m = 1
  self.class_mvspd_m = 1
  self.buff_hp_a = 0
  self.buff_dmg_a = 0
  self.buff_def_a = 0
  self.buff_mvspd_a = 0
  self.buff_hp_m = 1
  self.buff_dmg_m = 1
  self.buff_aspd_m = 1
  self.buff_area_dmg_m = 1
  self.buff_area_size_m = 1
  self.buff_def_m = 1
  self.buff_mvspd_m = 1
  self.slow_mvspd_m = 1
  self.buff_range_a = 0
  self.buff_range_m = 1
  self.buff_cdr_m = 1

  self.eledmg_m = 1

  self.vamp = 0
  self.elevamp = 0

  self.status_resist = 0
  if self.class == 'miniboss' then
    self.status_resist = 0.5
  elseif self.class == 'boss' then
    self.status_resist = 0.8
  end

  if self.class == 'regular_enemy' then
    local enemy_stats = enemy_type_to_stats[self.type]
    if enemy_stats then
      for stat, amt in pairs(enemy_stats) do
        if stat == buff_types['dmg'] then
          self.class_dmg_m = amt
        elseif stat == buff_types['flat_def'] then
          self.class_def_a = amt
        elseif stat == buff_types['percent_def'] then
          self.class_def_m = amt
        elseif stat == buff_types['mvspd'] then
          self.class_mvspd_m = amt
        elseif stat == buff_types['aspd'] then
          self.class_aspd_m = amt
        elseif stat == buff_types['area_dmg'] then
          self.class_area_dmg_m = amt
        elseif stat == buff_types['area_size'] then
          self.class_area_size_m = amt
        elseif stat == buff_types['hp'] then
          self.class_hp_m = amt
        elseif stat == buff_types['status_resist'] then
          self.status_resist = self.status_resist + stat
        end
        
      end
    end
  end

  if self.buffs then
    for k, buff in pairs(self.buffs) do
      if buff.stats then
        for stat, amt in pairs(buff.stats) do
          local amtWithStacks = amt * (buff.stacks or 1)

          if stat == buff_types['dmg'] then
            self.buff_dmg_m = self.buff_dmg_m + amtWithStacks
          elseif stat == buff_types['mvspd'] then
            self.buff_mvspd_m = self.buff_mvspd_m + amtWithStacks
          elseif stat == buff_types['aspd'] then
            self.buff_aspd_m = self.buff_aspd_m + amtWithStacks
          elseif stat == buff_types['area_dmg'] then
            self.buff_area_dmg_m = self.buff_area_dmg_m + amtWithStacks
          elseif stat == buff_types['area_size'] then
            self.buff_area_size_m = self.buff_area_size_m + amtWithStacks
          elseif stat == buff_types['hp'] then
            self.buff_hp_m = self.buff_hp_m + amtWithStacks
          elseif stat == buff_types['status_resist'] then
            self.status_resist = self.status_resist + amtWithStacks
          elseif stat == buff_types['range'] then
            self.buff_range_m = self.buff_range_m + amtWithStacks
          elseif stat == buff_types['cdr'] then
            self.buff_cdr_m = self.buff_cdr_m + amtWithStacks
          elseif stat == buff_types['percent_def'] then
              self.buff_def_m = self.buff_def_m + stat


          elseif stat == buff_types['eledmg'] then
            self.eledmg_m = self.eledmg_m + amtWithStacks
          elseif stat == buff_types['elevamp'] then
            self.elevamp = self.elevamp + amtWithStacks
          elseif stat == buff_types['vamp'] then
            self.vamp = self.vamp + amtWithStacks

          --flat stats
          elseif stat == buff_types['flat_def'] then
            self.buff_def_a = self.buff_def_a + amtWithStacks
          end
          
        end
      end
    end
  end

  if self.items and #self.items > 0 then
    for k,v in ipairs(self.items) do
      local item = v
      if item.stats then
        for stat, amt in pairs(item.stats) do
          if stat == buff_types['dmg'] then
            self.buff_dmg_m = self.buff_dmg_m + amt
          elseif stat == buff_types['flat_def'] then
            self.buff_def_a = self.buff_def_a + amt
          elseif stat == buff_types['percent_def'] then
            self.buff_def_m = self.buff_dmg_m + amt
          elseif stat == buff_types['mvspd'] then
            self.buff_mvspd_m = self.buff_mvspd_m + amt
          elseif stat == buff_types['aspd'] then
            self.buff_aspd_m = self.buff_aspd_m + amt
          elseif stat == buff_types['range'] then
            self.buff_range_m = self.buff_range_m + amt
          elseif stat == buff_types['area_dmg'] then
            self.buff_area_dmg_m = self.buff_area_dmg_m + amt
          elseif stat == buff_types['area_size'] then
            self.buff_area_size_m = self.buff_area_size_m + amt
          elseif stat == buff_types['hp'] then
            self.buff_hp_m = self.buff_hp_m + amt
          elseif stat == buff_types['status_resist'] then
            self.status_resist = self.status_resist + amt
          elseif stat == buff_types['ghost'] then
            self.ghost = true
          elseif stat == buff_types['enrage'] then
            self.enrage_on_death = true
          elseif stat == buff_types['explode'] then
            self.canExplode = true
          end
        end
      end
    end
  end

  local unit_stat_mult = unit_stat_multipliers[self.character] or unit_stat_multipliers['none']

  self.class_hp_m = self.class_hp_m*unit_stat_mult.hp
  self.max_hp = (self.base_hp + self.class_hp_a + self.buff_hp_a)*self.class_hp_m*self.buff_hp_m
  --need to set hp after buffs
  if first_run then self.hp = self.max_hp end

  self.class_dmg_m = self.class_dmg_m*unit_stat_mult.dmg
  self.dmg = (self.base_dmg + self.class_dmg_a + self.buff_dmg_a)*self.class_dmg_m*self.buff_dmg_m

  self.class_def_m = self.class_def_m*unit_stat_mult.def
  self.def = (self.base_def + self.class_def_a + self.buff_def_a)*self.class_def_m*self.buff_def_m

  self.aspd_m = 1/(self.base_aspd_m*self.buff_aspd_m)

  -- Stats_Max_Aspd(self.buff_aspd_m)
  -- if self.buff_hp_m == 1 then
  --   Stats_Max_Dmg_Without_Hp(self.buff_dmg_m or 0)
  -- end
  if self.baseCooldown then
    self.cooldownTime = self.baseCooldown * self.aspd_m
  end
  if self.baseCast then
    self.castTime = self.baseCast * self.aspd_m
  end

  self.attack_range = ((self.base_attack_range or 0) + self.buff_range_a) * self.buff_range_m

  self.area_size_m = self.base_area_size_m*self.buff_area_size_m

  self.class_mvspd_m = self.class_mvspd_m*unit_stat_mult.mvspd
  self.max_move_v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m*self.slow_mvspd_m
  self.max_v = self.max_move_v * 50
end

function Unit:onTickCallbacks(dt)
  if not main.current:is(Arena) then return end

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_TICK]) do
    proc:onTick(dt, self)
  end

  for k, proc in ipairs(self.onTickProcs) do
    proc:onTick(dt, self)
  end
end

--warning, target can be either a unit or a coordinate
function Unit:onAttackCallbacks(target)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_ATTACK]) do
    proc:onAttack(target, self)
  end

  for k, proc in ipairs(self.onAttackProcs) do
    proc:onAttack(target, self)
  end
end

function Unit:onHitCallbacks(target, damage, damageType)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_HIT]) do
    proc.globalUnit = self
    proc:onHit(target, damage, damageType)
  end

  for k, proc in ipairs(self.onHitProcs) do
    proc:onHit(target, damage, damageType)
  end
end

function Unit:onGotHitCallbacks(from, damage)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_GOT_HIT]) do
    proc.globalUnit = self
    proc:onGotHit(from, damage)
  end
  for k, proc in ipairs(self.onGotHitProcs) do
    proc:onGotHit(from, damage)
  end
end

function Unit:onKillCallbacks(target)

  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_KILL]) do
    proc.globalUnit = self
    proc:onKill(target)
  end
  for k, proc in ipairs(self.onKillProcs) do
    proc:onKill(target)
  end
end

function Unit:onDeathCallbacks(from)
  for k, proc in ipairs(GLOBAL_PROC_LIST[PROC_ON_DEATH]) do
    proc.globalUnit = self
    proc:onDeath(from)
  end

  for k, proc in ipairs(self.onDeathProcs) do
    proc:onDeath(from)
  end
end

function Unit:onMoveCallbacks(distance)
  for k, proc in ipairs(self.onMoveProcs) do
    proc:onMove(distance)
  end
end

function Unit:onRoundStartCallbacks()
  for k, proc in ipairs(self.onRoundStartProcs) do
    proc:onRoundStart()
  end
end

--seems like body.v does not change from nil
function Unit:isMoving(dt)
  local diff = math.distance(self.x, self.y, self.last_x or self.x, self.last_y or self.y)
  self.last_x = self.x
  self.last_y = self.y
  return diff > 0.1
end

--only keep the highest dps buff
function Unit:burn(dps, duration, from)
  local burnBuff = {name = 'burn', color = red[0], duration = duration, maxDuration = duration, nextTick = duration, dps = dps}
  local existing_buff = self.buffs['burn']
  
  if existing_buff and existing_buff.dps > burnBuff.dps then
    return
  else

    self:remove_buff('burn')
    self:add_buff(burnBuff)
  end

end

function Unit:isShielded()
  return self.shielded > 0
end

function Unit:remove_shield()
  self.shielded = 0
end

--keep the highest shield value, don't stack, don't refresh duration
function Unit:shield(amount, duration)
  if self.shielded > amount then return end
  
  local shieldBuff = {name = 'shield', duration = duration, maxDuration = duration, stats = {}}
  self:remove_buff('shield')
  self:add_buff(shieldBuff)
  self.shielded = amount
end

function Unit:redshield(duration)
  local redshieldBuff = {name = 'redshield', color = grey[0], duration = duration, maxDuration = duration,
    stacks = 1, stats = {def = 1}}
  local existing_buff = self.buffs['redshield']

  if existing_buff then
    redshieldBuff.stacks = math.min((existing_buff.stack or 1) + 1, MAX_STACKS_REDSHIELD)
  end
  self:remove_buff('redshield')
  self:add_buff(redshieldBuff)
end

function Unit:shock(duration)
  local shockBuff = {name = 'shock', color = yellow[0], duration = duration, maxDuration = duration, stats = {buff_def_m = SHOCK_DEF_REDUCTION}}
  local existing_buff = self.buffs['shock']

  shockBuff.stacks = 1
  if existing_buff then
    shockBuff.stacks = math.min((existing_buff.stacks or 1) + 1, MAX_STACKS_SHOCK)
  end

  self:remove_buff('shock')
  self:add_buff(shockBuff)
end

function Unit:stun(duration)
  --dont stun bosses
  if self.class == 'boss' then
    return
  end
  local stunBuff = {name = 'stunned', color = black[0], duration = duration}
  self:add_buff(stunBuff)
  self:interrupt_cast()
end

function Unit:root(duration)
  if self.class == 'boss' then
    return
  end
  local rootBuff = {name = 'rooted', color = green[0], duration = duration}
  self:add_buff(rootBuff)
end

--only keep the highest slow amount
function Unit:slow(amount, duration, from)
  local slowBuff = {name = 'slowed', color = blue[2], duration = duration, maxDuration = duration, stats = {mvspd = -1 * amount}}
  local existing_buff = self.buffs['slowed']

  if existing_buff and existing_buff.stats.mvspd > slowBuff.stats.mvspd then
    return
  else
    self:remove_buff('slowed')
    self:add_buff(slowBuff)
  end

end

--only keep the highest chill amount
function Unit:chill(amount, duration, from)
  local chillBuff = {name = 'chilled', color = blue[0], duration = duration, maxDuration = duration, stats = {mvspd = -1 * amount}}
  local existing_buff = self.buffs['chilled']
  
  if existing_buff and existing_buff.stats.mvspd > chillBuff.stats.mvspd then
    return
  else
    self:remove_buff('chilled')
    self:add_buff(chillBuff)
  end
end

function Unit:freeze(duration, from)
  local freezeBuff = {name = 'frozen', color = blue[0], duration = duration, maxDuration = duration}
  self:add_buff(freezeBuff)
end

function Unit:set_invulnerable(duration)
  local invulnerableBuff = {name = 'invulnerable', color = white[0], duration = duration, maxDuration = duration}
  self:add_buff(invulnerableBuff)
end

function Unit:bloodlust(duration)
  local bloodlustBuff = {name = 'bloodlust', color = purple[5], duration = duration, maxDuration = duration, 
    stats = {aspd = 0.1, mvspd = 0.05}
  }
  local existing_buff = self.buffs['bloodlust']

  bloodlustBuff.stacks = 1
  if existing_buff then
    bloodlustBuff.stacks = math.min((existing_buff.stacks or 1) + 1, MAX_STACKS_BLOODLUST)
  end

  self:remove_buff('bloodlust')
  self:add_buff(bloodlustBuff)
end

function Unit:set_as_target()
  local targetBuff = {name = 'target', color = yellow[0], duration = 9999, stats = nil}
  self:add_buff(targetBuff)
end

function Unit:untarget()
  self:remove_buff('target')
end

function Unit:get_closest_target(shape, classes)
  local target = self:get_closest_object_in_shape(shape, classes)
  if target then
    return target
  end
end

function Unit:get_random_target(shape, classes)
  local targets = self:get_objects_in_shape(shape, classes)
  if targets and #targets > 0 then
    return targets[math.random(#targets)]
  end
end

function Unit:get_closest_hurt_target(shape, classes)
  local targets = self:get_objects_in_shape(shape, classes)
  if targets and #targets > 0 then
    return targets[math.random(#targets)]
  end

end

--unit level state functions
function Unit:start_backswing()
  --unit should always be 'casting' when this is called
  --if the unit stops casting, the spell should be cancelled
  if self.state == unit_states['casting'] then
    self.state = unit_states['stopped']
  else
    print('error: unit not casting when start_backswing called', self.type)
  end
end

function Unit:end_backswing()
  if self.state == unit_states['stopped'] then
    self.state = unit_states['normal']
  end
end

--2 types of target, assigned target is set by the player (RMB)
--the regular target is temporary and is set by the unit itself
function Unit:my_target()
  return self.assigned_target or self.target
end

function Unit:set_target(target)
  self.target = target
end

function Unit:set_assigned_target(target)
  self.assigned_target = target
end

function Unit:clear_assigned_target()
  self.assigned_target = nil
end

function Unit:clear_my_target()
  self.target = nil
end

function Unit:update_targets()
  if self.target and self.target.dead then
    self.target = nil
  end
  if self.assigned_target and self.assigned_target.dead then
    self.assigned_target = nil
  end
end

--need melee units to not move inside the target
--need ranged units to move close enough to attack
function Unit:in_range()
  return function()
    local target = self:my_target()
    local target_size_offset = 0
    if self.attack_range and self.attack_range < MELEE_ATTACK_RANGE and target and not target.dead then
      target_size_offset = target.shape.w/2
    end
    return target and 
      not target.dead and 
      table.any(unit_states_can_target, function(v) return self.state == v end) and 
      self:distance_to_object(target) - target_size_offset < self.attack_sensor.rs
  end
end

function Unit:in_aggro_range()
  return function()
    local target = self:my_target()
    local target_size_offset = 0
    if self.attack_range and self.attack_range < MELEE_ATTACK_RANGE and target and not target.dead then
      target_size_offset = target.shape.w/2
    end
    return target and 
      not target.dead and 
      table.any(unit_states_can_target, function(v) return self.state == v end) and 
      self:distance_to_object(target) - target_size_offset < self.aggro_sensor.rs
  end
end

--looks like space is the override for all units move
--and RMB sets 'following' or 'rallying' state in player_troop?
--change to the original control design
-- space for "all units follow mouse"
-- LMB for "selected troop follows mouse"
-- shift+ LMB for "selected troop rallies to mouse"
-- RMB for "selected troop targets enemy"


--controls possibiltiies:
-- RMB - target enemy
-- RMB - target enemy OR rally to location
-- RMB - target enemy OR attack move while holding button
-- RMB- target enemy OR attack move to location
function Unit:should_follow()
  local input = input['space'].down
  if input then
    Helper.Unit:clear_all_rally_points()
    if self.cancel_cast then
      self:cancel_cast()
    end 
  end
  local canMove = table.any(unit_states_can_move, function(v) return self.state == v end)

  return input and canMove
end

--casting functions
-- uses 
-- self.castcooldown as the cooldown until the next spell
-- self.base_castcooldown as the base cooldown for the unit
-- self.baseCast ?? as the cast time for the spell (unless otherwise specified)

-- in update(), calls pick_cast() if the unit has spells and is ready to cast
-- 'normal' and castcooldown exists and is <= 0

-- pick_cast() calls start_cast()
-- which sets the unit state to 'casting'
-- sets currentcast to be the spell.cast()
-- casts the spell.oncaststart()
-- and sets currentcast to be the spell castcooldown

--then the update_cast()
-- ticks based on last_attack_started
-- and calls the currentcast() when the time is up

--confusing between castTime, baseCast, currentcast
-- need baseCast and castTime for player units w aspd
-- spell castcooldown should be modified by aspd as well

-- currentcast is the function that is called when the cast is finished
-- castcooldown is the unit's cooldown until the next cast

--freezeduration is the time before the cast is finished when the unit stops rotating
--(so player can escape the cast), linked to freezerotation

--should be able to interrupt the cast with stuns or something, and have it kill the 
--existing spell (say for a channeling spell)

function Unit:pick_cast()
  if not self.attack_options then return end

  local viable_attacks = {}
  for k, v in pairs(self.attack_options) do
    if v.viable(self) then
      table.insert(viable_attacks, v)
    end
  end

  if #viable_attacks == 0 then return false end

  local attack = random:table(viable_attacks)

  self:cast(attack)
  return true
end

function Unit:update_cast_cooldown(dt)
  if self.castcooldown > 0 then
    self.castcooldown = self.castcooldown - dt
  end
end

function Unit:cast(castData)
  if castData.spellclass then
    if castData.oncast then
      castData.oncast(self)
    end
    local castCopy = Deep_Copy_Cast(castData)
    castCopy.x = self.x
    castCopy.y = self.y
    castCopy.unit = self
    castCopy.target = self:my_target()
    self.castObject = Cast(castCopy)
  else
    print('spellclass not found', castData.name)
  end
end

function Unit:should_freeze_rotation()
  return self.freezerotation
    or (self.castObject and self.castObject.freeze_rotation)
    or (self.spellObject and self.spellObject.freeze_rotation)
end

function Unit:end_cast(cooldown)
  self.castcooldown = cooldown
  self.total_castcooldown = cooldown
  self.spelldata = nil
  self.freezerotation = false
  if self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
    self.state = unit_states['normal']
  end

  self.castObject = nil
  self.spellObject = nil
end


--remove the castObject before calling die()
-- to prevent the infinite loop
function Cancel_Cast_And_Spell(unit)
  local castObject = unit.castObject
  local spellObject = unit.spellObject
  unit.castObject = nil
  unit.spellObject = nil
  if castObject then
    castObject:cancel()
  end
  if spellObject then
    spellObject:cancel()
  end
end


--infinite loop, this calls cast:cancel() which calls this
--but broken by removing the castObject before calling die()
-- and the death check
function Unit:cancel_cast()

  if self.state == unit_states['casting'] or self.state == unit_states['channeling'] then
    self.state = unit_states['normal']
    self.castcooldown = 0
    self.spelldata = nil
  end

  Cancel_Cast_And_Spell(self)
end

function Unit:interrupt_cast()
  if self.castObject or self.spellObject then
    self.castcooldown = self.baseCast or 1
    self.spelldata = nil
    Cancel_Cast_And_Spell(self)
  end
end

--for channeling spells, if they are hit while casting
function Unit:delay_cast()

end

function Unit:launch_at_facing(force_magnitude, duration)
  if self.state == unit_states['casting'] then
    self.state = unit_states['channeling']
  end

  duration = duration or 0.7

  local mass
  if self.body then
    mass = self.body:getMass()
  else
    mass = 1
  end

  self.is_launching = true
  self.t:after(duration, function() self.is_launching = false end, 'launch_end')
  local facing = self:get_angle()
  self.launch_force_x = math.cos(facing) * force_magnitude * mass
  self.launch_force_y = math.sin(facing) * force_magnitude * mass
  self:set_velocity(0, 0)
  self:apply_impulse(self.launch_force_x, self.launch_force_y)
  

  local orig_damping
  if self.body then
    orig_damping = self:get_damping()
  else
    orig_damping = BOSS_DAMPING
  end

  local orig_friction
  if self.body then
    orig_friction = self:get_friction()
  else
    orig_friction = 0
  end

  self:set_damping(0)
  self:set_friction(0.4)

  self.t:after(duration, function()
    self:set_velocity(0, 0)
    self:set_damping(orig_damping)
    self:set_friction(orig_friction)
    self.is_launching = false
    
  end)



end

function Unit:die()
  --cleanup buffs
  for k, v in pairs(self.buffs) do
    self:remove_buff(k)
  end
  for k, v in pairs(self.procs) do
    v:die()
  end
  --killing the items should kill the procs as well
  --but it is only the itemdata on the unit, not the actual item
  -- for k, v in pairs(self.items) do
  --   v:die()
  -- end

end


EffectBar = Object:extend()
EffectBar:implement(GameObject)
EffectBar:implement(Parent)
function EffectBar:init(args)
  self:init_game_object(args)
  self.hidden = true
  self.color = fg[0]
end


function EffectBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()
end


function EffectBar:draw()
  if self.hidden then return end
  --[[
  local p = self.parent
  graphics.push(p.x, p.y, p.r, p.hfx.hit.x, p.hfx.hit.x)
    graphics.rectangle(p.x, p.y, 3, 3, 1, 1, self.color)
  graphics.pop()
  ]]--
end




HPBar = Object:extend()
HPBar:implement(GameObject)
HPBar:implement(Parent)
function HPBar:init(args)
  self:init_game_object(args)
  self.hidden = true
  if self.isBoss then
    self.hidden = false
  end

  self.last_hp = self.parent.hp
end


function HPBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()

  --update "last hp" for the hp bar effect
  --messy AF!
  if self.isBoss and self.parent and self.last_hp ~= self.parent.hp then
    local w = 200
    local x = gw/2 - w/2

    local x1 = self:get_percent_hp() * w + x 
    local x2 = self:get_percent_hp(self.last_hp) * w + x
    
    HPBar_Damage_Chunk{
      group = main.current.effects,
      x1 = x1,
      y1 = 20,
      x2 = x2,
      y2 = 20,
    }
    self.last_hp = self.parent.hp
  end
end

function HPBar:get_percent_hp(hp)
  local p = self.parent
  return math.remap(hp or p.hp, 0, p.max_hp, 0, 1)
end


function HPBar:draw()
  if self.hidden then return end
  
  local p = self.parent
  local n = self:get_percent_hp()

  if self.isBoss then
    local w = 200
    local h = 10
    local x = gw/2 - w/2
    local y = 20
    graphics.line(x, y, x + w, y, bg[-3], h)
    graphics.line(x, y, x + n*w, y, red[0], h)
    skull:draw(x + n*w, y, 0, 0.4, 0.4)
  else
    if p.hp < p.max_hp then
      graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
        graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x + 0.5*p.shape.w, p.y - p.shape.h, bg[-3], 2)
        graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x - 0.5*p.shape.w + n*p.shape.w, p.y - p.shape.h,
        p.hfx.hit.f and fg[0] or (((p:is(Player) or p.is_troop) and green[0]) or (table.any(main.current.enemies, function(v) return p:is(v) end) and red[0])), 2)
      graphics.pop()
    end
  end
end

HPBar_Damage_Chunk = Object:extend()
HPBar_Damage_Chunk:implement(GameObject)
function HPBar_Damage_Chunk:init(args)
  self:init_game_object(args)
  self.start_time = Helper.Time.time
  self.duration = 1
  self.a = 1
  self.color = white[0]
end

function HPBar_Damage_Chunk:update(dt)
  self:update_game_object(dt)
  if Helper.Time.time - self.start_time > self.duration then
    self.dead = true
  end
  self.a = math.remap(Helper.Time.time - self.start_time, 0, self.duration, 1, 0)
end

function HPBar_Damage_Chunk:draw()
  local color = self.color:clone()
  color.a = self.a
  graphics.line(self.x1, self.y1, self.x2, self.y2, color, 10)
end



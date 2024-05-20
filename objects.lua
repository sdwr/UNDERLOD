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

Buff = Object:extend()
function Buff:init(name, duration, color)
  self.name = name
  self.duration = duration
  self.color = color
  self.stats = {}
end

function Create_buff_dmg(duration)
  local name = "dmg/0.2"
  local buff = Buff(name, duration, red_transparent_weak)
  buff.stats[buff_types['dmg']] = 0.2
  return buff
end

function Create_buff_druid_hot(duration)
  local name = 'druid_hot'
  local buff = Buff(name, duration, green_transparent_weak)
  buff.heal_per_s = 5
  return buff
end





Unit = Object:extend()
function Unit:init_unit()
  self.level = self.level or 1
  self.target = nil
  self.buffs = {}
  self.toggles = {}
  self.hfx:add('hit', 1)
  self.hfx:add('shoot', 1)
  self.hp_bar = HPBar{group = main.current.effects, parent = self}
  self.effect_bar = EffectBar{group = main.current.effects, parent = self}

  self.state = unit_states['normal']

  Helper.Unit:add_custom_variables_to_unit(self)
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


function Unit:show_hp(n)
  self.hp_bar.hidden = false
  self.hp_bar.color = red[0]
  --self.t:after(n or 2, function() self.hp_bar.hidden = true end, 'hp_bar')
end

function Unit:hide_hp()
  self.hp_bar.hidden = true
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
function Unit:has_buff(buffName)
  return self.buffs[buffName] ~= nil
end

function Unit:add_buff(buff)
  local existing_buff = self.buffs[buff.name]

  --overwrite duration and nextTick if the buff is already present
  if existing_buff then
    self.buffs[buff.name].duration = math.max(existing_buff.duration, buff.duration)
    if buff.nextTick then
      self.buffs[buff.name].nextTick = buff.nextTick
    end
  else
    if buff.color then
      local color = buff.color
      color.a = 0.6
      buff.color = color
    end
    self.buffs[buff.name] = buff
    self:increment_buff_toggles(buff)
  end
end

function Unit:remove_buff(buffName)
  local existing_buff = self.buffs[buffName]
  if existing_buff then
    self.buffs[buffName] = nil
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

--should move this somewhere, maybe to the proc class
-- dont want to have a bunch of if statements in here
-- with special logic for each buff
function Unit:update_buffs(dt)
  for k, v in pairs(self.buffs) do
    --on buff start
    if k == 'stunned' then
      self.state = unit_states['frozen']
    end

    --dec duration
    v.duration = v.duration - dt

    --on buff tick
    if k == 'burn' then
      if v.duration <= v.nextTick then
        --add a really quiet short sound here, because it'll be playing all the time
        self:hit(v.dps * (v.stacks or 1), nil)
        --1 second tick, could be changed
        v.nextTick = v.nextTick - 1
      end
    end

    --on buff end
    if v.duration < 0 then
      if k == 'bash_cd' then
        self.canBash = true
      elseif k == 'stunned' then
        self.state = unit_states['normal']
      end
      if v.stacks and v.stacks > 1 then
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
  --constants? remove
  local level = self.level or 1
  local hpMod = 1 + ((level - 1) / 2)
  local dmgMod = 1 + ((level - 1) / 2)
  local spdMod = 1
  
  --init base stats
  if self:is(Player) then
    self.base_hp = 100
    self.base_dmg = 10
    self.base_mvspd = 50
  elseif self.is_troop then
    self.base_hp = 100 * hpMod
    self.base_dmg = 10 * dmgMod
    self.base_mvspd = 67 * spdMod
  elseif self:is(EnemyCritter) or self:is(Critter) then
    self.base_hp = 25 * hpMod
    self.base_dmg = 5 * dmgMod
    self.base_mvspd = 100 * spdMod
  elseif self.class == 'regular_enemy' then
    self.base_hp = 100 * (math.pow(1.02, level))
    self.base_dmg = 20  * (math.pow(1.02, level))
    self.base_mvspd = 34
  elseif self.class == 'miniboss' then
    self.base_hp = 500 * (math.pow(1.02, level))
    self.base_dmg = 20  * (math.pow(1.02, level))
    self.base_mvspd = 55
  end
  if self.class == 'boss' then
    self.base_hp = 1500 * (1 + ((level / 6) * 0.25))
    self.base_dmg = 30
    self.base_mvspd = 34
  end

  self.baseCooldown = self.baseCooldown or attack_speeds['medium']
  self.baseCast = self.baseCast or attack_speeds['medium-cast']
  
  --add per-attack procs from items here
  self.procs = {}

  self.onTickProcs = {}
  self.onHitProcs = {}
  self.onAttackProcs = {}
  self.onGotHitProcs = {}
  self.onKillProcs = {}
  self.onDeathProcs = {}
  self.onMoveProcs = {}
  if self.items and #self.items > 0 then
    for k,item in ipairs(self.items) do
      if item.procs then
        for _, proc in ipairs(item.procs) do
          local procname = proc
          --can fill data from item here, but defaults should be ok
          print(procname)
          local procObj = proc_name_to_class[procname]{unit = self, data = {name = procname}}
          table.insert(self.procs, procObj)

          --add procs to the unit callback lists here
          -- could be done in the proc class, but this is more readable
          -- still need to deal with proc deletion, right now they should be cleared at end of round (I hope??)
          if procObj:hasTrigger(PROC_ON_HIT)  then
            table.insert(self.onHitProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_ATTACK) then
            table.insert(self.onAttackProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_GOT_HIT) then
            table.insert(self.onGotHitProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_KILL) then
            table.insert(self.onKillProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_DEATH) then
            table.insert(self.onDeathProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_MOVE) then
            table.insert(self.onMoveProcs, procObj)
          end
          if procObj:hasTrigger(PROC_ON_TICK) then
            table.insert(self.onTickProcs, procObj)
          end
        end
      end
    end
  end

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
  self.buff_attack_range_a = 0
  self.buff_attack_range_m = 1

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
        elseif stat == buff_types['def'] then
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
          elseif stat == buff_types['attack_range'] then
            self.buff_attack_range_m = self.buff_attack_range_m + amtWithStacks

          --flat stats
          elseif stat == buff_types['def'] then
            self.buff_def_a = self.buff_def_a + amtWithStacks
          --should do this after all other stats are calculated
          elseif stat == buff_types['dmg_per_def'] then
            local def = self.buff_def_a
            self.buff_dmg_a = self.buff_dmg_a + def*amtWithStacks
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
          elseif stat == buff_types['def'] then
            self.buff_def_m = self.buff_dmg_m + amt
          elseif stat == buff_types['mvspd'] then
            self.buff_mvspd_m = self.buff_mvspd_m + amt
          elseif stat == buff_types['aspd'] then
            self.buff_aspd_m = self.buff_aspd_m + amt
          elseif stat == buff_types['attack_range'] then
            self.buff_attack_range_m = self.buff_attack_range_m + amt
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

  if self.baseCooldown then
    self.cooldownTime = self.baseCooldown * self.aspd_m
  end
  if self.baseCast then
    self.castTime = self.baseCast * self.aspd_m
  end

  self.attack_range = ((self.base_attack_range or 0) + self.buff_attack_range_a) * self.buff_attack_range_m

  self.area_size_m = self.base_area_size_m*self.buff_area_size_m

  self.class_mvspd_m = self.class_mvspd_m*unit_stat_mult.mvspd
  self.max_v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m*self.slow_mvspd_m
  self.v = (self.base_mvspd + self.class_mvspd_a + self.buff_mvspd_a)*self.class_mvspd_m*self.buff_mvspd_m*self.slow_mvspd_m
end

function Unit:onTickCallbacks(dt)
  for k, proc in ipairs(self.onTickProcs) do
    proc:onTick(dt)
  end
end

--warning, target can be either a unit or a coordinate
function Unit:onAttackCallbacks(target)
  for k, proc in ipairs(self.onAttackProcs) do
    proc:onAttack(target)
  end
end

function Unit:onHitCallbacks(from, damage)
  for k, proc in ipairs(self.onHitProcs) do
    proc:onHit(from, damage)
  end
end

function Unit:onGotHitCallbacks(from, damage)
  for k, proc in ipairs(self.onGotHitProcs) do
    proc:onGotHit(from, damage)
  end
end

function Unit:onKillCallbacks(target)
  for k, proc in ipairs(self.onKillProcs) do
    proc:onKill(target)
  end
end

function Unit:onDeathCallbacks()
  for k, proc in ipairs(self.onDeathProcs) do
    proc:onDeath()
  end
end

function Unit:onMoveCallbacks(distance)
  for k, proc in ipairs(self.onMoveProcs) do
    proc:onMove(distance)
  end
end

--add custom UI later, so it doesn't stack with the buff circles
--check firestack on from unit to see if it can stack
function Unit:burn(dps, duration, from)
  local burnBuff = {name = 'burn', color = red[0], duration = duration, maxDuration = duration, nextTick = duration - 1, dps = dps}
  local existing_buff = self.buffs['burn']
  
  burnBuff.stacks = 1
  if from and from:has_toggle('firestack') and existing_buff then
    burnBuff.stacks = math.min((existing_buff.stacks or 1) + 1, MAX_STACKS_FIRE)
  end

  --assume we only have 1 dps of burn for now
  --duration gets overwritten if the buff is already present, but the dps doesn't stack
  --handle dps * stacks and stacks falling off in the update function
  self:remove_buff('burn')
  self:add_buff(burnBuff)
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


function Unit:explode(enemy)
  local damage_troops = not self.is_troop
  local radius = enemy.shape.w * self.area_size_m
  explosion1:play{volume = 0.7}
  Helper.Spell.DamageCircle:create(self, black[0], damage_troops, enemy.max_hp * 0.2, 
  radius, enemy.x, enemy.y)
end

function Unit:stun(duration)
  local stunBuff = {name = 'stunned', color = black[0], duration = duration}
  self:add_buff(stunBuff)
end

function Unit:slow(amount, duration, from)
  local slowBuff = {name = 'slowed', color = blue[2], duration = duration, maxDuration = duration, stats = {mvspd = -1 * amount}}
  local existing_buff = self.buffs['slowed']

  slowBuff.stacks = 1
  if from and from:has_toggle('slowstack') and existing_buff then
    slowBuff.stacks = math.min((existing_buff.stacks or 1) + 1, MAX_STACKS_SLOW)
  end

  self:remove_buff('slowed')
  self:add_buff(slowBuff)
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

function Unit:in_range()
  return function()
    return self.target and not self.target.dead and self.state == unit_states['normal'] and self:distance_to_object(self.target) - self.target.shape.w/2 < self.attack_sensor.rs
  end
end

--looks like space is the override for all units move
--and RMB sets 'following' or 'rallying' state in player_troop?
--change to the original control design
-- space for "all units follow mouse"
-- LMB for "selected troop follows mouse"
-- shift+ LMB for "selected troop rallies to mouse"
-- RMB for "selected troop targets enemy"

function Unit:should_follow()
  local input = input['space'].down
  local canMove = (self.state == unit_states['normal'] or self.state == unit_states['stopped'] or self.state == unit_states['rallying'] or self.state == unit_states['following'] or self.state == unit_states['casting'])

  return input and canMove

end

function Unit:die()
  --cleanup buffs
  for k, v in pairs(self.buffs) do
    self:remove_buff(k)
  end

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
end


function HPBar:update(dt)
  self:update_game_object(dt)
  self:follow_parent_exclusively()
end


function HPBar:draw()
  if self.hidden then return end
  local p = self.parent
  if p.hp < p.max_hp then
    graphics.push(p.x, p.y, 0, p.hfx.hit.x, p.hfx.hit.x)
      graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x + 0.5*p.shape.w, p.y - p.shape.h, bg[-3], 2)
      local n = math.remap(p.hp, 0, p.max_hp, 0, 1)
      graphics.line(p.x - 0.5*p.shape.w, p.y - p.shape.h, p.x - 0.5*p.shape.w + n*p.shape.w, p.y - p.shape.h,
      p.hfx.hit.f and fg[0] or (((p:is(Player) or p.is_troop) and green[0]) or (table.any(main.current.enemies, function(v) return p:is(v) end) and red[0])), 2)
    graphics.pop()
  end
end

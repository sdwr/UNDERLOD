NetBehavior = {}

NetBehavior.global_timer = 0
NetBehavior.lightning_cooldown = 2.5
NetBehavior.lightning_warning_duration = 0.8
NetBehavior.lightning_duration = 1.0
NetBehavior.showing_warning = false
NetBehavior.warning_started = false
NetBehavior.warning_sound = nil
NetBehavior.all_nets = {}

function NetBehavior.reset()
  NetBehavior.global_timer = NetBehavior.lightning_cooldown
  NetBehavior.showing_warning = false
  NetBehavior.warning_started = false
  NetBehavior.all_nets = {}
end

function NetBehavior.register_net(net)
  table.insert(NetBehavior.all_nets, net)
end

function NetBehavior.unregister_net(net)
  for i = #NetBehavior.all_nets, 1, -1 do
    if NetBehavior.all_nets[i] == net then
      table.remove(NetBehavior.all_nets, i)
      break
    end
  end
end

function NetBehavior.update(dt)
  for i = #NetBehavior.all_nets, 1, -1 do
    if NetBehavior.all_nets[i].dead then
      table.remove(NetBehavior.all_nets, i)
    end
  end

  local active_nets = NetBehavior.get_active_nets()
  if #active_nets < 2 then
    return
  end

  NetBehavior.global_timer = NetBehavior.global_timer - dt

  if NetBehavior.showing_warning then
    if NetBehavior.global_timer <= 0 then
      NetBehavior.showing_warning = false
      NetBehavior.warning_started = false
      if NetBehavior.warning_sound then
        NetBehavior.warning_sound:stop()
      end
      NetBehavior.warning_sound = nil
      NetBehavior.create_all_lightning_lines()
      NetBehavior.global_timer = NetBehavior.lightning_cooldown
    end
  elseif NetBehavior.global_timer <= 0 then
    NetBehavior.start_warning()
  end
end

function NetBehavior.get_active_nets()
  local active = {}
  for _, net in ipairs(NetBehavior.all_nets) do
    if not net.dead and net.fully_onscreen then
      table.insert(active, net)
    end
  end
  return active
end

function NetBehavior.start_warning()
  NetBehavior.showing_warning = true
  NetBehavior.warning_started = true
  NetBehavior.global_timer = NetBehavior.lightning_warning_duration

  NetBehavior.warning_sound = laser_charging:play{pitch = random:float(1.3, 1.5), volume = 0.15}
end

function NetBehavior.create_all_lightning_lines()
  local active_nets = NetBehavior.get_active_nets()

  if #active_nets < 2 then return end

  spark2:play{pitch = random:float(1.3, 1.5), volume = 0.6}

  for i = 1, #active_nets do
    for j = i + 1, #active_nets do
      local net1 = active_nets[i]
      local net2 = active_nets[j]

      LightningLine{
        group = main.current.effects,
        src = net1,
        dst = net2,
        color = blue[5],
        generations = 4,
        max_offset = 10,
        duration = NetBehavior.lightning_duration
      }

      local center_x = (net1.x + net2.x) / 2
      local center_y = (net1.y + net2.y) / 2
      local length = math.distance(net1.x, net1.y, net2.x, net2.y)
      local angle = math.atan2(net2.y - net1.y, net2.x - net1.x)

      Area_Spell{
        group = main.current.main,
        x = center_x,
        y = center_y,
        r = angle,
        pick_shape = 'line',
        width = length,
        height = 8,
        duration = NetBehavior.lightning_duration,
        damage = net1.dmg * 0.5,
        damage_type = DAMAGE_TYPE_LIGHTNING,
        unit = net1,
        is_troop = false,
        damage_ticks = true,
        tick_rate = 0.1,
        hit_only_once = true,
        color = blue[5],
        opacity = 0,
        draw_shape = false
      }
    end
  end
end

function NetBehavior.draw_warning_lines()
  if not NetBehavior.showing_warning then return end

  local active_nets = NetBehavior.get_active_nets()
  if #active_nets < 2 then return end

  local alpha = math.abs(math.sin((Helper.Time.time or 0) * 12))

  for i = 1, #active_nets do
    for j = i + 1, #active_nets do
      local net1 = active_nets[i]
      local net2 = active_nets[j]

      local warning_color = yellow[0]:clone()
      warning_color.a = alpha * 0.7
      graphics.line(net1.x, net1.y, net2.x, net2.y, warning_color, 3)
    end
  end
end


Spell_Laser = Spell:extend()
function Spell_Laser:init(args)
  Spell_Laser.super.init(self, args)
end

--laser spell only draws the sight
--the actual laser is drawn in the damage line
--means laser spell is only alive while aiming
function Spell_Laser:draw()
  love.graphics.setLineWidth(self.laser_aim_width)
  love.graphics.setColor(self.color.r, self.color.g, self.color.b, 0.5)
  if self.direction_lock then
      love.graphics.line(self.unit.x, self.unit.y, Helper.Spell.Laser:get_end_location(self.unit.x, self.unit.y, self.unit.x + self.direction_targetx, self.unit.y + self.direction_targety))
  else
      local x, y = Helper.Spell:get_claimed_target_nearest_point(self.unit)
      love.graphics.line(self.unit.x, self.unit.y, Helper.Spell.Laser:get_end_location(self.unit.x, self.unit.y, x, y))
  end
end

function Spell_Laser:update()
  if Helper.Time.time - self.start_aim_time > self.cast_time and not self.holding_fire then
    --fire laser
    if self.direction_lock then
        Helper.Spell.DamageLine:create(self.unit, self.color, self.laser_aim_width * 3, self.damage_troops, self.damage, self.unit.x, self.unit.y, Helper.Spell.Laser:get_end_location(self.unit.x, self.unit.y, self.unit.x + self.direction_targetx, self.unit.y + self.direction_targety), true)
    else
        local x, y = Helper.Spell:get_claimed_target_nearest_point(self.unit)
        Helper.Spell.DamageLine:create(self.unit, self.color, self.laser_aim_width * 3, self.damage_troops, self.damage, self.unit.x, self.unit.y, Helper.Spell.Laser:get_end_location(self.unit.x, self.unit.y, x, y), true)
    end
    shoot1:play{volume=0.7}

    self.unit.last_attack_finished = Helper.Time.time
    Helper.Unit:unclaim_target(self.unit)
    Helper.Unit:finish_casting(self.unit)
    self:die()
  end
end

function Spell_Laser:hold_fire()
  self.holding_fire = true
end

function Spell_Laser:continue_fire()
  self.holding_fire = false
  self.start_aim_time = Helper.Time.time - 1
end

--need to associate with unit somehow
--but also have a global spell list
-- so we can stop aiming if the unit moves
--and delete all spells if the unit dies
function Spell_Laser:stop_aiming()
  self.unit.have_target = false
  self:die()
end

function Spell_Laser:get_end_location(x, y, targetx, targety)
  local deltax = math.abs(targetx - x)
  local deltay = math.abs(targety - y)
  local length_to_window_width = 0
  local length_to_window_height = 0
  local endx = 0
  local endy = 0

  if targetx - x > 0 and targety - y > 0 then
      length_to_window_width = Helper.window_width - x
      length_to_window_height = Helper.window_height - y

      if length_to_window_height ~= 0 and deltay ~= 0 then
          if length_to_window_width / length_to_window_height > deltax / deltay then
              endy = Helper.window_height
              endx = x + length_to_window_height * (deltax / deltay)
          else
              endx = Helper.window_width
              endy = y + length_to_window_width * (deltay / deltax)
          end
      end

  elseif targetx - x < 0 and targety - y > 0 then
      length_to_window_width = x
      length_to_window_height = Helper.window_height - y

      if length_to_window_height ~= 0 and deltay ~= 0 then
          if length_to_window_width / length_to_window_height > deltax / deltay then
              endy = Helper.window_height
              endx = x - length_to_window_height * (deltax / deltay)
          else
              endx = 0
              endy = y + length_to_window_width * (deltay / deltax)
          end
      end

  elseif targetx - x < 0 and targety - y < 0 then
      length_to_window_width = x
      length_to_window_height = y

      if length_to_window_height ~= 0 and deltay ~= 0 then
          if length_to_window_width / length_to_window_height > deltax / deltay then
              endy = 0
              endx = x - length_to_window_height * (deltax / deltay)
          else
              endx = 0
              endy = y - length_to_window_width * (deltay / deltax)
          end
      end

  elseif targetx - x > 0 and targety - y < 0 then
      length_to_window_width = Helper.window_width - x
      length_to_window_height = y

      if length_to_window_height ~= 0 and deltay ~= 0 then
          if length_to_window_width / length_to_window_height > deltax / deltay then
              endy = 0
              endx = x + length_to_window_height * (deltax / deltay)
          else
              endx = Helper.window_width
              endy = y - length_to_window_width * (deltay / deltax)
          end
      end
  end

  return endx, endy
end
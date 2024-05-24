
Arrow_Proj = Object:extend()
Arrow_Proj:implement(GameObject)
Arrow_Proj:implement(Physics)
function Arrow_Proj:init(args)
  self:init_game_object(args)
  
  self.damage = self.damage or 10
  self.speed = 400
  self.color = self.color or Helper.Color.blue
  self.unit = self.unit
  self.target = self.target
  self.x = self.unit.x
  self.y = self.unit.y

  self.r = 2
  
  self.shape = Rectangle(self.x, self.y, self.r, self.r)
end

function Arrow_Proj:update(dt)
  self:update_game_object(dt)

  local xdist = self.target.x - self.x
  local ydist = self.target.y - self.y
  local angle = math.atan2(ydist, xdist)
  self.x = self.x + math.cos(angle) * self.speed * dt
  self.y = self.y + math.sin(angle) * self.speed * dt


  self.shape:move_to(self.x, self.y)

  if self.dead then return end
  if not self.target then self:die() end
  if self.target.dead then self:die() end

  if math.distance(self.x, self.y, self.target.x, self.target.y) < 10 then
    hit2:play{volume=0.7}
    self.target:hit(self.damage, self.unit)
    self:die()
  end
end

function Arrow_Proj:draw()
  graphics.circle(self.x, self.y, self.r, self.color)
end

function Arrow_Proj:die()
  self.dead = true
end

require 'helper/spells/v2/spell'

Spell_Arrow = Spell:extend()
function Spell_Arrow:init(args)
  Spell_Arrow.super.init(self, args)

  --this should be in the super
  self.unit = self.unit

  self.damage = self.damage or 10
  self.castTime = self.castTime or 0.5
  self.target = self.target
  self.color = self.color or Helper.Color.blue
  self.backSwing = self.backSwing or 0.2
  
end


function Spell_Arrow:update(dt)
  Spell_Arrow.super.update(self, dt)

  if self.dead then
    print("this spell is dead")
    return
  end
  if Helper.Time.time - self.startTime > self.castTime then
    self:cast()
  end
end

--cancel cast if unit is dead or not casting
function Spell_Arrow:confirmCast()
  --cancel cast if unit is dead or not casting
  if not self.unit then
    print('no unit')
    self:die()
    return false
  end
  if self.unit.dead == true then
    print('unit dead')
    self:die()
    return false
  end
  if not self.unit.state == unit_states['casting'] then
    print('unit not casting')
    self:die()
    return false
  end

  return true
end


function Spell_Arrow:cast()

  if not self:confirmCast() then return end
  
  --set the unit to backswing
  if self.unit then self.unit:start_backswing() end
  --launch projectile here
  alert1:play{volume=0.9}
  local data = {
    group = self.group,
    target = self.target,
    unit = self.unit,
    damage = self.damage,
    color = self.color
  }
  Arrow_Proj(data)
  self:die()

  self.unit.last_attack_finished = Helper.Time.time
  trigger:after(self.backSwing, function()
    if self.unit then self.unit:end_backswing() end
  end)
end

function Spell_Arrow:draw()
  Spell_Arrow.super.draw(self)
end

function Spell_Arrow:die()
  Spell_Arrow.super.die(self)
end
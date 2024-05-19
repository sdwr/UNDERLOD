

Spell_Arrow = Spell:extend()
function Spell_Arrow:init(args)
  Spell_Arrow.super.init(self, args)
end

function Spell_Arrow:draw()
  Spell_Arrow.super.draw(self)
end

function Spell_Arrow:update(dt)
  Spell_Arrow.super.update(self, dt)
end

function Spell_Arrow:die()
  Spell_Arrow.super.die(self)
end
PreventCasting_Spell = Spell:extend()
function PreventCasting_Spell:init(args)
  PreventCasting_Spell.super.init(self, args)
    
    self.color = self.color or yellow[0]
    self.aim_color = self.aim_color or yellow[0]
    self.color_transparent = self.color:clone()
    self.color_transparent.a = 0.3

    self.duration = self.duration or 3  -- Duration in seconds

    self:start_cast()
end

function PreventCasting_Spell:start_cast()
    
  -- Set the new state that allows movement but prevents casting
  self.unit.state = unit_states['casting_blocked']
  

  -- Set timer to return to normal state
  self.unit.t:after(self.duration, function()
      if self.unit.state == unit_states['casting_blocked'] then
          self.unit.state = unit_states['normal']
      end
  end)
end
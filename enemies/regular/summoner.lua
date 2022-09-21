Summoner = Object:extend()
Summoner:implement(GameObject)
Summoner:implement(Physics)
Summoner:implement(Unit)
Summoner:implement(Enemy)
function Summoner:init(args)
    self:init_game_object(args)
    self:init_unit()

    self:create_unit()
    self:calculate_stats(true)

    self:set_attacks()
end

function Summoner:create_unit()
    self:set_as_rectangle(14, 6, 'dynamic', 'enemy')
    self:set_restitution(0.5)
    self.color = purple[0]:clone()
    self:set_as_steerable(self.v, 2000, 4*math.pi, 4)
    self.class = 'summoner'
end

function Summoner:set_attacks()
    self.summons = 0
    self.t:cooldown(attack_speeds['slow'], function() return self.state == 'normal' and self.summons < 4 end, function()
      self:summon()
    end, nil, nil, 'cast')
end

function Summoner:summon()
    Summon{group = main.current.main, team = "enemy", x = self.x, y = self.y, rs = 25, color = purple[0], level = self.level, parent = self}
  end

function Summoner:draw()
    graphics.rectangle(self.x, self.y, self.shape.w, self.shape.h, 3, 3, self.hfx.hit.f and fg[0] or (self.silenced and bg[10]) or self.color)
end

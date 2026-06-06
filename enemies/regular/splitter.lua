-- Splitter: a melee approacher with no attacks of its own. On death it
-- bursts into 3 swarmers that fan out from its position. Forces the player
-- to choose between killing it cleanly (and dealing with the splits) or
-- ignoring it (and getting tagged by the body). Coded after brute.lua for
-- the walker shell, with a death hook in the bomb.lua style for the burst.

local fns = {}

fns['init_enemy'] = function(self)
  self.data = self.data or {}
  self.icon = 'rat1'

  self.color = green[0]:clone()
  Set_Enemy_Shape(self, self.size)

  self.stopChasingInRange = false
  self.haltOnPlayerContact = true

  self.class = 'special_enemy'
  self.baseIdleTimer = 0

  self.attack_sensor = Circle(self.x, self.y, 500)
  self.move_option_weight = 0.4

  -- No attacks; the threat is the body and the death burst.
  self.attack_options = {}

  self.split_count = self.split_count or 3

  self.state_change_functions['death'] = function(self)
    if self.already_split then return end
    self.already_split = true
    -- Stagger the spawns by a hair so they don't all share one frame's
    -- physics tick (which can wedge them inside each other).
    for i = 1, self.split_count do
      local angle = (i - 1) * (2 * math.pi / self.split_count) + random:float(-0.3, 0.3)
      local ox, oy = math.cos(angle) * 10, math.sin(angle) * 10
      self.t:after(0.02 * i, function()
        Enemy{
          type = 'swarmer',
          group = main.current.main,
          x = self.x + ox,
          y = self.y + oy,
          path_heading = angle,
          level = self.level,
          data = {},
        }
      end)
    end
  end
end

fns['draw_enemy'] = function(self)
  local animation_success = self:draw_animation()
  if not animation_success then
    self:draw_fallback_animation()
  end
end

enemy_to_class['splitter'] = fns

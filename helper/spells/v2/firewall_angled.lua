-- ====================================================================
-- EnemyFirewallSpell
-- This is a simple, instantaneous spell that an enemy unit can cast.
-- Its only purpose is to create the EnemyFirewall projectile.
-- ====================================================================
EnemyFirewallSpell = Spell:extend()
function EnemyFirewallSpell:init(args)
    EnemyFirewallSpell.super.init(self, args)
    
    local caster = self.unit
    if not caster then 
        self:die()
        return 
    end

    -- Create the projectile object
    EnemyFirewall {
        group = main.current.effects,
        x = caster.x,
        y = caster.y,
        r = caster:get_angle(), -- Set the firewall's angle to the caster's angle
        unit = caster,          -- The caster, for team checking and damage attribution
        damage = get_dmg_value(self.damage),
        spell_duration = self.spell_duration or 5,
        knockback_force = self.knockback_force or 90,
        travel_distance = self.travel_distance or 450,
        width = self.width or 60,
        thickness = self.thickness or 16
    }
    
    -- The "spell" itself is done after launching the projectile.
    self:die()
end

function EnemyFirewallSpell:update(dt)
    EnemyFirewallSpell.super.update(self, dt)
end

function EnemyFirewallSpell:draw()
    EnemyFirewallSpell.super.draw(self)
end

function EnemyFirewallSpell:die()
    EnemyFirewallSpell.super.die(self)
end

-- ====================================================================
-- EnemyFirewall (The Projectile)
-- Adapted from your original FireWall code. This is the moving wall
-- of fire that damages and knocks back units.
-- REFACTORED to use manual point-in-polygon collision detection.
-- ====================================================================
EnemyFirewall = Object:extend()
EnemyFirewall:implement(GameObject)
EnemyFirewall:implement(Physics)
function EnemyFirewall:init(args)
    self:init_game_object(args)
    
    fire1:play{volume = 0.7, pitch = random:float(0.9, 1.1)}
    self.color = red[0]:clone()
    self.color.a = 0.7
    
    self.damage = get_dmg_value(self.damage)
    self.knockback_force = self.knockback_force or 12000
    self.spell_duration = self.spell_duration or 5
    self.current_duration = 0
    
    -- Movement logic
    self.speed = 80
    self.angle = self.r or 0
    self.vx = math.cos(self.angle) * self.speed
    self.vy = math.sin(self.angle) * self.speed
    
    -- Lifetime logic
    self.distance_traveled = 0

    -- Define the dimensions of the firewall
    self.w = self.width or 60
    self.h = self.thickness or 16
    
    -- FIX: Initialize corners as an empty array to hold point tables
    self.corners = {}
    
    -- Keep track of units we've already hit to prevent multi-hits
    self.hit_units = {}

    
    self.particle_interval = 0.1
    self.particle_elapsed = 0

    self.shader = love.graphics.newShader("helper/spells/v2/shaders/firewall.frag")
    self.flash_amount = 0
    self.flash_duration = 0.2
    self.flash_timer = 0

end

-- This function calculates the world coordinates of the firewall's 4 corners
function EnemyFirewall:update_corners()
    -- Clear the old corner data
    self.corners = {}
    
    local x, y = self.x, self.y
    local render_angle = self.angle + math.pi / 2
    local w, h = self.w / 2, self.h / 2

    -- Get the unrotated corners relative to the center
    local corner_offsets = {
        {-w, -h}, {w, -h}, {w, h}, {-w, h}
    }

    -- Rotate each corner around the center and translate to world position
    for i, offset in ipairs(corner_offsets) do
        local rotated_x = offset[1] * math.cos(render_angle) - offset[2] * math.sin(render_angle)
        local rotated_y = offset[1] * math.sin(render_angle) + offset[2] * math.cos(render_angle)
        -- FIX: Insert a point table {x=..., y=...} into the corners array
        table.insert(self.corners, {x = x + rotated_x, y = y + rotated_y})
    end
end

function EnemyFirewall:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    self:update_corners()
    self:add_particles()
    
    self.current_duration = self.current_duration + dt
    if self.current_duration >= self.spell_duration then
        self:die()
        return
    end

    self.particle_elapsed = self.particle_elapsed + dt

      -- Update the flash timer
  if self.flash_timer > 0 then
    self.flash_timer = self.flash_timer - dt
    -- Create a fade-out effect for the flash
    self.flash_amount = self.flash_timer / self.flash_duration
  else
      self.flash_amount = 0
  end
  
    self.shader:send("time", self.current_duration)
    self.shader:send("flash_amount", self.flash_amount)

    self:check_collisions()
    
end

function EnemyFirewall:add_particles()
    if self.particle_elapsed > self.particle_interval then
      self.particle_elapsed = 0
      for i = 1, 5 do
        local x = self.x + random:float(-self.w/2, self.w/2)
        local y = self.y + random:float(-self.h/2, self.h/2)
        HitParticle{group = main.current.effects, 
          x = x, y = y, 
          color = self.color,
          v = random:float(30, 60)
        }
      end
    end
  end

-- Checks for collisions using manual point-in-polygon logic
function EnemyFirewall:check_collisions()
    local units_to_check = Helper.Unit:get_list(true) 
    for _, unit in ipairs(units_to_check) do
        if not table.contains(self.hit_units, unit) then
            for i, point in ipairs(unit.points) do
                local point_x = unit.x + point.x
                local point_y = unit.y + point.y
                
                if Helper.Geometry:is_point_in_polygon(point_x, point_y, self.corners) then
                    self:flash()
                    self:on_hit(unit)
                    break 
                end
            end
        end
    end
end

-- Add this new function to the FireSegment object
function EnemyFirewall:flash()
    -- This resets the flash timer, which is then handled in update()
    self.flash_timer = self.flash_duration
end

-- This function is called when a collision is detected
function EnemyFirewall:on_hit(unit)
    if self.debug_collisions then
        print(string.format("--- FIREWALL HIT DETECTED on Unit ID %s ---", tostring(unit.id)))
    end

    table.insert(self.hit_units, unit)
    
    unit:hit(self.damage, self.unit)
    
    player_hit1:play{pitch = random:float(0.95, 1.05), volume = 1.2}
    
    local push_angle = self.angle
    local knockback_duration = KNOCKBACK_DURATION_ENEMY
    
    unit:push(self.knockback_force, push_angle, nil, knockback_duration)
end

function EnemyFirewall:draw()
    -- Set the shader
    love.graphics.setShader(self.shader)

    -- Draw the main firewall visual
    -- The shader will transform this simple rectangle
    graphics.push(self.x, self.y, self.angle + math.pi / 2)
        graphics.rectangle(self.x, self.y, self.w, self.h, 3, 3, self.color)
    graphics.pop()

    -- Unset the shader so it doesn't affect other objects
    love.graphics.setShader()

end

function EnemyFirewall:die()
    self.dead = true
end

-- ====================================================================
-- Firewall Caster Enemy Definition
-- This enemy is based on the 'laser' enemy template but has been
-- adapted to cast the EnemyFirewallSpell.
-- ====================================================================

local fns = {}

-- Initialization function for the Firewall Caster
fns['init_enemy'] = function(self)
    -- Set extra variables from data
    self.data = self.data or {}

    -- Create shape and set a fire-themed color
    self.color = red[0]:clone()
    Set_Enemy_Shape(self, self.size)

    self.class = 'special_enemy'
    self.icon = 'dragon'
  

    -- Set stats and cooldowns
      -- Attack speed now handled by base class

    -- This enemy will stop to cast and will be locked facing its cast direction.
    self.direction_lock = false
    self.rotation_lock = true

    -- ===================================================================
    -- ATTACK DEFINITION
    -- ===================================================================
    self.attack_options = {}

    local firewall_attack = {
        name = 'firewall_caster',
        
        -- The attack is viable if there is any friendly unit within its large aggro sensor range.
        viable = function() 
            return Helper.Target:get_random_enemy(self) 
        end,

        -- oncast is not needed because the spell fires instantly at the caster's angle.

        oncast = function() end,

    
        hide_cast_timer = false,

        -- Use the EnemyFirewallSpell class we defined previously.
        spellclass = EnemyFirewallSpell,
        instantspell = true,
        -- This data table passes properties to the EnemyFirewallSpell, which then
        -- passes them to the EnemyFirewall projectile.
        spelldata = {
            group = main.current.effects,
            unit = self,
            damage = function() return self.dmg end, -- Use the damage value from the enemy unit itself
            spell_duration = 5,
            -- Customize the firewall projectile's properties here
            travel_distance = 400,
            speed = 40,
            width = 50,
            thickness = 10,
        },
    }

    table.insert(self.attack_options, firewall_attack)
end

-- Draw function for the Firewall Caster
fns['draw_enemy'] = function(self)    
    local animation_success = self:draw_animation()
    
    if not animation_success then
        self:draw_fallback_animation()
    end

end

-- Add this new enemy type to the global enemy class table
enemy_to_class['firewall_caster'] = fns

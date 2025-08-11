Helper.Damage = {}

-- ===================================================================
-- THREE HIT TYPES FOR THE NEW DAMAGE SYSTEM
-- ===================================================================

-- ===================================================================
-- PRIMARY HIT
-- Direct attacks that can trigger full onHit effects including chains and criticals
-- ===================================================================
function Helper.Damage:primary_hit(unit, damage, from, damageType, playHitEffects)
  
  -- Primary hits can trigger full onHit effects
  -- TODO: Add critical hit check here before applying damage
  -- TODO: Add chain attack potential here
  
  -- Early returns for invalid states
  if unit.invulnerable then return end
  if unit.dead then return end
  if unit.offscreen then return end
  
  -- Default parameters
  playHitEffects = playHitEffects or true

  --only direct attacks can crit
  damage = Helper.Damage:roll_crit(from, damage)

  local stun = Helper.Damage:roll_stun(from)
  if stun then
    unit:stun()
  end
  
  -- Trigger onPrimaryHit callbacks right before processing the hit
  if from and from.onPrimaryHitCallbacks then
    from:onPrimaryHitCallbacks(unit, damage, damageType)
  end

  -- Helper.Damage:apply_knockback(unit, from)
  
  -- Unit-specific pre-hit processing
  if not Helper.Damage:process_pre_hit(unit, damage, from, damageType, playHitEffects) then
    return
  end
  
  -- Calculate final damage
  local actual_damage = Helper.Damage:calculate_final_damage(unit, damage, damageType)
  
  -- TODO: Apply critical hit multiplier here if critical
  -- TODO: Apply chain attack effects here

  --Elemental or physical
  if table.contains({DAMAGE_TYPE_FIRE, DAMAGE_TYPE_LIGHTNING, DAMAGE_TYPE_COLD}, damageType) then
    Helper.Damage:apply_elemental_effects(unit, actual_damage, damageType, from)
  else
    Helper.Damage:deal_damage(unit, actual_damage)
  end

  --Enemy specific: elemental damage reactions
  if unit.isEnemy then
    Helper.Damage:process_elemental_reactions(unit, actual_damage, damageType, from)
  end
  
  -- Unit-specific post-damage processing
  Helper.Damage:process_post_damage(unit, actual_damage, damageType, from)
  
  -- Track damage for teams
  Helper.Damage:track_team_damage(from, actual_damage)
  
  -- Handle callbacks with full onHit effects
  Helper.Damage:process_callbacks(unit, from, actual_damage, damageType, false)
  
  -- Handle death
  if unit.hp <= 0 then
    Helper.Damage:handle_death(unit, from, actual_damage)
  end
end

-- ===================================================================
-- INDIRECT HIT
-- Area effects, explosions, environmental damage that can't chain
-- ===================================================================
function Helper.Damage:indirect_hit(unit, damage, from, damageType, playHitEffects)
  
  -- Indirect hits have limited onHit effects (no chain effects, no critical hits)
  -- This is the current apply_hit function renamed
  
  -- Early returns for invalid states
  if unit.invulnerable then return end
  if unit.dead then return end
  if unit.offscreen then return end
  
  -- Default parameters
  playHitEffects = playHitEffects or true

  --see if we need to add additional elemental modifiers

  
  -- Unit-specific pre-hit processing
  if not Helper.Damage:process_pre_hit(unit, damage, from, damageType, playHitEffects) then
    return
  end
  
  -- Calculate final damage
  local actual_damage = Helper.Damage:calculate_final_damage(unit, damage, damageType)
  
  -- Apply damage
  Helper.Damage:deal_damage(unit, actual_damage)
  
  -- Unit-specific post-damage processing
  Helper.Damage:process_post_damage(unit, actual_damage, damageType, from)

  --Enemy specific: elemental damage reactions
  if unit.isEnemy then
    Helper.Damage:process_elemental_reactions(unit, actual_damage, damageType, from)
  end
  
  -- Track damage for teams
  Helper.Damage:track_team_damage(from, actual_damage)
  
  -- Handle callbacks with limited onHit effects
  Helper.Damage:process_callbacks(unit, from, actual_damage, damageType, false)
  
  -- Handle death
  if unit.hp <= 0 then
    Helper.Damage:handle_death(unit, from, actual_damage)
  end
end

-- ===================================================================
-- CHAINED HIT
-- Elemental damage, chain lightning, or any effect that originates from a primary hit
-- ===================================================================
function Helper.Damage:chained_hit(unit, damage, from, damageType, playHitEffects)
  -- Chained hits cannot trigger onHit effects (prevents infinite loops)
  
  -- Early returns for invalid states
  if unit.invulnerable then return end
  if unit.dead then return end
  if unit.offscreen then return end
  
  -- Default parameters
  playHitEffects = playHitEffects or true
  
  -- Unit-specific pre-hit processing
  if not Helper.Damage:process_pre_hit(unit, damage, from, damageType, playHitEffects) then
    return
  end
  
  -- Calculate final damage
  local actual_damage = Helper.Damage:calculate_final_damage(unit, damage, damageType)
  
  -- Apply damage
  Helper.Damage:deal_damage_chained(unit, actual_damage)
  
  -- Unit-specific post-damage processing
  Helper.Damage:process_post_damage(unit, actual_damage, damageType, from)
  
  -- Track damage for teams
  Helper.Damage:track_team_damage(from, actual_damage)
  
  -- Handle callbacks with NO onHit effects (prevents infinite loops)
  Helper.Damage:process_callbacks(unit, from, actual_damage, damageType, true)
  
  -- Handle death
  if unit.hp <= 0 then
    Helper.Damage:handle_death(unit, from, actual_damage)
  end
end 

function Helper.Damage:apply_knockback(unit, from)
  if unit and from then
    --dont knockback special enemies or bosses
    if unit.class == 'special_enemy' or unit.class == 'boss' then
      return
    end
    
    local duration = KNOCKBACK_DURATION_TROOP_ATTACK
    local push_force = LAUNCH_PUSH_FORCE_TROOP_ATTACK
    unit:push(push_force, unit:angle_to_object(from) + math.pi, nil, duration)
  end
end

function Helper.Damage:deal_damage(unit, damage)
  unit.hp = unit.hp - damage

  if unit.buffs['curse'] then
    unit.buffs['curse'].damage_taken = unit.buffs['curse'].damage_taken + damage
  end

  --only for non-chained hits, to prevent an infinite loop
  if unit.buffs['curse'] and unit.buffs['curse'].from then
    local curse_from = unit.buffs['curse'].from
    if Has_Static_Proc(curse_from, 'curseDamageLink') then
      --deal damage to some nearby cursed units
      local attack_sensor = Circle(unit.x, unit.y, CURSE_DAMAGE_LINK_RADIUS)
      local units_to_hit = unit:get_cursed_targets(attack_sensor, enemy_classes)

      local damage_to_deal = (damage * CURSE_DAMAGE_LINK_DAMAGE_PERCENT) / #units_to_hit

      for _, unit_to_hit in ipairs(units_to_hit) do
        ChainSpell{
          group = main.current.main,
          parent = curse_from,
          source = unit,
          target = unit_to_hit,
          max_chains = 1,
          range = 0,
          delay = 0,
          visual_duration = 0.2,
          is_troop = curse_from and curse_from.is_troop,
          skip_first_bounce = false,
          on_hit = function(spell, target)
            Helper.Damage:chained_hit(target, damage_to_deal, spell.caster, DAMAGE_TYPE_PHYSICAL, false)
          end,
          on_bounce = function(spell, from_target, to_target)
            wizard1:play{pitch = random:float(0.9, 1.1), volume = 0.2}
            -- The CurseLine effect is a separate, temporary object.
            CurseLine{
              group = main.current.effects,
              src = from_target,
              dst = to_target,
              w = 1,
              primary_color = purple[0],
              secondary_color = purple[-3],
              duration = 0.2
            }        end
          }
      end

    end
  end
end

function Helper.Damage:deal_damage_chained(unit, damage)
  unit.hp = unit.hp - damage

  if unit.buffs['curse'] then
    unit.buffs['curse'].damage_taken = unit.buffs['curse'].damage_taken + damage
  end
end

-- ===================================================================
-- PRE-HIT PROCESSING
-- Handles unit-specific logic that happens before damage is applied
-- ===================================================================
function Helper.Damage:process_pre_hit(unit, damage, from, damageType, playHitEffects)
  -- Player troop specific: bubble protection
  if unit.bubbled then return false end
  
  -- Player troop specific: shield absorption
  if unit.isShielded and unit.isShielded and unit:isShielded() then
    if unit.shielded > damage then 
      unit.shielded = unit.shielded - damage
      damage = 0
    else
      damage = damage - unit.shielded
      unit:remove_shield()
      unit:shield_explode()
    end
  end
  
  -- Enemy specific: push invulnerability
  if unit.push_invulnerable then return false end
  
  -- Apply hit effects and sounds
  Helper.Damage:apply_hit_effects(unit, damage, playHitEffects)
  
  return true
end

-- ===================================================================
-- HIT EFFECTS AND SOUNDS
-- Handles visual and audio effects when a unit is hit
-- ===================================================================
function Helper.Damage:apply_hit_effects(unit, damage, playHitEffects)
  
  -- Calculate hit strength for visual effects
  local hitStrength = (damage * 1.0) / unit.max_hp
  hitStrength = math.min(hitStrength, 0.5)
  hitStrength = math.remap(hitStrength, 0, 0.5, 1, 1.4)
  
  -- Apply hit flash effect
  if playHitEffects then
    if unit.isBoss then
      unit.hfx:use('hit', 0.01, 200, 20, 0.1)
    else
      unit.hfx:use('hit', 0.03 * hitStrength, 200, 10, 0.1)
    end

    -- Only create HitCircle for non-animated enemies (those without spritesheets)
    if not unit.spritesheet then
      HitCircle{group = main.current.effects, x = unit.x, y = unit.y}:scale_down(0.3):change_color(0.5, unit.color)
    end
    
    -- Player troop specific: camera shake
    if unit.is_troop then
      camera:shake(1, 0.5)
    end
  end
end

function Helper.Damage:roll_crit(from, damage)
  if not from then return damage end
  
  if from.crit_chance then
    if random:float(0, 1) < from.crit_chance then
      return damage * (from.crit_mult or BASE_CRIT_MULT)
    end
  end
  return damage
end

function Helper.Damage:roll_stun(from)
  if not from then return false end
  if from.stun_chance then
    if random:float(0, 1) < from.stun_chance then
      return true
    end
  end
end

-- ===================================================================
-- DAMAGE CALCULATION
-- Handles unit-specific damage calculation logic
-- ===================================================================
function Helper.Damage:calculate_final_damage(unit, damage, damageType)
  local final_damage = damage
  
  -- Apply unit-specific damage calculation
  if unit.calculate_damage then
    final_damage = unit:calculate_damage(damage)
  end
  
  -- Ensure damage is non-negative
  return math.max(final_damage, 0)
end

-- ===================================================================
-- POST-DAMAGE PROCESSING
-- Handles effects that happen after damage is calculated but before callbacks
-- ===================================================================
function Helper.Damage:process_post_damage(unit, actual_damage, damageType, from)
  -- Show damage number
  unit:show_damage_number(actual_damage, damageType)
  
  -- Update global damage tracking
  if unit.isEnemy then
    main.current.damage_dealt = main.current.damage_dealt + actual_damage
  end
end

-- ===================================================================
-- ELEMENTAL DAMAGE REACTIONS
-- Enemy-specific elemental damage handling
-- ===================================================================

function Helper.Damage:apply_elemental_effects(unit, actual_damage, damageType, from)
  if not from then return end

  if damageType == DAMAGE_TYPE_FIRE then
    unit:burn(actual_damage, from)
  end

  if damageType == DAMAGE_TYPE_LIGHTNING then
    unit:shock()
  end

  if damageType == DAMAGE_TYPE_COLD then
    unit:chill(actual_damage, from)
  end
end


function Helper.Damage:process_elemental_reactions(unit, actual_damage, damageType, from)
  if not from or not from.get_elemental_damage_multis then return end


  local elemental_damage_stats = from:get_elemental_damage_stats(damageType)

  if elemental_damage_stats[DAMAGE_TYPE_FIRE] > 0 then
    local fire_damage = actual_damage * elemental_damage_stats[DAMAGE_TYPE_FIRE]
    Helper.Damage:chained_hit(unit, fire_damage, from, DAMAGE_TYPE_FIRE, false)
  end

  if elemental_damage_stats[DAMAGE_TYPE_LIGHTNING] > 0 then
    local lightning_damage = actual_damage * elemental_damage_stats[DAMAGE_TYPE_LIGHTNING]
    ChainLightning{
      group = main.current.main, 
      target = unit, range = 50, 
      damage = lightning_damage, 
      damage_type = DAMAGE_TYPE_LIGHTNING,
      color = yellow[0], 
      parent = from,
      is_troop = from and from.is_troop,
    }
  end

  if elemental_damage_stats[DAMAGE_TYPE_COLD] > 0 then
    local cold_damage = actual_damage * elemental_damage_stats[DAMAGE_TYPE_COLD]
    Helper.Damage:chained_hit(unit, cold_damage, from, DAMAGE_TYPE_COLD, false)
  end
end

-- ===================================================================
-- TEAM DAMAGE TRACKING
-- Tracks damage and kills for team statistics
-- ===================================================================
function Helper.Damage:track_team_damage(from, actual_damage)
  if from and from.team then
    local attacker_team = Helper.Unit.teams[from.team]
    if attacker_team then
      attacker_team:record_damage(actual_damage)
    end
  end
end

-- ===================================================================
-- CALLBACK PROCESSING
-- Handles onHit and onGotHit callbacks
-- ===================================================================
function Helper.Damage:process_callbacks(unit, from, actual_damage, damageType, cannotProcOnHit)
  -- OnHit callbacks (from attacker)
  if from and from.onHitCallbacks and not cannotProcOnHit then
    from:onHitCallbacks(unit, actual_damage, damageType)
  end
  
  -- OnGotHit callbacks (on the hit unit)
  unit:onGotHitCallbacks(from, actual_damage, damageType)
end

-- ===================================================================
-- DEATH HANDLING
-- Handles unit death and related effects
-- ===================================================================
function Helper.Damage:handle_death(unit, from, actual_damage)

  -- OnDeath callbacks
  unit:onDeathCallbacks(from)

  if unit.isEnemy then
    unit:die()
  end
  
  -- OnKill callbacks
  if from and from.onKillCallbacks then
    local overkill = -unit.hp
    from:onKillCallbacks(unit, overkill)
  end
  
  -- Track kill for teams
  if from and from.team then
    local attacker_team = Helper.Unit.teams[from.team]
    if attacker_team then
      attacker_team:record_kill()
    end
  end
  
  -- Unit-specific death effects
  Helper.Damage:apply_death_effects(unit, from)
  
  -- Call die() for non-enemy units
  if not unit.isEnemy then
    unit:die()
  end
end

-- ===================================================================
-- DEATH EFFECTS
-- Handles unit-specific death effects and animations
-- ===================================================================
function Helper.Damage:apply_death_effects(unit, from)
  if unit.is_troop then
    -- Player troop death effects
    hit4:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    
    for i = 1, random:int(4, 6) do 
      HitParticle{group = main.current.effects, x = unit.x, y = unit.y, color = unit.color} 
    end
    HitCircle{group = main.current.effects, x = unit.x, y = unit.y, rs = 12}:scale_down(0.3):change_color(0.5, unit.color)
    
    -- Create death animation
    slow(0.25, 1)
    TroopDeathAnimation{group = main.current.effects, x = unit.x, y = unit.y}
    
    -- Clean up dot area
    if unit.dot_area then 
      unit.dot_area.dead = true
      unit.dot_area = nil 
    end
    
  elseif unit.isEnemy then
    -- Enemy death effects
    for i = 1, random:int(2, 3) do 
      HitParticle{group = main.current.effects, x = unit.x, y = unit.y, color = unit.color} 
    end
    HitCircle{group = main.current.effects, x = unit.x, y = unit.y, rs = 12}:scale_down(0.3):change_color(0.5, unit.color)
    
    if unit.isBoss then
      slow(0.25, 1)
      magic_die1:play{pitch = random:float(0.95, 1.05), volume = 0.5}
    else
      _G[random:table{'enemy_die1', 'enemy_die2'}]:play{pitch = random:float(0.9, 1.1), volume = 0.5}
    end
  end
end
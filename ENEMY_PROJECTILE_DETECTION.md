# Enemy Projectile Hit Detection Catalog

## Current Hit Detection Methods

### 1. Manual Detection with `get_objects_in_shape()`
Most enemy projectiles use manual hit detection by checking for collisions each frame:

#### Examples:
- **PlasmaBall** (`plasma_barrage.lua`)
  - Checks: `main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)`
  - Action: Explodes on contact with any friendly
  
- **SnakeArrow** (`snake_arrow.lua`)
  - Checks: `main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)`
  - Action: Deals damage and dies on contact
  
- **Boomerang** (`instants.lua`)
  - Checks: `main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)`
  - Maintains `already_damaged` list to avoid double hits
  
- **Burst/BurstBullet** (`instants.lua`)
  - Checks: `main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)`
  - Action: Explodes on contact
  
- **Area_Spell** (`area_spell.lua`)
  - Used by many AOE attacks (explosions, stomp, cleave)
  - Checks: `main.current.main:get_objects_in_shape(self.shape, main.current.friendlies)`
  - Can be single-hit or damage-over-time

### 2. Trigger-based Detection with `on_trigger_enter()`
Only a few projectiles use trigger-based detection:

#### Examples:
- **ArrowProjectile** (`instants.lua`)
  - Uses: `on_trigger_enter(other)`
  - Checks: `other:is(Troop) and not self.is_troop`
  - Note: This is the only enemy projectile using triggers

### 3. Special Cases
- **Laser_Spell** (`laser_spell.lua`)
  - No direct collision detection in the spell itself
  - Likely creates Area_Spell objects for damage
  
- **Mortar** (`mortar.lua`)
  - Creates Area_Spell on impact for explosion damage

## Current Problems

1. **Inconsistent Detection Methods**
   - Most use manual `get_objects_in_shape()`
   - Only ArrowProjectile uses triggers
   - No standardized approach

2. **Direct Troop Targeting**
   - All projectiles check for `main.current.friendlies` which includes troops
   - Troops are invisible and positioned at orb center
   - This causes confusion about what's actually being hit

3. **No PlayerCursor Integration**
   - PlayerCursor is not consistently checked
   - Damage redirection to orb happens at the troop level, not projectile level

## Proposed Clean Architecture

### Solution: Centralize Hit Detection Through PlayerCursor

1. **Remove Troop from Friendlies Detection**
   - Troops should not be in the collision detection list
   - Only PlayerCursor should be detectable

2. **Standardize on Manual Detection**
   - All enemy projectiles use `check_hits()` method
   - Check only for PlayerCursor, not all friendlies
   
3. **PlayerCursor Handles All Redirects**
   ```lua
   function EnemyProjectile:check_hits()
     local cursor = main.current.current_arena.player_cursor
     if cursor and not cursor.dead then
       if self.shape:collides_with_circle(cursor.x, cursor.y, cursor.cursor_radius) then
         cursor:hit(self.damage, self.unit, self.damage_type)
         self:on_hit_cursor()
       end
     end
   end
   ```

4. **PlayerCursor Invulnerability Period**
   ```lua
   function PlayerCursor:hit(damage, from, damageType)
     if self.invuln_timer and self.invuln_timer > 0 then
       return -- Ignore damage during invuln
     end
     
     -- Redirect to orb
     if self.orb and not self.orb.dead then
       self.orb:hit(damage, from, damageType)
       
       -- Start invuln period
       self.invuln_timer = 0.5 -- 0.5 second invulnerability
       
       -- Visual feedback
       self:flash_invuln()
     end
   end
   ```

## Enemy Attacks That Need Updates

### High Priority (Direct projectiles)
- PlasmaBall
- SnakeArrow
- Burst/BurstBullet
- Boomerang
- ArrowProjectile
- HomingMissile

### Medium Priority (Area attacks)
- Area_Spell (used by many attacks)
- Mortar explosions
- Stomp areas
- Cleave areas

### Low Priority (Special attacks)
- Laser_Spell (may need different handling)
- Firewall
- Chain attacks

## Implementation Steps

1. **Phase 1**: Update PlayerCursor
   - Add invulnerability timer
   - Add visual feedback for invuln state
   - Ensure proper damage redirection

2. **Phase 2**: Update Enemy Projectiles
   - Replace `main.current.friendlies` checks with PlayerCursor checks
   - Standardize all to use `check_hits()` method
   - Remove trigger-based detection from ArrowProjectile

3. **Phase 3**: Remove Troops from Detection
   - Ensure troops are never added to collision detection groups
   - Verify troops remain invisible and non-collidable

4. **Phase 4**: Testing
   - Test all enemy types
   - Verify damage redirection works
   - Ensure invulnerability period feels good
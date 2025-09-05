# UNDERLOD Debug Commands and Features

This document lists all debug commands, flags, and keyboard shortcuts available in UNDERLOD for development and testing.

## Keyboard Shortcuts

### Window and Display Controls
- **K** - Decrease window scale by 0.5 (minimum scale: 1)
- **L** - Increase window scale by 0.5

### Camera Controls (WorldManager)
- **X** - Move camera right by 100 pixels
- **Z** - Move camera left by 100 pixels

### Debug Toggle Keys
- **F5** - Toggle `DEBUG_ENEMY_SEEK_TO_RANGE`
  - Shows debug visualization for enemy seek-to-range behavior
  - Displays ovals/circles showing target ranges and movement paths
  
- **F6** - Toggle `DEBUG_STEERING_VECTORS`
  - Shows steering behavior vectors for enemies
  - Works with `DEBUG_STEERING_ENEMY_TYPE` to filter specific enemy types
  
- **F7** - Toggle `DEBUG_DISTANCE_MULTI`
  - Shows distance multiplier debugging information
  
- **F8** - Toggle `DEBUG_PLAYER_TROOPS`
  - Debug mode for player troops
  - Uses `DEBUG_PLAYER_CHARACTER_TYPE` (default: 'archer')

### Achievement and Testing
- **F10** - Unlock 'heatingup' achievement (for testing)
- **F11** - Reset all achievements and stats

## Debug Flags (game_constants.lua)

All debug flags are defined in `game_constants.lua` and default to `false`:

```lua
DEBUG_PROCS = false              -- Show proc debugging info
DEBUG_SPELLS = false             -- Show spell debugging info
DEBUG_ENEMY_SEEK_TO_RANGE = false -- Visualize enemy seek-to-range behavior
DEBUG_STEERING_VECTORS = false    -- Show enemy steering vectors
DEBUG_STEERING_ENEMY_TYPE = nil  -- Filter steering debug to specific enemy type
DEBUG_PLAYER_TROOPS = false      -- Enable player troop debugging
DEBUG_PLAYER_CHARACTER_TYPE = 'archer' -- Default character for debug troops
DEBUG_DISTANCE_MULTI = false     -- Debug distance multipliers
```

## Additional Debug Features

### Enemy Movement Debug
- `DEBUG_ENEMY_MOVEMENT` - Shows enemy movement debug info (referenced in enemy.lua:602)
- When enabled, calls `Enemy:draw_debug_info()` and `Enemy:draw_steering_debug()`

### Debug Visualization Objects
The codebase includes special debug visualization objects in `miscellaneous_objects.lua`:
- **DebugCircle** - Draws temporary debug circles with customizable color and duration
- **DebugOval** - Draws temporary debug ovals/ellipses for visualizing non-circular ranges
- **DebugLine** - Draws temporary debug lines between points

### Proc System Debug
When `DEBUG_PROCS = true`, detailed logging is shown for:
- Proc activation
- Proc callbacks (onAttack, onHit, onTick, etc.)
- Proc cooldowns and timing

### Spell System Debug
When `DEBUG_SPELLS = true`, shows:
- Spell creation and initialization
- Spell targeting and collision
- Spell damage calculations

## VSCode Debugging
The game supports VSCode Lua debugging:
```lua
if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  -- Debugger integration enabled
end
```

## Usage Tips

1. **Toggle Multiple Debug Modes**: You can enable multiple debug flags simultaneously for comprehensive debugging
2. **Performance Impact**: Some debug visualizations (especially steering vectors) may impact performance
3. **Persistent Settings**: Window scale and volume settings are saved to state
4. **Console Output**: Most debug toggles print their status to console when changed

## Common Debug Workflows

### Debugging Enemy AI
1. Press F5 to enable seek-to-range visualization
2. Press F6 to show steering vectors
3. Set `DEBUG_STEERING_ENEMY_TYPE` in code to filter to specific enemy

### Testing Combat Balance
1. Press F8 to enable player troop debugging
2. Modify `DEBUG_PLAYER_CHARACTER_TYPE` to test different units
3. Enable `DEBUG_PROCS` and `DEBUG_SPELLS` to see combat details

### Window Testing
1. Use K/L to test different window scales
2. Use X/Z to test camera movement (in WorldManager state)

## Notes
- Debug features are primarily for development and should be disabled in production builds
- Some debug features may require code modifications to fully utilize (e.g., setting enemy type filters)
- Console output provides additional context when debug modes are toggled
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UNDERLOD is an arcade RTS roguelite built with LÖVE2D (Love2D game engine) in Lua. Players control units with optimizable builds to achieve victory through combat encounters.

## Code Conventions

## Comments
- keep comments minimal

## Drawing Rules
- graphics.push(x, y) sets the origin point for rotation and scaling effects only
- It does not move the coordinate system. You must still provide the object's full x and y coordinates in all subsequent draw calls (e.g., graphics.rectangle(self.x, self.y, ...))
- Never use graphics.setColor()
- Always pass the color object directly into the draw command. For example: graphics.circle(x, y, radius, some_color)

## Color System
- The project uses global color tables, like red, blue, and green
- Access different shades using an index from -10 (darkest) to 10 (lightest), for example: red[5], blue[-2]
- These are color objects with .r, .g, .b, and .a properties, and should be cloned with :clone() when modified

## GameObjects
- If a GameObject is assigned to a Group, you do not need to manually call its :update() or :draw() methods. The Group handles this automatically
- To properly destroy a GameObject, you must set its .dead property to true (my_object.dead = true), then it will be destroyed by the Group
- Crucially, you must also remove all external references to the object so it can be garbage collected
- This is especially important for UI elements to prevent them from getting stuck on screen permanently.

## Units
- when referencing a passed-in unit, check if it exists and is not dead, passed-in units are frequently nil or dead

## Game Systems
- the `Arena` main `Group` is where all units and objects with physics live
- the world_ui `Group` is for global UI, the `Arena` ui `Group` is for level-specific UI
- use get_objects_in_shape() with main.current.friendlies and main.current.enemies to find units for manual hit detection

### Core Structure
- **Engine**: Custom game engine in `/engine/` with modules for graphics, physics, input, audio, and game objects
- **Game States**: Main game loop uses the `WorldManager` state, which creates `Arena`s for combat
- **Entity System**: Uses GameObject base class with Group management for collision and updates
- **Module System**: Heavy use of `require` for modular organization

### Key Directories
- `/engine/`: Custom LÖVE2D-based engine with graphics, physics, math utilities
- `/units/`: Player units (Troop class with character types)
- `/enemies/`: Enemy units (Seeker class with enemy types) and level management
- `/ui/`: User interface elements including character cards, tooltips, progress bars
- `/helper/`: Utility functions and spell implementations
- `/procs/`: Item effects and perk system
- `/spawns/`: Enemy spawning and wave management
- `/combat_stats/`: Status effects (burn, chill, shock)
- `/achievements/`: Achievement tracking system
- `/documentation/`: Game design and code structure documentation

### Combat System
- **Units**: All combat entities inherit from GameObject with Physics
- **Player Units**: Troop class with `.character` property defining unit type
- **Enemies**: Enemy class with `.type` property defining enemy type
- **Spells**: Extend Spell class, craeted in `objects.lua` Unit class when a Unit creates a Cast object, that then creates the Spell object
- **Items/Procs**: Loaded onto units at round start, affect combat through callbacks (ex. onAttackCallback, onTickCallback)

### Unit States
- `idle`: Default state, can move and act normally (enemies)
- `normal`: Can move freely and perform actions (troops)
- `moving`: Active movement state
- `frozen`: Cannot move, typically during casting animations or status effects
- `stunned`: Temporarily disabled, cannot move or act
- `casting`: Performing a spell cast, movement may be restricted
- `channeling`: Sustaining a spell, typically stationary
- `stopped`: Doesn't auto-move, can be rallied (backswing state)
- `rallying`: Moving to a rally point
- `following`: Following a target or leader
- `knockback`: Unused, refer to is_launching
- `launching`: Unused, refer to is_launching
- `casting_blocked`: basically unused

### Unit flags
- is_launching: is in process of launching, physics are modified

### Game Flow
1. **Main Loop**: `main.lua` calls `State:update()` and `State:draw()`
2. **Combat**: `Arena:update()` and `Arena:draw()` handle battle logic
3. **Unit Updates**: Each GameObject calls `init()` once, then `update()` and `draw()` each frame

### Adding New Content
**New Units**: Must be added to lookup tables in `main.lua`, implement attack in appropriate class (`Troop:set_character()` for players, `Seeker:init()` for enemies)

**New Items**: Add to item system with proc definitions, loaded via proc system

**New Enemies**: Add to `Seeker:init()` and spawn logic in `Arena:on_enter()`
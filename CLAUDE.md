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
- **Game States**: Main game loop uses the `WorldManager` state (`screens/world_manager.lua`), which creates `Arena`s for combat
- **Entity System**: Uses GameObject base class with Group management for collision and updates
- **Module System**: Heavy use of `require` for modular organization; entry point is root `main.lua` → `core/main.lua`

### Key Directories
- `/core/`: Entry-point logic (`main.lua`), shared globals, utils, game constants, media loading
- `/engine/`: Custom LÖVE2D-based engine with graphics, physics, math utilities, data structures
- `/screens/`: Game screens — `mainmenu.lua`, `buy_screen.lua`, `world_manager.lua`, `level_select.lua`
- `/save/`: Save game logic (`save_game.lua`) and buy screen utilities (`buy_screen_utils.lua`)
- `/units/`: Unit classes — `units.lua` (class lists + Team), `/units/player/` (Troop, PlayerCursor, weapons)
- `/enemies/`: Enemy base class (`enemy.lua`), per-type files in `regular/`, `bosses/`, `miniboss/`, `static/`, `environmental/`
- `/level_classes/`: Arena, combat levels, stage wave data, doors, XP shards, objects
- `/spawns/`: Wave management (`spawnmanager.lua`, `levelmanager.lua`, `wave_types.lua`)
- `/ui/`: User interface elements including tooltips, perk cards, floor items, panels
- `/helper/`: Utility functions and spell implementations (`/helper/spells/`)
- `/procs/`: Item proc system (`procs.lua`, `proc.lua`) and perk system (`perks.lua`)
- `/items/`: Item definitions (`items_v2.lua`, `old_items.lua`, `constants.lua`)
- `/combat_stats/`: Status effect constants (burn, chill, shock)
- `/achievements/`: Achievement tracking and unlock logic
- `/animations/`: Sprite animation init
- `/util/`: Dev utilities — FPS counter, draw helpers, profiler

### Combat System
- **Units**: All combat entities inherit from `Unit` (with `GameObject` and `Physics` mixins)
- **Player Units**: `Troop` class in `units/player/player_troop.lua`; positioned at orb center (gw/2, gh/2); collision disabled. Subclasses: `Laser_Troop`, `Swordsman_Troop`, `Archer_Troop`
- **Player Cursor**: `PlayerCursor` in `units/player/player_cursor.lua` — the actual collidable player entity; receives hits and redirects damage to the orb
- **Weapons**: Separate weapon classes in `units/player/` (archer, frost AOE, machine gun, lightning, cannon, laser)
- **Enemies**: `Enemy` base class in `enemies/enemy.lua`; `.type` property maps to per-type init via `enemy_to_class` table; `EnemyCritter` for critter types
- **Spells**: Extend Spell class; created in `level_classes/objects.lua` when a Unit creates a Cast object, which then creates the Spell object
- **Items/Procs**: Loaded onto units at round start, affect combat through callbacks (e.g. `onAttackCallback`, `onTickCallback`)
- **Spawn System**: `SpawnManager` (initialized in Arena) consumes `stage_data` wave definitions from `stage_wave_data.lua` and `wave_types.lua`

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
1. **Main Loop**: root `main.lua` → `core/main.lua`; Love2D calls `love.update()` / `love.draw()` which dispatch to the active State
2. **State Machine**: `WorldManager` is the primary combat state; `MainMenu`, `BuyScreen`, and `LevelSelect` are the other screens
3. **Combat**: `Arena:update()` and `Arena:draw()` handle battle logic, enemy spawning via `SpawnManager`
4. **Unit Updates**: Each GameObject calls `init()` once, then `update()` and `draw()` each frame via their Group

### Adding New Content
**New Player Units**: Create a file in `units/player/`, extend `Troop` (or `Unit` directly), add to `require` list in `units/units.lua`, and add the class to `troop_classes`

**New Weapons**: Create a file in `units/player/`, extend `Weapon`, require in `units/units.lua`

**New Enemies**: Create a file in `enemies/regular/` (or appropriate subfolder), register in `enemy_to_class` table and `enemy_includes.lua`; add spawn entries to `level_classes/stage_wave_data.lua` or `spawns/wave_types.lua`

**New Items**: Add to `items/items_v2.lua` with proc definitions; procs are loaded via `procs/procs.lua`

**New Spells**: Extend `Spell` class in `helper/spells/` (v2 spells in `helper/spells/v2/`); create via Cast object in `level_classes/objects.lua`
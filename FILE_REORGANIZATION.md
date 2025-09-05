# File Reorganization Summary

## Files Moved from Root Directory

### To `core/` folder:
- main.lua (actual game logic, now loaded by root main.lua)
- shared.lua
- utils.lua 
- game_constants.lua
- media.lua

### To `screens/` folder:
- buy_screen.lua
- mainmenu.lua
- world_manager.lua

### To `save/` folder:
- save_game.lua
- buy_screen_utils.lua

### To `level_classes/` folder:
- door.lua
- miscellaneous_objects.lua
- objects.lua

## Files Kept in Root:
- main.lua (new entry point that requires core/main)
- conf.lua (Love2D needs this in root)
- Build/run scripts: build.sh, run.sh, server.py
- Documentation: README.md, CLAUDE.md, DEBUG_README.md, devlog.md, LICENSE
- Config files: .gitignore, .ctrlp, launch.json
- Steam libraries: libsteam_api.so, luasteam.so
- Design documents and todo files

## Updated Import Paths in core/main.lua:
- `require 'save_game'` → `require 'save/save_game'`
- `require 'shared'` → `require 'core/shared'`
- `require 'utils'` → `require 'core/utils'`
- `require 'game_constants'` → `require 'core/game_constants'`
- `require 'door'` → `require 'level_classes/door'`
- `require 'mainmenu'` → `require 'screens/mainmenu'`
- `require 'buy_screen_utils'` → `require 'save/buy_screen_utils'`
- `require 'buy_screen'` → `require 'screens/buy_screen'`
- `require 'world_manager'` → `require 'screens/world_manager'`
- `require 'objects'` → `require 'level_classes/objects'`
- `require 'miscellaneous_objects'` → `require 'level_classes/miscellaneous_objects'`
- `require 'media'` → `require 'core/media'`

## Launch Command:
The launch command `engine/love/love.exe --console .` remains the same since:
1. Love2D still finds main.lua in the root directory
2. The root main.lua loads core/main.lua which contains the actual game logic
3. conf.lua remains in the root directory where Love2D expects it

## Benefits of This Organization:
1. Cleaner root directory
2. Better organization for LEANN indexing (can now exclude assets/ folder)
3. Logical grouping of related files
4. Easier navigation and maintenance
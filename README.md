






# UNDERLOD

UNDERLOD is an arcade RTS roguelite where you control an army of units that automatically attack nearby enemies.

https://user-images.githubusercontent.com/22898519/134641583-11ba18c1-c698-47c0-aa74-3bbc3ce1dc4f.mp4

### Running

Download this repository, `cd` into it and then run `engine/love/love.exe --console .`

### Build

https://love2d.org/wiki/Game_Distribution#Creating_a_Windows_Executable

For Windows,

Make a .zip file containing all project files (except /builds)
Move to /builds/windows
Rename to .love - powershell: (Rename-Item .\UNDERLOD.zip UNDERLOD.love)
Combine with love.exe - powershell: (cmd /c copy /b love.exe+UNDERLOD.love UNDERLOD.exe)

must be run in folder with .dlls, so rezip to upload?


### Controls
1-9 to select unit class

RMB rallies units of the selected class

LMB moves units of the selected class

SPACE moves all units

DEBUG:
ctrl+a shows fps
ctrl+g gives 100 gold
d makes damage circle

### Dev notes at
design doc:
https://docs.google.com/document/d/1h1HBBKpgfyQK8WC4L8NUQqK6oAXedDW6Qe8LG5zbEEI/edit

unit balance:
https://docs.google.com/spreadsheets/d/1QvwsmUMpfQ2xgpiHGV0wy-ooc-nnkyhdeTN2CoGGme8/edit#gid=0

### LICENSE

All assets have their specific licenses and they are linked to in the game's credits. All code is under the MIT license.

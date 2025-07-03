






# UNDERLOD

UNDERLOD is an arcade RTS roguelite. Control your units and optimize their builds to victory!




https://github.com/user-attachments/assets/8ddd9f0e-0e6b-4d01-93ba-c0ac94a314bf



### Running

Windows:

Download this repository, `cd` into it and then run `engine/love/love.exe --console .`

Linux:

Install love with `sudo apt install love`

Download the repo, `cd` into it

Link the libraries with 

  export LD_LIBRARY_PATH=PATH_TO_REPO:$LD_LIBRARY_PATH

Then run with 

  love .


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

ctrl+u toggles level select buttons

ctrl+p toggles basic profiler

f11 clears all achievements (and tries to clear from steam as well)

d makes damage circle
s makes sweep spell

### Dev notes at
design doc:
https://docs.google.com/document/d/1h1HBBKpgfyQK8WC4L8NUQqK6oAXedDW6Qe8LG5zbEEI/edit

unit balance:
https://docs.google.com/spreadsheets/d/1QvwsmUMpfQ2xgpiHGV0wy-ooc-nnkyhdeTN2CoGGme8/edit#gid=0

### LICENSE

All assets have their specific licenses and they are linked to in the game's credits. All code is under the MIT license.

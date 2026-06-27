@echo off
setlocal
rem Always run from this script's own folder (engine\love) so the ..\..\
rem relative paths resolve to the project root no matter where it's launched.
cd /d "%~dp0"
rem Project name. Defaults to UNDERLOD when no argument is given.
if "%~1"=="" (set "NAME=UNDERLOD") else (set "NAME=%~1")

call "C:\Program Files\7-Zip\7z.exe" a -r "%NAME%.zip" -w ..\..\ -xr!engine/love -xr!builds -xr!steam -xr!.git -xr!*.moon -xr!.worktrees -xr!.venv -xr!__pycache__ -xr!*.pyc -xr!.aider* -xr!.vscode -xr!analysis -xr!*.py -xr!*.docx -xr!*.sh -xr!devlog.md -xr!todo.txt -xr!todo-balance -xr!.gitignore -xr!CLAUDE.md -xr!README.md -xr!*.psd -xr!*.aseprite -xr!.DS_Store
rename "%NAME%.zip" "%NAME%.love"
call love-js -c -m 1073741824 -t %NAME% %2\engine\love\%NAME%.love ..\..\builds\web
del "%NAME%.love"

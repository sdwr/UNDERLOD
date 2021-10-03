
$path = "C:\Users\rory\code\UNDERLOD"
$destination = "C:\Users\rory\code\UNDERLOD\builds\web\underlod.zip"
$destinationLove = "C:\Users\rory\code\UNDERLOD\builds\web\underlod.love"
$server = "C:\Users\rory\code\UNDERLOD\builds\web\server.py"
$lovejsDir = "C:\Users\rory\code\UNDERLOD\builds\web\underlod"
$serverCopy = "C:\Users\rory\code\UNDERLOD\builds\web\underlod\server.py"
$exclude = @("builds")

Remove-Item -Path $destination
Remove-Item -Path $destinationLove
Get-ChildItem $path -Directory | 
    where {$_.Name -notin $exclude} | 
        Compress-Archive -DestinationPath $destination -Update
        
Rename-Item -Path $destination -NewName underlod.love
npx love.js -m 100000000 ./UNDERLOD.love ./underlod
Copy-Item -Path $server -Destination $lovejsDir
python $serverCopy
        
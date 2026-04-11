set sh1 to "launchctl unload -w /Library/LaunchDaemons/ru.deskru.DeskRu_service.plist;"
set sh2 to "/bin/rm /Library/LaunchDaemons/ru.deskru.DeskRu_service.plist;"
set sh3 to "/bin/rm /Library/LaunchAgents/ru.deskru.DeskRu_server.plist;"

set sh to sh1 & sh2 & sh3
do shell script sh with prompt "DeskRu wants to unload daemon" with administrator privileges

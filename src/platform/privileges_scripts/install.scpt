on run {daemon_file, agent_file, user}

  set sh1 to "echo " & quoted form of daemon_file & " > /Library/LaunchDaemons/ru.deskru.DeskRu_service.plist && chown root:wheel /Library/LaunchDaemons/ru.deskru.DeskRu_service.plist;"

  set sh2 to "echo " & quoted form of agent_file & " > /Library/LaunchAgents/ru.deskru.DeskRu_server.plist && chown root:wheel /Library/LaunchAgents/ru.deskru.DeskRu_server.plist;"

  set sh3 to "cp -rf /Users/" & user & "/Library/Preferences/ru.deskru.DeskRu/DeskRu.toml /var/root/Library/Preferences/ru.deskru.DeskRu/;"

  set sh4 to "cp -rf /Users/" & user & "/Library/Preferences/ru.deskru.DeskRu/DeskRu2.toml /var/root/Library/Preferences/ru.deskru.DeskRu/;"

  set sh5 to "launchctl load -w /Library/LaunchDaemons/ru.deskru.DeskRu_service.plist;"

  set sh to sh1 & sh2 & sh3 & sh4 & sh5

  do shell script sh with prompt "DeskRu wants to install daemon and agent" with administrator privileges
end run

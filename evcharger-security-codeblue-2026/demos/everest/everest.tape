Output everest.mp4
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 30
Set Theme "Builtin Dark"
Set TypingSpeed 40ms
Hide
Type "clear" Enter
Show
Type "# EVerest reference charger + simulated car, default config" Sleep 600ms Enter
Type "./run.sh 2>&1 | grep -v -E 'Container|Network|level=warning|^$' | cut -c1-118" Sleep 400ms Enter
Wait+Screen@120s /V2G messages/
Sleep 1s
Type "# TLS server is up. the car says no TLS. the charger says sure." Sleep 600ms Enter
Sleep 5s

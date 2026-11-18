Output ocpp.mp4
Set FontSize 20
Set Width 1600
Set Height 900
Set Padding 30
Set Theme "Builtin Dark"
Set TypingSpeed 40ms
Hide
Type "clear" Enter
Show
Type "# a charger with no OCPP security profile, talking to our CSMS on localhost" Sleep 600ms Enter
Type "./run.sh 2>&1 | grep -v -E 'listening|connection' | cut -c1-118" Sleep 400ms Enter
Sleep 6s
Type "# one JSON message, and the charger agrees to install whatever is at that URL" Sleep 600ms Enter
Sleep 4s

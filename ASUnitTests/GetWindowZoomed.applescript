global HandyAdiumScripts

on run
	tell application "Adium"
		set c to zoomed of window 1
		set zoomed of window 1 to not c
		delay 2
		if (get zoomed of window 1) is c then error
	end tell
end run
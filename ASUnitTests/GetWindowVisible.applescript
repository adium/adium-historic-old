global HandyAdiumScripts

on run
	tell application "Adium"
		set c to visible of window 1
		set visible of window 1 to not c
		if (get visible of window 1) is c then error
	end tell
end run
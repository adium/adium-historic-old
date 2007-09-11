global HandyAdiumScripts

on run
	tell application "Adium"
		set c to minimized of window 1
		set minimized of window 1 to not c
		if (get minimized of window 1) is c then error
	end tell
end run
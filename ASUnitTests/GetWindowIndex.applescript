global HandyAdiumScripts

on run
	tell application "Adium"
		if (get index of window 1) is not 1 then error
	end tell
end run
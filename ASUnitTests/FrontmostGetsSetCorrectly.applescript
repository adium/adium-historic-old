global HandyAdiumScripts

on run
	tell application "Adium"
		activate
		if not (get frontmost) then error
	end tell
end run
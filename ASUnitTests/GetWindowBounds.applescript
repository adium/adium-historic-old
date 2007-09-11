global HandyAdiumScripts

on run
	tell application "Adium"
		get bounds of window 1 -- Can't check for this...
	end tell
end run
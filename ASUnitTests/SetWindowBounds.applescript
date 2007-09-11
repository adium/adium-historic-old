global HandyAdiumScripts

on run
	tell application "Adium"
		set bounds of window 1 to {0, 0, 40, 40}
		if (get bounds of window 1) is not {0, 0, 40, 40} then error
	end tell
end run
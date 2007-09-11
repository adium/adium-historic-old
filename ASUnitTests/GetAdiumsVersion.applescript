global HandyAdiumScripts

on run
	tell application "Adium"
		if (get version) is missing value then error
	end tell
end run
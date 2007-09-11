global HandyAdiumScripts

on run
	tell application "Adium"
		if (get name of window "Contacts") is not "Contacts" then error
	end tell
end run
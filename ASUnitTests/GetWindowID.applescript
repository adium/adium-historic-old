global HandyAdiumScripts

on run
	tell application "Adium"
		get id of window "Contacts" --I don't know how to check this condition
	end tell
end run
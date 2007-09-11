global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		set n to (HandyAdiumScripts's defaultService & "." & HandyAdiumScripts's defaultParticipant)
		if (get id of newChat) is not n then error
		close newChat
	end tell
end run
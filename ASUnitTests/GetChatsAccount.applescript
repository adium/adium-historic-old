global HandyAdiumScripts
on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChat()
		if (get account of newChat) is not account (HandyAdiumScripts's defaultAccount) then error
		close newChat
	end tell
end run
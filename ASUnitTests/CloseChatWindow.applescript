global HandyAdiumScripts

on run
	tell application "Adium"
		set newChat to HandyAdiumScripts's makeNewChatWindow()
		set cw to (count chat windows)
		close newChat
		delay 1
		if (count chat windows) is not cw - 1 then error ("count chat windows is " & (count chat windows) & " rather than " & (cw - 1))
		if (exists newChat) then error
	end tell
end run
global HandyAdiumScripts

on run
	tell application "Adium"
		try
			set minimizable of window 1 to false
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run
global HandyAdiumScripts

on run
	tell application "Adium"
		try
			set name of window 1 to "dummy"
			error
		on error number num
			if num is -2700 then error
		end try
	end tell
end run
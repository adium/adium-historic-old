global HandyAdiumScripts

on run
	tell application "Adium"
		set newAccount to HandyAdiumScripts's makeTemporaryAccount()
		set c to count accounts
		delete newAccount
		if (count accounts) is not c - 1 then error
	end tell
end run
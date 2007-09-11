global HandyAdiumScripts

on run
	tell application "Adium"
		set c to count accounts
		tell service "AIM"
			set newAccount to make new account with properties {name:"test"}
		end tell
		if (count accounts) is not c + 1 then error
		delete newAccount
	end tell
end run
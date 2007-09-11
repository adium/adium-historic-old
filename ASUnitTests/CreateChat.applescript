global HandyAdiumScripts
script HandyAdiumScripts
	property defaultService : "AIM"
	property defaultAccount : "applmak"
	property defaultParticipant : "applmak"
	property defaultSecondParticipant : "boredzo"
end script

on run
	tell application "Adium"
		set c to count chat windows
		set c2 to count chats
		tell account (HandyAdiumScripts's defaultAccount)
			set newChat to make new chat with contacts {contact (HandyAdiumScripts's defaultParticipant)} with new chat window
			set newChatWindow to (get window of newChat)
			if (count chat windows of application "Adium") is not c + 1 then error
			if (count chats of application "Adium") is not c2 + 1 then error
			if (count chats of newChatWindow) is not 1 then error
			set newChat2 to make new chat with contacts {contact (HandyAdiumScripts's defaultSecondParticipant)} at end of chats of newChatWindow
			if (count chat windows of application "Adium") is not c + 1 then error
			if (count chats of application "Adium") is not c2 + 2 then error
			if (count chats of newChatWindow) is not 2 then error
			close newChatWindow
		end tell
	end tell
end run
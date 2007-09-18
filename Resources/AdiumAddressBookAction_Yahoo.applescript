using terms from application "Address Book"
	on action property
		return "yahoo"
	end action property
	
	on action title for aPerson with screenName
		return "Adium"
	end action title
	
	on should enable action for aPerson with screenName
		return true
	end should enable action
	
	on perform action for aPerson with screenName
		set screenName to (value of screenName as string)
		using terms from application "Adium"
			
			tell application "Adium"
				(* We want a Jabber account to be online or connecting before proceeding *)
				if (((every «class acct» whose «class AsSC» is "Yahoo!" and «class AcOn» is yes) count) is equal to 0) then
					tell (the first «class acct» whose «class AsSC» is "Yahoo!") to «event AdIMcnct»
				end if
				
				(* Create the chat and find the contact it is with *)
				tell the first «class astC» to «event AdIMcCdM» given «class TO  »:screenName, «class cCsI»:"Yahoo!"
				set theContact to (the first «class ltct» whose «class AUID» is screenName and «class AsSC» is "Yahoo!")
				
				(* Make the chat active *)
				activate
				set the «class AiAC» of the first «class AiCC» to the first «class Acht» whose «class ltct» is theContact
				
			end tell
		end using terms from
		
		return true
	end perform action
	
end using terms from
using terms from application "Address Book"
	on action property
		return "phone"
	end action property
	
	on action title for aPerson with phoneNumber
		return "Adium"
	end action title
	
	on should enable action for aPerson with phoneNumber
		return true
	end should enable action
	
	on perform action for aPerson with phoneNumber
		set phoneNumber to (value of phoneNumber as string)
		
		(* remove ignored phone characters *)
		set AppleScript's text item delimiters to {" "}
		set chunks to text items of phoneNumber
		set AppleScript's text item delimiters to {""}
		set phoneNumber to chunks as Unicode text
		
		set AppleScript's text item delimiters to {"-"}
		set chunks to text items of phoneNumber
		set AppleScript's text item delimiters to {""}
		set phoneNumber to chunks as Unicode text
		
		set AppleScript's text item delimiters to {"("}
		set chunks to text items of phoneNumber
		set AppleScript's text item delimiters to {""}
		set phoneNumber to chunks as Unicode text
		
		set AppleScript's text item delimiters to {")"}
		set chunks to text items of phoneNumber
		set AppleScript's text item delimiters to {""}
		set phoneNumber to chunks as Unicode text
		
		set AppleScript's text item delimiters to {"."}
		set chunks to text items of phoneNumber
		set AppleScript's text item delimiters to {""}
		set phoneNumber to chunks as Unicode text
		
		if (phoneNumber does not start with "1") and (phoneNumber does not start with "+") then
			(* If the phone number neither starts with "1" nor with "+", add "+1" to it *)
			set phoneNumber to "+1" & phoneNumber
			
		else if (phoneNumber does not start with "+") then
			(* If the phone number does not start with "+", add "+" to it *)
			
			set phoneNumber to "+" & phoneNumber
		end if
		
		using terms from application "Adium"
			
			tell application "Adium"
				set theServiceID to (the «class AsID» of (the first «class acct» whose «class AsSC» is "AIM-compatible" and «class AcOn» is yes))
				
				(* We want an AIM, ICQ, or .Mac account to be online or connecting before proceeding *)
				if (((every «class acct» whose «class AsSC» is "AIM-compatible" and «class AcOn» is yes) count) is equal to 0) then
					tell (the first «class acct» whose «class AsSC» is "AIM-compatible") to «event AdIMcnct»
					
					set theServiceID to (the «class AsID» of (the first «class acct» whose «class AsSC» is "AIM-compatible"))
				end if
				
				(* Create the chat and find the contact it is with *)
				(* serviceID of theAccount*)
				
				tell the first «class astC» to «event AdIMcCdM» given «class TO  »:phoneNumber, «class cCsI»:theServiceID
				set theContact to (the first «class ltct» whose «class AUID» is phoneNumber and «class AsSC» is "AIM-compatible")
				
				activate
				set the «class AiAC» of the first «class AiCC» to the first «class Acht» whose «class ltct» is theContact
			end tell
		end using terms from
		
		return true
	end perform action
	
end using terms from
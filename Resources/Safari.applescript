on substitute(severalBrowsersPrompt)
	set candidates to {}
	set labelledcandidates to {}
	set candidateURLs to {}
	tell application "System Events"
		if ((application processes whose (name is equal to "Safari")) count) is greater than 0 then
			tell application "Safari"
				if (count of documents) is greater than 0 then
					set the end of labelledcandidates to "Safari: " & (name of front document)
					set the end of candidates to (name of front document)
					set the end of candidateURLs to URL of front document
				end if
			end tell
		end if
		if ((application processes whose (name is equal to "OmniWeb")) count) is greater than 0 then
			tell application "OmniWeb"
				if (count of every browser) is greater than 0 then
					set the end of labelledcandidates to "OmniWeb: " & (name of front browser)
					set the end of candidates to (name of front browser)
					set the end of candidateURLs to address of front browser
				end if
			end tell
		end if
		if ((application processes whose (name is equal to "Camino")) count) is greater than 0 then
			using terms from application "Camino"
				tell application "Camino"
					if version ³ 1.0 then
						if (count of every window) is greater than 0 then
							set the end of labelledcandidates to "Camino: " & (name of front window)
							set the end of candidateURLs to the URL of front window
							set the end of candidates to name of front window
						end if
					end if
				end tell
			end using terms from
		end if
		if ((application processes whose (name is equal to "firefox-bin")) count) is greater than 0 then
			tell application "Firefox"
				if (count of every window) is greater than 0 then
					set the end of labelledcandidates to "Firefox: " & (Çclass pTitÈ of window 1)
					set the end of candidateURLs to Çclass curlÈ of window 1
					set the end of candidates to Çclass pTitÈ of window 1
				end if
			end tell
		end if
		if ((application processes whose (name is equal to "NetNewsWire")) count) is greater than 0 then
			tell application "NetNewsWire"
				if (index of selected tab) is greater than 0 then
					set nnwselT to index of selected tab + 1 -- the news items tab is not present in the lists of titles and tabs, so we have to bump this
					-- gotta prefetch these
					set nnwtitles to titles of tabs
					set nnwurls to URLs of tabs
					set the end of labelledcandidates to "NetNewsWire: " & (item nnwselT of nnwtitles)
					set the end of candidates to (item nnwselT of nnwtitles)
					set the end of candidateURLs to (item nnwselT of nnwurls)
				end if
			end tell
		end if
		if ((application processes whose (name is equal to "Shiira")) count) is greater than 0 then
			tell application "Shiira"
				if (count documents) > 0 then
					set the_doc to document 1
					set the end of labelledcandidates to "Shiira: " & name of the_doc
					set the end of candidates to name of the_doc
					set the end of candidateURLs to URL of the_doc
				end if
			end tell
		end if
		if ((count of labelledcandidates) is greater than 1) then
			set theChosen to {}
			try
				tell application "Adium"
					set theChosen to (choose from list labelledcandidates with prompt severalBrowsersPrompt)
				end tell
			on error
				return ""
			end try
			if theChosen is not equal to {} then
				repeat with chosen in theChosen
					set i to 1
					repeat with aName in labelledcandidates
						if aName & "" is equal to chosen & "" then
							return "<HTML><A HREF=\"" & (item i of candidateURLs) & "\">" & (item i of candidates) & "</A></HTML>"
						end if
						set i to i + 1
					end repeat
				end repeat
			end if
		else if ((count of labelledcandidates) is 1) then
			return "<HTML><A HREF=\"" & (item 1 of candidateURLs) & "\">" & (item 1 of candidates) & "</A></HTML>"
		else
			return ""
		end if
	end tell
end substitute
//
//  ESAnnouncerPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//

#import "ESAnnouncerPlugin.h"
#import "ESAnnouncerAlertDetailPane.h"

#define	CONTACT_ANNOUNCER_NIB		@"ContactAnnouncer"		//Filename of the announcer info view
#define ANNOUNCER_ALERT_SHORT		AILocalizedString(@"Speak Specific Text",nil)
#define ANNOUNCER_ALERT_LONG		AILocalizedString(@"Speak the text \"%@\"",nil)

#define	ANNOUNCER_EVENT_ALERT_SHORT	AILocalizedString(@"Speak Event","short phrase for the contact alert which speaks the event")
#define	ANNOUNCER_EVENT_ALERT_LONG	AILocalizedString(@"Speak the event aloud","short phrase for the contact alert which speaks the event")

@interface ESAnnouncerPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESAnnouncerPlugin

- (void)installPlugin
{
    //Install our contact alerts
	[[adium contactAlertsController] registerActionID:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER
										  withHandler:self];
	[[adium contactAlertsController] registerActionID:CONTACT_ALERT_SPEAK_EVENT_IDENTIFIER
										  withHandler:self];
    
    //Setup our preferences
    preferences = [[ESAnnouncerPreferences preferencePane] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ANNOUNCER];

    //Install the contact info view
/*
	[NSBundle loadNibNamed:CONTACT_ANNOUNCER_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Announcer" categoryName:@"None" view:view_contactAnnouncerInfoView delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    [popUp_voice addItemsWithTitles:[[adium soundController] voices]];
 */
    
    observingContent = NO;
    lastSenderString = nil;
	
    //Observer preference changes
	[[adium preferenceController] registerPreferenceObserver:self 
													forGroup:PREF_GROUP_ANNOUNCER];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
//    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	speechEnabled = [[prefDict objectForKey:KEY_ANNOUNCER_ENABLED] boolValue];
	speakOutgoing = [[prefDict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue];
	speakIncoming = [[prefDict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue];
	speakMessages = speakOutgoing || speakIncoming;
	
	speakMessageText = [[prefDict objectForKey:KEY_ANNOUNCER_MESSAGETEXT] boolValue];
	speakStatus = [[prefDict objectForKey:KEY_ANNOUNCER_STATUS] boolValue];
	
	speakTime = [[prefDict objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakSender = [[prefDict objectForKey:KEY_ANNOUNCER_SENDER] boolValue];
	
	BOOL	newValue = ((speakMessages || speakStatus) && speechEnabled);
	
	if(newValue != observingContent){
		observingContent = newValue;
		
		if(!observingContent){ //Stop Observing
			[[adium notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];
		}else{ //Start Observing
			[[adium notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];
		}
	}
}

- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"AIContentObject"];
	
    AIChat			*chat = nil;
    NSString		*message = nil;
    AIAccount		*account = nil;
    AIListObject	*source = nil;
    NSCalendarDate	*date = nil;
    NSString		*dateString = nil;
    NSMutableString	*theMessage = nil;
	

	if(speechEnabled && [content trackContent]){
		//Message Content
		if(speakMessages && ([[content type] isEqualToString:CONTENT_MESSAGE_TYPE])){
			date = [[content date] dateWithCalendarFormat:nil timeZone:nil];
			chat	= [notification object];
			account	= [chat account];
			source	= [content source];
			message = [[[content message] safeString] string];
			
			
			if(account && source){ //valid message
				//Determine some basic info about the content
				BOOL isOutgoing = [content isOutgoing];
				BOOL newParagraph = NO;
				if ((isOutgoing  && speakOutgoing) || (!isOutgoing && speakIncoming)){
					
					theMessage = [NSMutableString string];
					
					if(speakSender && !isOutgoing) {
						NSString	*senderString;

						//Get the sender string
						senderString = [source displayName];
						
						if(!lastSenderString || ![senderString isEqualToString:lastSenderString]){
							NSMutableString		*senderStringToSpeak;
							
							[lastSenderString release]; lastSenderString = [senderString retain];
							
							senderStringToSpeak = [senderString mutableCopy];
							[senderStringToSpeak replaceOccurrencesOfString:@" " 
																 withString:@" [[emph -]] " 
																	options:NSCaseInsensitiveSearch
																	  range:NSMakeRange(0, [senderStringToSpeak length])]; //deemphasize all words after first in sender's name
							[theMessage appendFormat:@"[[emph +]] %@...",senderStringToSpeak]; //emphasize first word in sender's name
							newParagraph = YES;
							
							[senderStringToSpeak release];
						}
					}
					
					if(speakTime){
						dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
						[theMessage appendFormat:@" %@...",dateString];
					}
					
					if(newParagraph){
						[theMessage appendFormat:@" [[pmod +1; pbas +1]]"];
					}
					
					if(speakMessageText){
						[theMessage appendFormat:@" %@",message];
					}
				}
			}
		} else if(speakStatus && ([[content type] isEqualToString:CONTENT_STATUS_TYPE])){
			account	= [chat account];
			source	= [content source];


			if(account && source){

				theMessage = [NSMutableString string];

				message = [[[content message] safeString] string];
				date = [[content date] dateWithCalendarFormat:nil timeZone:nil];
				chat = [notification object];
				
				if (speakTime) {
					dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
					[theMessage appendFormat:@" %@...",dateString];
				}
				[theMessage appendFormat:@" %@",message];
			}
		}
		
		//Speak the message
		if(theMessage != nil){
			AIListObject	*otherPerson = [chat listObject];
			if (otherPerson) { //one-on-one chat; check for and use custom settings
				NSString	*voice = nil;
				NSNumber	*pitchNumber = nil;	float pitch = 0;
				NSNumber	*rateNumber = nil;	int rate = 0;
				voice = [otherPerson preferenceForKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER];
				
				pitchNumber = [otherPerson preferenceForKey:PITCH group:PREF_GROUP_ANNOUNCER];
				if(pitchNumber)
					pitch = [pitchNumber floatValue];
				
				rateNumber = [otherPerson preferenceForKey:RATE group:PREF_GROUP_ANNOUNCER];
				if(rateNumber)
					rate = [rateNumber intValue];
				
				[[adium soundController] speakText:theMessage withVoice:voice andPitch:pitch andRate:rate];
			} else { //must be in a chat room - just speak the message
				[[adium soundController] speakText:theMessage];
			}
		}
	}
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSString	*voice = nil;
    NSNumber	*pitchNumber = nil;
    NSNumber	*rateNumber = nil;
	
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];
    voice = [activeListObject preferenceForKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER  ignoreInheritedValues:YES];
    if(voice) {
        [popUp_voice selectItemWithTitle:voice];
    } else {
        [popUp_voice selectItemAtIndex:0]; //"Default"
    }
	
    pitchNumber = [activeListObject preferenceForKey:PITCH group:PREF_GROUP_ANNOUNCER ignoreInheritedValues:YES];
    if(pitchNumber) {
		[slider_pitch setFloatValue:[pitchNumber floatValue]];
    } else {
		[slider_pitch setFloatValue:[[adium soundController] defaultPitch]];
    }
	
    rateNumber = [activeListObject preferenceForKey:RATE group:PREF_GROUP_ANNOUNCER ignoreInheritedValues:YES];
    if(rateNumber) {
		[slider_rate setIntValue:[rateNumber intValue]];
    } else {
		[slider_rate setIntValue:[[adium soundController] defaultRate]];
    }
}

- (IBAction)changedSetting:(id)sender
{
    if (sender == popUp_voice) {
		NSString * voice = [popUp_voice titleOfSelectedItem];
		if ([voice isEqualToString:@"Default"]){
			voice = nil;
		}
		[activeListObject setPreference:voice forKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_pitch) {
        [activeListObject setPreference:[NSNumber numberWithFloat:[slider_pitch floatValue]] forKey:PITCH group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_rate) {
        [activeListObject setPreference:[NSNumber numberWithInt:[slider_rate intValue]] forKey:RATE group:PREF_GROUP_ANNOUNCER];
    }
}


//Speak Text Alert -----------------------------------------------------------------------------------------------------
#pragma mark Speak Text Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER]){
		return(ANNOUNCER_ALERT_SHORT);
	}else{ /*Speak Event*/
		return(ANNOUNCER_EVENT_ALERT_SHORT);
	}
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	if([actionID isEqualToString:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER]){		
		NSString *textToSpeak = [details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
		
		if(textToSpeak && [textToSpeak length]){
			return([NSString stringWithFormat:ANNOUNCER_ALERT_LONG, textToSpeak]);
		}else{
			return(ANNOUNCER_ALERT_LONG);
		}
	}else{ /*Speak Event*/
		return(ANNOUNCER_EVENT_ALERT_LONG);
	}
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"AnnouncerAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	if([actionID isEqualToString:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER]){
		return([ESAnnouncerAlertDetailPane actionDetailsPane]);
	}else{ /*Speak Event*/
		return(/*[ESAnnouncerEventAlertDetailPane actionDetailsPane]*/nil);
	}
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	NSString *textToSpeak = nil;
	
	if([actionID isEqualToString:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER]){
		textToSpeak = [details objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	}else{ /*Speak Event*/
		textToSpeak = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
																				 listObject:listObject
																				   userInfo:userInfo
																			 includeSubject:YES];		
	}

	if(textToSpeak){
		[[adium soundController] speakText:textToSpeak];
	}
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	if([actionID isEqualToString:CONTACT_ALERT_SPEAK_TEXT_IDENTIFIER]){
		return(YES);
	}else{ /*Speak Event*/
		return(NO);
	}
}

@end

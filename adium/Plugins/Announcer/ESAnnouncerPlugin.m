//
//  ESAnnouncerPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//

#import "ESAnnouncerPlugin.h"
#import "ESAnnouncerContactAlert.h"

#define	CONTACT_ANNOUNCER_NIB		@"ContactAnnouncer"		//Filename of the announcer info view

@interface ESAnnouncerPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESAnnouncerPlugin

- (void)installPlugin
{
    //Install our contact alert
    [[adium contactAlertsController] registerContactAlertProvider:self];
    
    //Setup our preferences
    preferences = [[ESAnnouncerPreferences preferencePane] retain];
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ANNOUNCER];

    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ANNOUNCER_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Announcer" categoryName:@"None" view:view_contactAnnouncerInfoView delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    [popUp_voice addItemsWithTitles:[[adium soundController] voices]];
    
    observingContent = NO;
    lastSenderString = nil;
    //Observer preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
    [[adium contactAlertsController] unregisterContactAlertProvider:self];
    
}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ANNOUNCER] == 0){
	NSDictionary * dict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];

	speechEnabled = [[dict objectForKey:KEY_ANNOUNCER_ENABLED] boolValue];
	speakOutgoing = [[dict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue];
	speakIncoming = [[dict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue];
	speakMessages = speakOutgoing || speakIncoming;
        
	speakMessageText = [[dict objectForKey:KEY_ANNOUNCER_MESSAGETEXT] boolValue];
	speakStatus = [[dict objectForKey:KEY_ANNOUNCER_STATUS] boolValue];

	speakTime = [[dict objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakSender = [[dict objectForKey:KEY_ANNOUNCER_SENDER] boolValue];

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
}

- (void)contentObjectAdded:(NSNotification *)notification
{
    AIContentMessage 	*content = [[notification userInfo] objectForKey:@"Object"];
	
    AIChat		*chat = nil;
    NSString		*message = nil;
    AIAccount		*account = nil;
    NSString		*object = nil;
    AIListObject	*source = nil;
    NSCalendarDate	*date = nil;
    NSString		*dateString = nil;
    NSMutableString	*theMessage = nil;
	
	
	if(speechEnabled) {
		//Message Content
		if(speakMessages && ([[content type] compare:CONTENT_MESSAGE_TYPE] == 0) ){
			date = [[content date] dateWithCalendarFormat:nil timeZone:nil];
			chat	= [notification object];
			object  = [[chat statusDictionary] objectForKey:@"DisplayName"];
			if(!object) object = [[chat listObject] UID];
			account	= [chat account];
			source	= [content source];
			message = (NSString *)[[[content message] safeString] string];
			
			
			if(account && source) { //valid message
				theMessage = [[NSMutableString alloc] init];
				//Determine some basic info about the content
				BOOL isOutgoing = [content isOutgoing];
				BOOL newParagraph = NO;
				if ( (isOutgoing  && speakOutgoing) || (!isOutgoing && speakIncoming) ) {
					
					if (speakSender && !isOutgoing) {
						NSString * senderString;
						//Get the sender string
						/*  if(isOutgoing){ //speak outgoing message sender names
						senderString = [[adium accountController] propertyForKey:@"FullName" account:(AIAccount *)source];
						if(!senderString || [senderString length] == 0) senderString = [(AIAccount *)source accountDescription];
						}else{ */ //incoming message sender name
						senderString = [(AIListContact *)source displayName];
						//		    }
						
						if (!lastSenderString || [senderString compare:lastSenderString] != 0) {
							[theMessage replaceOccurrencesOfString:@" " withString:@" [[emph -]] " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [theMessage length])]; //deemphasize all words after first in sender's name
							[theMessage appendFormat:@"[[emph +]] %@...",senderString]; //emphasize first word in sender's name
							[lastSenderString release]; lastSenderString = [senderString retain];
							newParagraph = YES;
						}
					}
					
					if (speakTime) {
						dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
						[theMessage appendFormat:@" %@...",dateString];
					}
					
					if (newParagraph) {
						[theMessage appendFormat:@" [[pmod +1; pbas +1]]"];
					}
					
					if (speakMessageText) {
						[theMessage appendFormat:@" %@",message];
					}
				}
			}
		}
		else if(speakStatus && ([[content type] compare:CONTENT_STATUS_TYPE] == 0) ){
			date = [[content date] dateWithCalendarFormat:nil timeZone:nil];
			chat	= [notification object];
			object  = [[chat statusDictionary] objectForKey:@"DisplayName"];
			if(!object) object = [[chat listObject] UID];
			account	= [chat account];
			source	= [content source];
			message = (NSString *)[content message];
			
			if(account && source){
				theMessage = [[NSMutableString alloc] init];
				if (speakTime) {
					dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
					[theMessage appendFormat:@" %@...",dateString];
				}
				[theMessage appendFormat:@" %@",message];
			}
		}
		
		//Speak the message
		if(theMessage != nil){
			AIListObject * otherPerson = [chat listObject];
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
	if ([voice compare:@"Default"] == 0)
	    voice = nil;
	[activeListObject setPreference:voice forKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_pitch) {
        [activeListObject setPreference:[NSNumber numberWithFloat:[slider_pitch floatValue]] forKey:PITCH group:PREF_GROUP_ANNOUNCER];
    } else if (sender == slider_rate) {
        [activeListObject setPreference:[NSNumber numberWithInt:[slider_rate intValue]] forKey:RATE group:PREF_GROUP_ANNOUNCER];
    }
}

//*****
//ESContactAlertProvider
//*****

- (NSString *)identifier
{
    return CONTACT_ALERT_IDENTIFIER;
}

- (ESContactAlert *)contactAlert
{
    return [ESAnnouncerContactAlert contactAlert];   
}

//performs an action using the information in details and detailsDict (either may be passed as nil in many cases), returning YES if the action fired and NO if it failed for any reason
- (BOOL)performActionWithDetails:(NSString *)details andDictionary:(NSDictionary *)detailsDict triggeringObject:(AIListObject *)inObject triggeringEvent:(NSString *)event eventStatus:(BOOL)event_status actionName:(NSString *)actionName
{
    [[adium soundController] speakText:details];
    return YES;
}

//continue processing after a successful action
- (BOOL)shouldKeepProcessing
{
    return YES;   
}

@end

//
//  ESAnnouncerPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerPlugin.h"

#define	CONTACT_ANNOUNCER_NIB		@"ContactAnnouncer"		//Filename of the announcer info view
#define ANNOUNCER_DEFAULT_PREFS 	@"AnnouncerDefaults.plist"

@interface ESAnnouncerPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESAnnouncerPlugin

- (void)installPlugin
{
    //Setup our preferences
    preferences = [[ESAnnouncerPreferences preferencePaneWithOwner:owner] retain];
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_ANNOUNCER];

    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ANNOUNCER_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Announcer" categoryName:@"None" view:view_contactAnnouncerInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];
    [popUp_voice addItemsWithTitles:[[owner soundController] voices]];
    
    observingContent = NO;
    lastSenderString = nil;
    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{

}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_ANNOUNCER] == 0){
	NSDictionary * dict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];
	speakOutgoing = [[dict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue];
	speakIncoming = [[dict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue];
	speakMessages = speakOutgoing || speakIncoming;

	speakStatus = [[dict objectForKey:KEY_ANNOUNCER_STATUS] boolValue];

	speakTime = [[dict objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakSender = [[dict objectForKey:KEY_ANNOUNCER_SENDER] boolValue];

	BOOL	newValue = (speakMessages || speakStatus);

        if(newValue != observingContent){
            observingContent = newValue;

            if(!observingContent){ //Stop Observing
                [[owner notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];
            }else{ //Start Observing
                [[owner notificationCenter] addObserver:self selector:@selector(contentObjectAdded:) name:Content_ContentObjectAdded object:nil];
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
	    BOOL isOutgoing = ([source isKindOfClass:[AIAccount class]]);
	    BOOL newParagraph = NO;
	    if ( (isOutgoing  && speakOutgoing) || (!isOutgoing && speakIncoming) ) {
		
		if (speakSender && !isOutgoing) {
		    NSString * senderString;
		    //Get the sender string
		  /*  if(isOutgoing){ //speak outgoing message sender names
			senderString = [[owner accountController] propertyForKey:@"FullName" account:(AIAccount *)source];
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
		
		[theMessage appendFormat:@" %@",message];
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
	    voice = [[owner preferenceController] preferenceForKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER object:otherPerson];
	    
	    pitchNumber = [[owner preferenceController] preferenceForKey:PITCH group:PREF_GROUP_ANNOUNCER object:otherPerson];
	    if(pitchNumber)
		pitch = [pitchNumber floatValue];

	    rateNumber = [[owner preferenceController] preferenceForKey:RATE group:PREF_GROUP_ANNOUNCER object:otherPerson];
	    if(rateNumber)
		rate = [rateNumber intValue];

	    [[owner soundController] speakText:theMessage withVoice:voice andPitch:pitch andRate:rate];
	} else { //must be in a chat room - just speak the message
	[[owner soundController] speakText:theMessage];
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
    voice = [[owner preferenceController] preferenceForKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER object:activeListObject];
    if(voice) {
        [popUp_voice selectItemWithTitle:voice];
    } else {
        [popUp_voice selectItemAtIndex:0]; //"Default"
    }

    pitchNumber = [[owner preferenceController] preferenceForKey:PITCH group:PREF_GROUP_ANNOUNCER object:activeListObject];
    if(pitchNumber) {
	[slider_pitch setFloatValue:[pitchNumber floatValue]];
    } else {
	[slider_pitch setFloatValue:[[owner soundController] defaultPitch]];
    }

    rateNumber = [[owner preferenceController] preferenceForKey:RATE group:PREF_GROUP_ANNOUNCER object:activeListObject];
    if(rateNumber) {
	[slider_rate setIntValue:[rateNumber intValue]];
    } else {
	[slider_rate setIntValue:[[owner soundController] defaultRate]];
    }
}

- (IBAction)changedSetting:(id)sender
{
    if (sender == popUp_voice) {
	NSString * voice = [popUp_voice titleOfSelectedItem];
	if ([voice compare:@"Default"] == 0)
	    voice = nil;
	[[owner preferenceController] setPreference:voice forKey:VOICE_STRING group:PREF_GROUP_ANNOUNCER object:activeListObject];
    } else if (sender == slider_pitch) {
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:[slider_pitch floatValue]] forKey:PITCH group:PREF_GROUP_ANNOUNCER object:activeListObject];
    } else if (sender == slider_rate) {
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[slider_rate intValue]] forKey:RATE group:PREF_GROUP_ANNOUNCER object:activeListObject];
    }
}

@end

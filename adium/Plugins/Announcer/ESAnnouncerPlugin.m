//
//  ESAnnouncerPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESAnnouncerPlugin.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

#define ANNOUNCER_DEFAULT_PREFS @"AnnouncerDefaults.plist"

@interface ESAnnouncerPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation ESAnnouncerPlugin

- (void)installPlugin
{
    //Setup our preferences
    preferences = [[ESAnnouncerPreferences announcerPreferencesWithOwner:owner] retain];
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_SOUNDS];

    observingContent = NO;

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //Initialize our text-to-speech object
    speaker = [[SUSpeaker alloc] init];
}

- (void)uninstallPlugin
{

}

//Called when the preferences change, reregister for the notifications
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
	NSDictionary * dict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
	speakOutgoing = [[dict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue];
	speakIncoming = [[dict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue];
	speakMessages = speakOutgoing || speakIncoming;

	speakStatus = [[dict objectForKey:KEY_ANNOUNCER_STATUS] boolValue];

	speakTime = [[dict objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	speakSender = [[dict objectForKey:KEY_ANNOUNCER_SENDER] boolValue];

	BOOL	newValue = (speakMessages || speakStatus);

        if(newValue != observingContent){
            observingContent = newValue;

            if(!observingContent){ //Stop Announcing
				   //Stop Observing
                [[owner notificationCenter] removeObserver:self name:Content_ContentObjectAdded object:nil];

            }else{ //Start Logging & Update remaining preferences
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
    NSMutableString	*theMessage = [[NSMutableString alloc] init];


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

	    //Determine some basic info about the content
	    BOOL isOutgoing = ([source isKindOfClass:[AIAccount class]]);

	    if ( (isOutgoing  && speakOutgoing) || (!isOutgoing && speakIncoming) ) {

		if (speakSender) {
		    NSString * senderString;
		    //Get the sender string
		    if(isOutgoing){
			senderString = [[owner accountController] propertyForKey:@"FullName" account:(AIAccount *)source];
			if(!senderString || [senderString length] == 0) senderString = [(AIAccount *)source accountDescription];
		    }else{
			senderString = [(AIListContact *)source displayName];
		    }

		    [theMessage appendFormat:@"%@...",senderString];
		}
		
		if (speakTime) {
		    dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
		    [theMessage appendFormat:@" %@...",dateString];
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
	    if (speakTime) {
		dateString = [NSString stringWithFormat:@"%i %i and %i seconds",[date hourOfDay],[date minuteOfHour],[date secondOfMinute]];
		[theMessage appendFormat:@" %@...",dateString];
	    }
	    [theMessage appendFormat:@" %@",message];
	}
    }

    //Speak the message
    if(theMessage != nil){
        [speaker speakText:theMessage];
    }
}
@end

//
//  ESAnnouncerSpeakEventAlertDetailPane.m
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESAnnouncerSpeakEventAlertDetailPane.h"
#import "ESAnnouncerPlugin.h"

@implementation ESAnnouncerSpeakEventAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"AnnouncerSpeakEventContactAlert");    
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	BOOL	speakTime, speakContactName;
	
	if(inDetails){
		speakTime = [[inDetails objectForKey:KEY_ANNOUNCER_TIME] boolValue];
		speakContactName = [[inDetails objectForKey:KEY_ANNOUNCER_SENDER] boolValue];
	}else{
		NSDictionary	*defaults = [[adium preferenceController] preferenceForKey:@"DefaultSpeakEventDetails"
																			  group:PREF_GROUP_ANNOUNCER];
		speakTime = [[defaults objectForKey:KEY_ANNOUNCER_TIME] boolValue];
		speakContactName = [[defaults objectForKey:KEY_ANNOUNCER_SENDER] boolValue];
	}
	
	[checkBox_speakEventTime setState:speakTime];
	[checkBox_speakContactName setState:speakContactName];
	
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSNumber			*speakTime, *speakContactName;
	
	NSMutableDictionary	*actionDetails = [NSMutableDictionary dictionary];
	
	speakTime = [NSNumber numberWithBool:([checkBox_speakEventTime state] == NSOnState)];
	speakContactName = [NSNumber numberWithBool:([checkBox_speakContactName state] == NSOnState)];
	
	[actionDetails setObject:speakTime
					  forKey:KEY_ANNOUNCER_TIME];
	[actionDetails setObject:speakContactName
					  forKey:KEY_ANNOUNCER_SENDER];
	
	//Save the speak time preference for future use
	[[adium preferenceController] setPreference:actionDetails
										 forKey:@"DefaultSpeakEventDetails"
										  group:PREF_GROUP_ANNOUNCER];

	return(actionDetails);
}

@end

//
//  ESAnnouncerSpeakTextAlertDetailPane.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Nov 27 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESAnnouncerSpeakTextAlertDetailPane.h"
#import "ESAnnouncerPlugin.h"

@implementation ESAnnouncerSpeakTextAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"AnnouncerSpeakTextContactAlert");    
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[checkBox_speakEventTime setTitle:SPEAK_EVENT_TIME];
	[textView_textToSpeakLabel setStringValue:AILocalizedString(@"Text To Speak:",nil)];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	NSString *textToSpeak = [inDetails objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	[textView_textToSpeak setString:(textToSpeak ? textToSpeak : @"")];

	BOOL	speakTime;
	
	if(inDetails){
		speakTime = [[inDetails objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	}else{
		speakTime = [[[[adium preferenceController] preferenceForKey:@"DefaultSpeakTextDetails"
															   group:PREF_GROUP_ANNOUNCER] objectForKey:KEY_ANNOUNCER_TIME] boolValue];
	}
	
	[checkBox_speakEventTime setState:speakTime];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSString			*textToSpeak;
	NSNumber			*speakTime;
	NSMutableDictionary	*actionDetails = [NSMutableDictionary dictionary];
	
	textToSpeak  = [[[textView_textToSpeak string] copy] autorelease];
	speakTime = [NSNumber numberWithBool:([checkBox_speakEventTime state] == NSOnState)];
	
	if(textToSpeak){
		[actionDetails setObject:textToSpeak
						  forKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	}
	
	[actionDetails setObject:speakTime
					 forKey:KEY_ANNOUNCER_TIME];

	//Save the speak time preference for future use
	[[adium preferenceController] setPreference:actionDetails
										 forKey:@"DefaultSpeakTextDetails"
										  group:PREF_GROUP_ANNOUNCER];

	return(actionDetails);
}
	
@end

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
	
	[textView_textToSpeakLabel setStringValue:AILocalizedString(@"Text To Speak:",nil)];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	NSString *textToSpeak = [inDetails objectForKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	[textView_textToSpeak setString:(textToSpeak ? textToSpeak : @"")];

	[super configureForActionDetails:inDetails listObject:inObject];
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSString			*textToSpeak;
	NSMutableDictionary	*actionDetails = [NSMutableDictionary dictionary];
	
	textToSpeak  = [[[textView_textToSpeak string] copy] autorelease];
	
	if(textToSpeak){
		[actionDetails setObject:textToSpeak
						  forKey:KEY_ANNOUNCER_TEXT_TO_SPEAK];
	}

	return([self actionDetailsFromDict:actionDetails]);
}
	
- (NSString *)defaultDetailsKey
{
	return @"DefaultSpeakTextDetails";
}

@end

//
//  ESAnnouncerSpeakEventAlertDetailPane.m
//  Adium
//
//  Created by Evan Schoenberg on 12/21/04.
//  Copyright 2004 The Adium Team. All rights reserved.
//

#import "ESAnnouncerSpeakEventAlertDetailPane.h"


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
//[NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]]
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
//		return([NSDictionary dictionaryWithObject:[view_textToSpeak string] forKey:KEY_ANNOUNCER_TEXT_TO_SPEAK]);


	return(nil);
}

@end

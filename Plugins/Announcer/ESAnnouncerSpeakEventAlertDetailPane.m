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

- (NSString *)defaultDetailsKey
{
	return @"DefaultSpeakEventDetails";
}

@end

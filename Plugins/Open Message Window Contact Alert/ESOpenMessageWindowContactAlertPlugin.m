//
//  ESOpenMessageWindowContactAlertPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Sat Nov 29 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESOpenMessageWindowContactAlertPlugin.h"
//#import "ESOpenMessageWindowContactAlert.h"

#define OPEN_MESSAGE_ALERT_SHORT	AILocalizedString(@"Open a message window",nil)
#define OPEN_MESSAGE_ALERT_LONG		OPEN_MESSAGE_ALERT_SHORT

@implementation ESOpenMessageWindowContactAlertPlugin

- (void)installPlugin
{
	[[adium contactAlertsController] registerActionID:@"OpenMessageWindow" withHandler:self];
}


//Open Message Alert ---------------------------------------------------------------------------------------------------
#pragma mark Play Sound Alert
- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(OPEN_MESSAGE_ALERT_SHORT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return(OPEN_MESSAGE_ALERT_LONG);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"WindowAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return(nil);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
	if([listObject isKindOfClass:[AIListContact class]]){
		AIChat	*chat = [[adium contentController] openChatWithContact:(AIListContact *)listObject];
		[[adium interfaceController] setActiveChat:chat];
	}
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return(NO);
}

@end
//
//  NEHGrowlPlugin.m
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "NEHGrowlPlugin.h"
#import <Growl/Growl.h>

#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_EVENT_BEZEL_SHOW_AWAY           AILocalizedString(@"Show While Away",nil)
#define GROWL_ALERT							AILocalizedString(@"Display Growl Notification",nil)

#define GROWL_DEBUG TRUE
 
@interface NEHGrowlPlugin (PRIVATE)
- (NSDictionary *)growlRegistrationDict;
@end

@implementation NEHGrowlPlugin

- (void)installPlugin
{
	//Wait for Adium to finish launching before we perform further actions so all events are registered
	[[adium notificationCenter] addObserver:self
								   selector:@selector(adiumFinishedLaunching:)
									   name:Adium_CompletedApplicationLoad
									 object:nil];	
}

- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[super dealloc];
}

- (void)adiumFinishedLaunching:(NSNotification *)notification
{
	//Now delay one more run loop so any events which are registered on this notification are guaranteed to be complete
	//regardless of the order in which the observers are called
	[self performSelector:@selector(beginGrowling)
			   withObject:nil
			   afterDelay:0.00001];

	[[adium notificationCenter] removeObserver:self
										  name:Adium_CompletedApplicationLoad
										object:nil];
}

- (void)beginGrowling
{
	[GrowlAppBridge setGrowlDelegate:self];

	//Install our contact alert
	[[adium contactAlertsController] registerActionID:@"Growl" withHandler:self];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_EVENT_BEZEL];	
}	

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	showWhileAway = [[prefDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue];
}

#pragma mark AIActionHandler

- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(GROWL_ALERT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return(GROWL_ALERT);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"GrowlAlert" forClass:[self class]]);
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details triggeringEventID:(NSString *)eventID userInfo:(id)userInfo
{
#warning bleh
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && ! showWhileAway)
		return;
	
	NSString		*title, *description;
	NSData			*iconData = nil;
	
	if(listObject){
		if([listObject isKindOfClass:[AIListContact class]]){
			title = [listObject longDisplayName];
		}else{
			title = [listObject formattedUID];
		}
		
		iconData = [listObject userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:listObject
														type:AIServiceIconLarge
												   direction:AIIconNormal] TIFFRepresentation];
		}
	}else{
		if([eventID isEqualToString:CONTENT_MESSAGE_RECEIVED] ||
		   [eventID isEqualToString:CONTENT_MESSAGE_RECEIVED_FIRST] ||
		   [eventID isEqualToString:CONTENT_MESSAGE_SENT]){
			AIChat	*chat = [userInfo objectForKey:@"AIChat"];
			title = [chat name];

		}else{
			title = @"Adium";
		}
	}
	
	description = [[adium contactAlertsController] naturalLanguageDescriptionForEventID:eventID
																			 listObject:listObject
																			   userInfo:userInfo
																		 includeSubject:NO];

	[GrowlAppBridge notifyWithTitle:title
						description:description
				   notificationName:eventID /* Use the same ID as Adium uses to keep things simple */
						   iconData:iconData
						   priority:0
						   isSticky:NO
					   clickContext:[listObject internalObjectID]];
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
    return nil;
}

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}

#pragma mark Growl

- (NSString *)growlAppName
{
	return @"Adium";
}

- (NSDictionary *)growlRegistrationDict
{
	//Register us with Growl
	NSArray *allNotes = [[adium contactAlertsController] allEventIDs];
	
	NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Adium", GROWL_APP_NAME,
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	
	return(growlReg);
}

- (void)growlIsReady
{
#ifdef GROWL_DEBUG
	AILog(@"Growl is go for launch.");
	[GrowlAppBridge notifyWithTitle:@"We have found a witch."
						description:@"May we burn her?"
				   notificationName:@"Account_Connected"
						   iconData:nil
						   priority:0
						   isSticky:YES
					   clickContext:@"The Growl! IT IS READY!"];
#endif
}

- (void)growlNotificationWasClicked:(NSString *)clickContext
{
	NSLog(@"%@ was clicked",clickContext);
}

@end

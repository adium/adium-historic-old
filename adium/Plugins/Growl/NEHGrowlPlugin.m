//
//  NEHGrowlPlugin.m
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "NEHGrowlPlugin.h"
#import "GrowlDefines.h"
#import "GrowlApplicationBridge.h"

#define PREF_GROUP_EVENT_BEZEL              @"Event Bezel"
#define KEY_EVENT_BEZEL_SHOW_AWAY           @"Show While Away"

@implementation NEHGrowlPlugin

- (void)installPlugin
{
	//Set up the events
	events = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"Adium-ContactOnline", CONTACT_STATUS_ONLINE_YES,
				@"Adium-ContactOffline", CONTACT_STATUS_ONLINE_NO,
				@"Adium-ContactAway", CONTACT_STATUS_AWAY_YES,
				@"Adium-ContactUnaway", CONTACT_STATUS_AWAY_NO,
				@"Adium-ContactIdle", CONTACT_STATUS_IDLE_YES,
				@"Adium-ContactUnidle", CONTACT_STATUS_IDLE_NO,
				@"Adium-NewMessage", Content_FirstContentRecieved,
				@"Adium-MessageWhileHidden", Content_DidReceiveContent,
				nil];
	
	//Launch Growl if needed
	[GrowlApplicationBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(registerAdium:) context:NULL];
	
	NSEnumerator * notes = [events keyEnumerator];
	NSString	 * note;
	while(note = [notes nextObject]) {
		[[adium notificationCenter] addObserver:self selector:@selector(handleEvent:) name:note object: nil];
	}
	
	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	
	[self preferencesChanged:nil];
}

- (void)registerAdium:(void*)context
{
	//Register us with Growl
	
	NSArray * objects = [[events objectEnumerator] allObjects];
	NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Adium", GROWL_APP_NAME,
		objects, GROWL_NOTIFICATIONS_ALL,
		objects, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION
																   object:nil
																 userInfo:growlReg];
}

- (void)handleEvent:(NSNotification*)notification
{
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && ! showWhileAway)
		return;
	
	NSString * title;
	NSString * description;
	NSString * message;
	AIListContact * contact;
	NSString * notificationName = [notification name];
	NSString * contactName;
	NSImage  * buddyIcon;
	NSData   * iconData = nil;
	
	//shamlessly ripped from the event bezel :)
	if([notificationName isEqualToString:Content_FirstContentRecieved] ||
		[notificationName isEqualToString:Content_DidReceiveContent]) {
		NSArray *participatingListObjects = [[notification object] participatingListObjects];
		if([participatingListObjects count]){
			contact = [participatingListObjects objectAtIndex:0];
		}else{
			contact = nil;
		}
    } else {
        contact = [notification object];
		if([[contact containingObject] isKindOfClass:[AIMetaContact class]]){
			contact = nil;
		}
    }
	
	if(contact) {
		contactName = [contact longDisplayName];
		
		title = contactName;
		
		if([notificationName isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
			description = AILocalizedString(@"came online","");
		}else if([notificationName isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
			description = AILocalizedString(@"went offline","");
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_YES]) {
			description = AILocalizedString(@"went away","");
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_NO]) {
			description = AILocalizedString(@"is available","");
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_YES]) {
			description = AILocalizedString(@"is idle","");
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_NO]) {
			description = AILocalizedString(@"is no longer idle","");
		}else if([notificationName isEqualToString: Content_FirstContentRecieved]){
			message = [[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] string];
			description = [NSString stringWithFormat: AILocalizedString(@"%@","New content notification"), message];
		}else if([notificationName isEqualToString: Content_DidReceiveContent]) {
			if(![NSApp isHidden])
				return;
			message = [[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] string];
			description = [NSString stringWithFormat: AILocalizedString(@"%@","Message notification while hidden"), message];
		}else{
			description = @"OMGWTFBBQ!";
		}

		iconData = [contact userIconData];
		
		NSDictionary * growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
										title, GROWL_NOTIFICATION_TITLE,
										description, GROWL_NOTIFICATION_DESCRIPTION,
										@"Adium", GROWL_APP_NAME,
										iconData, GROWL_NOTIFICATION_ICON,
										nil];
	
		[[NSDistributedNotificationCenter defaultCenter]
										postNotificationName: [events objectForKey: notificationName]
													  object: nil
													userInfo: growlEvent
										  deliverImmediately: NO];
		
	}
}

- (void)preferencesChanged:(NSNotification*)notification
{
	if (notification == nil ||  [(NSString*)[[notification userInfo] objectForKey:@"Group"] isEqualToString:PREF_GROUP_EVENT_BEZEL]) {
		showWhileAway = [[[adium preferenceController] preferenceForKey:KEY_EVENT_BEZEL_SHOW_AWAY group:PREF_GROUP_EVENT_BEZEL] boolValue];
	}
}


@end

//
//  NEHGrowlPlugin.m
//  Adium
//
//  Created by Nelson Elhage on Sat May 29 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "NEHGrowlPlugin.h"
#import "GrowlDefines.h"


@implementation NEHGrowlPlugin

- (void)installPlugin
{
	//Set up the events and titles
	events = [[NSDictionary dictionaryWithObjectsAndKeys:
				AILocalizedString(@"Contact came online",nil), CONTACT_STATUS_ONLINE_YES,
				AILocalizedString(@"Contact went offline",nil), CONTACT_STATUS_ONLINE_NO,
				AILocalizedString(@"Contact has gone away",nil), CONTACT_STATUS_AWAY_YES,
				AILocalizedString(@"Contact is available",nil), CONTACT_STATUS_AWAY_NO,
				AILocalizedString(@"Contact is idle",nil), CONTACT_STATUS_IDLE_YES,
				AILocalizedString(@"Contact is no longer idle",nil), CONTACT_STATUS_IDLE_NO,
				AILocalizedString(@"New Message received",nil), Content_FirstContentRecieved,
				nil] retain];
	
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
	
	NSEnumerator * notes = [events keyEnumerator];
	NSString	 * note;
	while(note = [notes nextObject]) {
		[[adium notificationCenter] addObserver:self selector:@selector(handleEvent:) name:note object: nil];
	}
}

- (void)handleEvent:(NSNotification*)notification
{
	NSString * title;
	NSString * message;
	AIListContact * contact;
	NSString * notificationName = [notification name];
	NSString * contactName;
	NSImage  * buddyIcon;
	
	//shamlessly ripped from the event bezel :)
	if([notificationName isEqualToString:Content_FirstContentRecieved]) {
		NSArray *participatingListObjects = [[notification object] participatingListObjects];
		if([participatingListObjects count]){
			contact = [participatingListObjects objectAtIndex:0];
		}else{
			contact = nil;
		}
    } else {
        contact = [notification object];
		if([[contact containingGroup] isKindOfClass:[AIMetaContact class]]){
			contact = nil;
		}
    }
	
	if(contact) {
		contactName = [contact longDisplayName];
		
		if([notificationName isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ came online",nil),
									contactName];
		}else if([notificationName isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ went offline",nil),
				contactName];
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_YES]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ went away",nil),
				contactName];
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_NO]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ is available",nil),
				contactName];
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_YES]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ is idle",nil),
				contactName];
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_NO]) {
			message = title = [NSString stringWithFormat: AILocalizedString(@"%@ is no longer idle",nil),
				contactName];
		}else if([notificationName isEqualToString: Content_FirstContentRecieved]) {
			title = [NSString stringWithFormat: AILocalizedString(@"New message from %@",nil),
				contactName];
			message = [[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] string];
		}
		
		buddyIcon = [[contact displayArrayForKey:@"UserIcon"] objectValue];
		if(!buddyIcon){
			buddyIcon = [NSImage imageNamed: @"DefaultIcon"];
		}
		
		NSDictionary * growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
										title, GROWL_NOTIFICATION_TITLE,
										message, GROWL_NOTIFICATION_DESCRIPTION,
										@"Adium", GROWL_APP_NAME,
										[buddyIcon TIFFRepresentation], GROWL_NOTIFICATION_ICON,
										nil];
		
		[[NSDistributedNotificationCenter defaultCenter]
										postNotificationName: [events objectForKey: notificationName]
													  object: nil
													userInfo: growlEvent
										  deliverImmediately: NO];
		
	}
}


@end

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
#define KEY_EVENT_BEZEL_SHOW_AWAY           AILocalizedString(@"Show While Away",nil)
#define GROWL_ALERT							AILocalizedString(@"Show Growl Notification",nil)

@implementation NEHGrowlPlugin

- (void)installPlugin
{
	//Set up the events
	events = [[NSDictionary alloc] initWithObjectsAndKeys:
				@"Contact Signed On", CONTACT_STATUS_ONLINE_YES,
				@"Contact Signed Off", CONTACT_STATUS_ONLINE_NO,
				@"Contact Went Away", CONTACT_STATUS_AWAY_YES,
				@"Contact Is Available", CONTACT_STATUS_AWAY_NO,
				@"Contact Went Idle", CONTACT_STATUS_IDLE_YES,
				@"Contact Is No Longer Idle", CONTACT_STATUS_IDLE_NO,
				@"New Message Received", Content_FirstContentRecieved,
				@"Message Received while hidden", Content_DidReceiveContent,
				nil];
	
	//Launch Growl if needed
	[GrowlApplicationBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(registerAdium:) context:NULL];
	
	NSEnumerator * notes = [events keyEnumerator];
	NSString	 * note;
	while(note = [notes nextObject]) {
		[[adium notificationCenter] addObserver:self selector:@selector(handleEvent:) name:note object: nil];
	}
	
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"Growl" withHandler:self];

	[[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
	
	[self preferencesChanged:nil];
}

- (void)dealloc
{
	[events release];
	[super dealloc];
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
	
	NSString		*title;
	NSString		*description;
	NSString		*message;
	AIListContact	*contact;
	NSString		*notificationName = [notification name];
	NSString		*contactName;
	NSData			*iconData = nil;
	
	//shamlessly ripped from the event bezel :)
	if([notificationName isEqualToString:Content_FirstContentRecieved] ||
		[notificationName isEqualToString:Content_DidReceiveContent]) {

		contact = [[notification object] listObject];

    } else {
        contact = [notification object];
		
		//Don't show the bezel for a status change of a metaContact-contained object, 
		//as the metaContact will provide a better status notification
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
			message = [[[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] safeString] string];
			description = [NSString stringWithFormat: AILocalizedString(@"%@","New content notification"), message];
		}else if([notificationName isEqualToString: Content_DidReceiveContent]) {
			if(![NSApp isHidden])
				return;
			message = [[[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] safeString] string];
			description = [NSString stringWithFormat: AILocalizedString(@"%@","Message notification while hidden"), message];
		}else{
			description = @"OMGWTFBBQ!";
		}

		iconData = [contact userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:contact
					type:AIServiceIconLarge
					direction:AIIconNormal] TIFFRepresentation];
		}
		
		NSDictionary * growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
										[events objectForKey: notificationName], GROWL_NOTIFICATION_NAME,
										title, GROWL_NOTIFICATION_TITLE,
										description, GROWL_NOTIFICATION_DESCRIPTION,
										@"Adium", GROWL_APP_NAME,
										iconData, GROWL_NOTIFICATION_ICON,
										nil];
	
		[[NSDistributedNotificationCenter defaultCenter]
										postNotificationName: GROWL_NOTIFICATION
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
    [self handleEvent:[NSNotification notificationWithName:eventID object:listObject]];
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
    return nil;
}
@end

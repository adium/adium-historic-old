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

#define	GROWL_CONTACT_SIGNON				@"Contact Signed On"
#define GROWL_CONTACT_SIGNOFF				@"Contact Signed Off"
#define GROWL_CONTACT_AWAY					@"Contact Went Away"
#define GROWL_CONTACT_UNAWAY				@"Contact Is Available"
#define GROWL_CONTACT_IDLE					@"Contact Went Idle"
#define GROWL_CONTACT_UNIDLE				@"Contact Is No Longer Idle"
#define GROWL_FIRST_MESSAGE					@"New Message Received"
#define GROWL_HIDDEN_MESSAGE				@"Message received while hidden"
#define GROWL_BACKGROUND_MESSAGE			@"Message received while in background"
#define GROWL_FT_REQUEST					@"File Transfer Requested"
#define GROWL_FT_BEGAN						@"File Transfer Began"
#define GROWL_FT_CANCELED					@"File Transfer Canceled"
#define GROWL_FT_COMPLETE					@"File Transfer Complete"

//-------------------------------------------------------------------
//In order to add another notification to this plugin:
// - Add a define right above this block so you can easily refer to its Growl name
// - If the notification maps to an Adium notification, add that to the events array in -installPlugin
// - Add it to the arrays in -(void)registerAdium:
//		- You must add it to allNotes if it is to be displayed
//		- Add it to defNotes only if it should be enabled in the growl Prefpane by default
// - Add a case for it in the if chain in -(void)handleEvent:
//		- set title to an appropriate title (If unset, it will be the name of the contact for the notification, if applicable)
//		- set description to the description
//		- set note to the name of your notification (one of the defines)

@implementation NEHGrowlPlugin

- (void)installPlugin
{
	NSString		*note;
	NSEnumerator	*enumerator;
	
	//Set up the events
	NSArray	* events = [NSArray arrayWithObjects:
									CONTACT_STATUS_ONLINE_YES,
									CONTACT_STATUS_ONLINE_NO,
									CONTACT_STATUS_AWAY_YES,
									CONTACT_STATUS_AWAY_NO,
									CONTACT_STATUS_IDLE_YES,
									CONTACT_STATUS_IDLE_NO,
									Content_FirstContentRecieved,
									Content_DidReceiveContent,
									FILE_TRANSFER_REQUEST,
									FILE_TRANSFER_BEGAN,
									FILE_TRANSFER_CANCELED,
									FILE_TRANSFER_COMPLETE,
									nil];
	
	//Launch Growl if needed
	[GrowlApplicationBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(registerAdium:) context:NULL];
	
	enumerator = [events objectEnumerator];
	while(note = [enumerator nextObject]) {
		[[adium notificationCenter] addObserver:self selector:@selector(handleEvent:) name:note object:nil];
	}
	
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"Growl" withHandler:self];

	[[adium notificationCenter] addObserver:self 
								   selector:@selector(preferencesChanged:) 
									   name:Preference_GroupChanged
									 object:nil];
	
	[self preferencesChanged:nil];
}

- (void)dealloc
{
	[super dealloc];
}

- (void)registerAdium:(void*)context
{
	//Register us with Growl
	
	NSArray * allNotes = [NSArray arrayWithObjects:
									GROWL_CONTACT_SIGNON,
									GROWL_CONTACT_SIGNOFF,
									GROWL_CONTACT_AWAY,
									GROWL_CONTACT_UNAWAY,
									GROWL_CONTACT_IDLE,
									GROWL_CONTACT_UNIDLE,
									GROWL_FIRST_MESSAGE,
									GROWL_HIDDEN_MESSAGE,
									GROWL_BACKGROUND_MESSAGE,
									GROWL_FT_REQUEST,
									GROWL_FT_BEGAN,
									GROWL_FT_CANCELED,
									GROWL_FT_COMPLETE,
									nil];
	
	//Set which notes are enabled by default
	NSArray	* defNotes = [NSArray arrayWithObjects:
									GROWL_CONTACT_SIGNON,
									GROWL_CONTACT_SIGNOFF,
									GROWL_CONTACT_AWAY,
									GROWL_CONTACT_UNAWAY,
									GROWL_CONTACT_IDLE,
									GROWL_CONTACT_UNIDLE,
									GROWL_FIRST_MESSAGE,
									GROWL_BACKGROUND_MESSAGE,
									//GROWL_HIDDEN_MESSAGE,
									GROWL_FT_REQUEST,
									GROWL_FT_BEGAN,
									GROWL_FT_CANCELED,
									GROWL_FT_COMPLETE,
									nil];
		
	NSDictionary * growlReg = [NSDictionary dictionaryWithObjectsAndKeys:
		@"Adium", GROWL_APP_NAME,
		allNotes, GROWL_NOTIFICATIONS_ALL,
		defNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION
																   object:nil
																 userInfo:growlReg];
}

- (void)handleEvent:(NSNotification*)notification
{
	if([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && ! showWhileAway)
		return;
	
	NSString		*note;
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
			note = GROWL_CONTACT_SIGNON;
		}else if([notificationName isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
			description = AILocalizedString(@"went offline","");
			note = GROWL_CONTACT_SIGNOFF;
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_YES]) {
			description = AILocalizedString(@"went away","");
			note = GROWL_CONTACT_AWAY;
		}else if([notificationName isEqualToString: CONTACT_STATUS_AWAY_NO]) {
			description = AILocalizedString(@"is available","");
			note = GROWL_CONTACT_UNAWAY;
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_YES]) {
			description = AILocalizedString(@"is idle","");
			note = GROWL_CONTACT_IDLE;
		}else if([notificationName isEqualToString: CONTACT_STATUS_IDLE_NO]) {
			description = AILocalizedString(@"is no longer idle","");
			note = GROWL_CONTACT_UNIDLE;
		}else if([notificationName isEqualToString: Content_FirstContentRecieved]){
			message = [[[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] safeString] string];
			description = [NSString stringWithFormat: AILocalizedString(@"%@","New content notification"), message];
			note = GROWL_FIRST_MESSAGE;
		}else if([notificationName isEqualToString: Content_DidReceiveContent]) {
			
			message = [[[(AIContentObject*)[[notification userInfo] objectForKey:@"Object"] message] safeString] string];
			if(![NSApp isActive]) {
				if([NSApp isHidden])
					description = [NSString stringWithFormat: AILocalizedString(@"%@","Message notification while hidden"), message];
				else
					description = [NSString stringWithFormat: AILocalizedString(@"%@","Message notification while in background"), message];
			} else {
				return;
			}
			note = GROWL_HIDDEN_MESSAGE;
		}else if([notificationName isEqualToString: FILE_TRANSFER_REQUEST]) {
			description = AILocalizedString(@"wants to send you a file","");
			note = GROWL_FT_REQUEST;
		}else if([notificationName isEqualToString: FILE_TRANSFER_BEGAN]) {
			description = AILocalizedString(@"began a file transfer","");
			note = GROWL_FT_BEGAN;
		}else if([notificationName isEqualToString: FILE_TRANSFER_CANCELED]) {
			description = AILocalizedString(@"canceled a file transfer","");
			note = GROWL_FT_CANCELED;
		}else if([notificationName isEqualToString: FILE_TRANSFER_COMPLETE]) {
			description = AILocalizedString(@"completed a file transfer","");
			note = GROWL_FT_COMPLETE;
		}else{
			NSLog(@"Unknown notification: %@",notificationName);
			return;
		}

		iconData = [contact userIconData];
		
		if (!iconData) {
			iconData = [[AIServiceIcons serviceIconForObject:contact
					type:AIServiceIconLarge
					direction:AIIconNormal] TIFFRepresentation];
		}
		
		NSDictionary * growlEvent = [NSDictionary dictionaryWithObjectsAndKeys:
										note, GROWL_NOTIFICATION_NAME,
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

- (BOOL)allowMultipleActionsWithID:(NSString *)actionID
{
	return NO;
}
@end

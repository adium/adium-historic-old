//
//  JSCEventBezelPlugin.m
//  Adium
//
//  Created by Jorge Salvador Caffarena.
//  Copyright (c) 2003 All rights reserved.
//

#import "JSCEventBezelPlugin.h"
#import "JSCEventBezelPreferences.h"
#import "AIContactStatusColoringPlugin.h"
//#import "ESEventBezelContactAlert.h"

#define CONTACT_BEZEL_NIB   @"ContactEventBezel"
#define EVENT_BEZEL_ALERT   @"Show Event Notification Window"

@interface JSCEventBezelPlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (void)processBezelForNotification:(NSNotification *)notification;
@end

@implementation JSCEventBezelPlugin

- (void)installPlugin
{
    //Install our contact alert
	[[adium contactAlertsController] registerActionID:@"ShowEventBezel" withHandler:self];

    //Register our default preferences
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:EVENT_BEZEL_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_EVENT_BEZEL];
    
    //Our preference view
    preferences = [[JSCEventBezelPreferences preferencePane] retain];
    
    // Setup the controller
    ebc = [JSCEventBezelController eventBezelController];
    
    eventArray = [[NSMutableArray alloc] init];
    
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_ONLINE_YES
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_ONLINE_NO
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_AWAY_YES
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_AWAY_NO
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_IDLE_YES
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:CONTACT_STATUS_IDLE_NO
                                     object:nil];
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(eventNotification:)
                                       name:Content_FirstContentRecieved
                                     object:nil];
        
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_BEZEL_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Event Bezel" categoryName:@"None" view:view_contactBezelInfoView delegate:self] retain];
    [[adium contactController] addContactInfoView:contactView];
    
    
    //Install our contact alert
//	[[adium contactAlertsController] registerActionID:@"EventBezel" withHandler:self];
	
    //watch preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    //set up preferences initially
    [self preferencesChanged:nil];
}

- (void)uninstallPlugin
{
    //Uninstall our contact alert
//    [[adium contactAlertsController] unregisterContactAlertProvider:self];
}

- (void)dealloc
{
    [ebc release];
    [preferences release];
    [super dealloc];
}

//
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_EVENT_BEZEL] == 0){
        NSDictionary    *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
        
        showEventBezel = [[preferenceDict objectForKey:KEY_SHOW_EVENT_BEZEL] boolValue];
        
        [ebc setBezelDuration: [[preferenceDict objectForKey:KEY_EVENT_BEZEL_DURATION] intValue]];
        ignoreClicks = [[preferenceDict objectForKey:KEY_EVENT_BEZEL_IGNORE_CLICKS] boolValue];
		
        [eventArray removeAllObjects];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_FIRST_MESSAGE] boolValue])
            [eventArray addObject:Content_FirstContentRecieved];                
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_ONLINE] boolValue])
            [eventArray addObject:CONTACT_STATUS_ONLINE_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_OFFLINE] boolValue])
            [eventArray addObject:CONTACT_STATUS_ONLINE_NO];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_AWAY] boolValue])
            [eventArray addObject:CONTACT_STATUS_AWAY_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_AVAILABLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_AWAY_NO];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_IDLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_IDLE_YES];
        if ([[preferenceDict objectForKey:KEY_EVENT_BEZEL_NO_IDLE] boolValue])
            [eventArray addObject:CONTACT_STATUS_IDLE_NO];   
    }
}

- (void)eventNotification:(NSNotification *)notification
{
    if (showEventBezel && [eventArray containsObject:[notification name]]) {
        [self processBezelForNotification:notification];
    }
}

- (void)processBezelForNotification:(NSNotification *)notification 
{
    AIListContact               *contact;
    BOOL                        isFirstMessage = NO;
    NSString                    *notificationName = [notification name];
    NSString                    *tempEvent = nil;
    NSImage                     *tempBuddyIcon = nil;
    NSString                    *statusMessage = nil;
    NSDictionary                *preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_EVENT_BEZEL];
    NSDictionary                *colorPreferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];
    
    if ([notificationName isEqualToString:Content_FirstContentRecieved]) {
		NSArray *participatingListObjects = [[notification object] participatingListObjects];
		if ([participatingListObjects count]){
			contact = [participatingListObjects objectAtIndex:0];
			isFirstMessage = YES;
		}else{
			contact = nil;
		}
    } else {
        contact = [notification object];
    }
    
	if (contact){
		//Check to be sure bezel for contact and for its group is enabled
		NSNumber *contactDisabledNumber = [contact preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL];
		//NSNumber *groupDisabledNumber = [[contact containingGroup] preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL];
		BOOL contactEnabled = !contactDisabledNumber || (![contactDisabledNumber boolValue]);
		//BOOL groupEnabled = !groupDisabledNumber || (![groupDisabledNumber boolValue]);
		// If Adium is hidden, check if we want it to show (and unhide Adium in the process)
		BOOL showIfHidden = ![NSApp isHidden] || ([NSApp isHidden] && [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_HIDDEN] boolValue]);
		// If you are away, check if we want it to show
		BOOL showIfAway = ![[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS]
			|| ([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] && [[preferenceDict objectForKey:KEY_EVENT_BEZEL_SHOW_AWAY] boolValue]);
		
		if (contactEnabled && /*groupEnabled &&*/ showIfHidden && showIfAway){
			if ([NSApp isHidden]) {
				[NSApp unhideWithoutActivation];
			}
			
			if (isFirstMessage) {
				AIContentMessage    *contentMessage = [[notification userInfo] objectForKey:@"Object"];
				statusMessage = [[[contentMessage message] safeString] string];
			} else {
				// If it is a status change, show status message
				// Not working
				/*ownerArray = [contact statusArrayForKey: @"StatusMessage"];
				if (ownerArray && [ownerArray count]) {
					statusMessage = [ownerArray objectAtIndex: 0];
				}
				if (statusMessage) {
				} else {
				}*/
			}
			
			if ([notificationName isEqualToString: CONTACT_STATUS_ONLINE_YES]) {
				tempEvent = AILocalizedString(@"is now online",nil);
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: CONTACT_STATUS_ONLINE_NO]) {
				tempEvent = AILocalizedString(@"has gone offline",nil);
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: CONTACT_STATUS_AWAY_YES]) {
				tempEvent = AILocalizedString(@"has gone away",nil);
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: CONTACT_STATUS_AWAY_NO]) {
				tempEvent = AILocalizedString(@"is available",nil);
				#warning Jorge: Here would be nice to have a check on the contact status and color accordingly
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: CONTACT_STATUS_IDLE_YES]) {
				tempEvent = AILocalizedString(@"is idle",nil);
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: CONTACT_STATUS_IDLE_NO]) {
				tempEvent = AILocalizedString(@"is no longer idle",nil);
				#warning Jorge: Here would be nice to have a check on the contact status and color accordingly
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
			} else if ([notificationName isEqualToString: Content_FirstContentRecieved]) {
				tempEvent = AILocalizedString(@"new message",nil);
				[ebc setBuddyIconLabelColor: [[colorPreferenceDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor]];
				[ebc setBuddyNameLabelColor: [[colorPreferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
			}
			
			tempBuddyIcon = [[[contact displayArrayForKey:@"UserIcon"] objectValue] retain];
			if (!tempBuddyIcon) {
				tempBuddyIcon = [[NSImage imageNamed: @"DefaultIcon"] retain];
			}
			[ebc showBezelWithContact: [contact longDisplayName]
							withImage: tempBuddyIcon
							 forEvent: tempEvent
					   ignoringClicks: ignoreClicks];
			[tempBuddyIcon release];
		}
	}
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSNumber *contactDisableBezel;
    //Hold onto the object
    [activeListObject release]; activeListObject = nil;
    activeListObject = [inObject retain];
    
    contactDisableBezel = [activeListObject preferenceForKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL];
    if (contactDisableBezel)
        [checkBox_disableBezel setState:[contactDisableBezel boolValue]];
    else
        [checkBox_disableBezel setState:NO];
}

- (IBAction)changedSetting:(id)sender
{
    if (sender == checkBox_disableBezel) {
        [activeListObject setPreference:[NSNumber numberWithBool:[checkBox_disableBezel state]] forKey:CONTACT_DISABLE_BEZEL group:PREF_GROUP_EVENT_BEZEL];
    }
}

#pragma mark Event Notification Alert

- (NSString *)shortDescriptionForActionID:(NSString *)actionID
{
	return(EVENT_BEZEL_ALERT);
}

- (NSString *)longDescriptionForActionID:(NSString *)actionID withDetails:(NSDictionary *)details
{
	return(EVENT_BEZEL_ALERT);
}

- (NSImage *)imageForActionID:(NSString *)actionID
{
	return([NSImage imageNamed:@"BezelAlert" forClass:[self class]]);
}

- (AIModularPane *)detailsPaneForActionID:(NSString *)actionID
{
	return nil;
}

- (void)performActionID:(NSString *)actionID forListObject:(AIListObject *)listObject withDetails:(NSDictionary *)details
{
	// Display the Event Notification
}

//        NSString * ContactStatusString = nil;
//        if ([event isEqualToString:@"Signed On"]) {
//            ContactStatusString = CONTACT_STATUS_ONLINE_YES;
//        } else  if ([event isEqualToString:@"Signed Off"]) {
//            ContactStatusString = CONTACT_STATUS_ONLINE_NO;
//        } else {
//            if (event_status) { //positive
//                if ([event isEqualToString:@"Away"]) {
//                    ContactStatusString = CONTACT_STATUS_AWAY_YES;
//                } else if ([event isEqualToString:@"Idle"]) {
//                    ContactStatusString = CONTACT_STATUS_IDLE_YES;
//                }
//            } else {
//                if ([event isEqualToString:@"Away"]) {
//                    ContactStatusString = CONTACT_STATUS_AWAY_NO;
//                } else if ([event isEqualToString:@"Idle"]) {
//                    ContactStatusString = CONTACT_STATUS_IDLE_NO;
//                }
//            }
//        }
//        
//        if (ContactStatusString) {
//            if (!showEventBezel || (![eventArray containsObject:ContactStatusString])) {
//                [self processBezelForNotification:[NSNotification notificationWithName:ContactStatusString object:inObject]];
//                return YES;
//            }
//        }
//        return NO;

	
@end

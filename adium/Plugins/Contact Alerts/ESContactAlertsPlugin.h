//
//  ESContactAlertsPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "SUSpeaker.h"

#define PREF_GROUP_ALERTS		@"Alerts"
#define	KEY_EVENT_NOTIFICATION		@"Notification"
#define KEY_EVENT_ACTION		@"Action"
#define KEY_EVENT_ACTIONSET		@"Contact Actions"
#define KEY_EVENT_DETAILS		@"Details"
#define KEY_EVENT_PATH			@"Path"
#define KEY_EVENT_STATUS		@"Status"
#define KEY_EVENT_DISPLAYNAME		@"Display Name"
#define KEY_EVENT_DELETE		@"Delete"
#define KEY_EVENT_DETAILS_UNIQUE	@"Unique Details"


#define KEY_EVENT_DETAILS_DICT		@"Details Dictionary"
#define KEY_MESSAGE_SENDTO_UID		@"Destination UID"
#define KEY_MESSAGE_SENDTO_SERVICE	@"Destination Service"
#define KEY_MESSAGE_SENDFROM		@"Account ID"
#define KEY_MESSAGE_OTHERACCOUNT	@"Allow Other"
#define KEY_MESSAGE_ERROR		@"Display Error"

#define PREF_GROUP_SOUNDS		@"Sounds"

#define SOUND_EVENT_START		@"\nSoundset:\n"	//String marking start of event list
#define SOUND_EVENT_QUOTE		@"\""			//Character before and after event name
#define SOUND_NEWLINE			@"\n"			//Newline character

#define KEY_EVENT_SOUND_SET		@"Event Sound Set"
#define	KEY_EVENT_SOUND_PATH		@"Path"
#define	KEY_EVENT_SOUND_NOTIFICATION	@"Notification"

#define Pref_Changed_Alerts		@"Alerts Changed in Pref Pane"
#define Window_Changed_Alerts		@"Alerts Changed in Window"
#define One_Time_Event_Fired 		@"One Time Event Fired"

@protocol AIMiniToolbarItemDelegate;
@protocol AIListObjectObserver;
@class ESContactAlertsPlugin;
@class ESContactAlertsPreferences;

@interface ESContactAlertsPlugin : AIPlugin <AIMiniToolbarItemDelegate,AIListObjectObserver> {
    NSMenuItem				*editContactAlertsMenuItem;
    NSMenuItem				*contactAlertsContextMenuItem;
    ESContactAlertsPreferences		*prefs;

    SUSpeaker 				*speaker;
}

@end

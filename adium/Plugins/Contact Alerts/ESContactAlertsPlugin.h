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
#define KEY_EVENT_ACTIONSET		@"Contact Actions"	//storage of a set of events and associated actions

#define	KEY_EVENT_NOTIFICATION		@"Notification"  	//event, actually
#define KEY_EVENT_ACTION		@"Action"		//actions to take
#define KEY_EVENT_DETAILS		@"Details"		//details (text, path, etc.)
#define KEY_EVENT_STATUS		@"Status"		//allows for inverse events (came back from away, etc.)
#define KEY_EVENT_DISPLAYNAME		@"Display Name"		//display name of the event
#define KEY_EVENT_DELETE		@"Delete"		//delete after execution?
#define KEY_EVENT_ACTIVE		@"Only While Active"

#define KEY_EVENT_DETAILS_UNIQUE	@"Unique Details"	//just used for UI purposes

#define KEY_EVENT_DETAILS_DICT		@"Details Dictionary"	//additional options' storage
#define KEY_MESSAGE_SENDTO_UID		@"Destination UID"
#define KEY_MESSAGE_SENDTO_SERVICE	@"Destination Service"
#define KEY_MESSAGE_SENDFROM		@"Account ID"
#define KEY_MESSAGE_OTHERACCOUNT	@"Allow Other"		//allow other account
#define KEY_MESSAGE_ERROR		@"Display Error"


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

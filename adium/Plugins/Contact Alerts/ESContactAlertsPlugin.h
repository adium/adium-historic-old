//
//  ESContactAlertsPlugin.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Jul 14 2003.
//

#define KEY_EVENT_ACTIONSET		@"Contact Actions"	//storage of a set of events and associated actions

#define	KEY_EVENT_NOTIFICATION		@"Notification"  	//event, actually
#define KEY_EVENT_ACTION		@"Action"		//actions to take
#define KEY_EVENT_DETAILS		@"Details"		//details (text, path, etc.)
#define KEY_EVENT_STATUS		@"Status"		//allows for inverse events (came back from away, etc.)
#define KEY_EVENT_DISPLAYNAME		@"Display Name"		//display name of the event
#define KEY_EVENT_DELETE		@"Delete"		//delete after execution?
#define KEY_EVENT_ACTIVE		@"Only While Active"

//#define KEY_EVENT_DETAILS_UNIQUE	@"Unique Details"	//just used for UI purposes

#define KEY_EVENT_DETAILS_DICT		@"Details Dictionary"	//additional options storage


#define Window_Changed_Alerts		@"Alerts Changed in Window"
#define One_Time_Event_Fired 		@"One Time Event Fired"

@protocol AIMiniToolbarItemDelegate;
@class ESContactAlertsPlugin;

@interface ESContactAlertsPlugin : AIPlugin <AIMiniToolbarItemDelegate> {
    NSMenuItem				*editContactAlertsMenuItem;
    NSMenuItem				*contactAlertsContextMenuItem;
    
    BOOL                                processedForUser;
}

@end

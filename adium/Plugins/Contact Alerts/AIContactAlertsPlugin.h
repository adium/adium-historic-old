//
//  AIContactAlertsPlugin.h
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
#define KEY_EVENT_STATUS		@"Status"
#define KEY_EVENT_DISPLAYNAME		@"Display Name"

#define PREF_GROUP_SOUNDS		@"Sounds"

#define SOUND_EVENT_START		@"\nSoundset:\n"	//String marking start of event list
#define SOUND_EVENT_QUOTE		@"\""			//Character before and after event name
#define SOUND_NEWLINE			@"\n"			//Newline character

#define KEY_EVENT_SOUND_SET		@"Event Sound Set"
#define	KEY_EVENT_SOUND_PATH		@"Path"
#define	KEY_EVENT_SOUND_NOTIFICATION	@"Notification"


@protocol AIMiniToolbarItemDelegate;
@protocol AIListObjectObserver;

@interface AIContactAlertsPlugin : AIPlugin <AIMiniToolbarItemDelegate,AIListObjectObserver> {
    NSMenuItem				*editContactAlertsMenuItem;
    NSMenuItem				*contactAlertsContextMenuItem;
    SUSpeaker 				*speaker;
}

@end

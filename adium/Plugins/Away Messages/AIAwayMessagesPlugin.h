//
//  AIAwayMessagesPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define PREF_GROUP_AWAY_MESSAGES 			@"Away Messages"
#define KEY_SAVED_AWAYS					@"Saved Aways"

@class AIAwayMessagePreferences;

@interface AIAwayMessagesPlugin : AIPlugin {
    AIAwayMessagePreferences	*preferences;

    NSMenuItem			*menuItem_away;
    NSMenuItem			*menuItem_removeAway;
    NSMenuItem			*menuItem_customMessage;
    NSMenu			*menu_awaySubmenu;

    BOOL			menuConfiguredForAway;

    NSMutableArray		*receivedAwayMessage;
}

- (void)installPlugin;
- (IBAction)enterAwayMessage:(id)sender;
- (IBAction)removeAwayMessage:(id)sender;

@end

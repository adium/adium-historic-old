//
//  AIAwayMessagesPlugin.h
//  Adium
//
//  Created by Adam Iser on Sun Jan 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

#define PREF_GROUP_AWAY_MESSAGES 	@"Away Messages"

@class AIAwayMessagePreferences;

@interface AIAwayMessagesPlugin : AIPlugin/*<AIPreferenceViewControllerDelegate>*/ {

    AIAwayMessagePreferences	*preferences;

    NSMenuItem			*menuItem_away;
    NSMenuItem			*menuItem_removeAway;
    NSMenuItem			*menuItem_customMessage;
    NSMenu			*menu_awaySubmenu;

    BOOL			menuConfiguredForAway;
}

- (void)installPlugin;
- (IBAction)enterAwayMessage:(id)sender;
- (IBAction)removeAwayMessage:(id)sender;

@end

//
//  AIAwayStatusWindowPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue May 27 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAwayStatusWindowPlugin.h"
#import "AIAwayStatusWindowController.h"
#import "AIAwayStatusWindowPreferences.h"

@interface AIAwayStatusWindowPlugin (PRIVATE)
- (void)accountStatusChanged:(NSNotification *)notification;
@end

@implementation AIAwayStatusWindowPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:AWAY_STATUS_DEFAULT_PREFS forClass:[self class]] forGroup:PREF_GROUP_AWAY_STATUS_WINDOW];

    //Our preference view
    preferences = [[AIAwayStatusWindowPreferences awayStatusWindowPreferencesWithOwner:owner] retain];

    //Observe
    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];
//    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Open an away status window if we woke up away
    if([[owner accountController] statusObjectForKey:@"AwayMessage" account:nil]) {
        // Get an away status window
        [AIAwayStatusWindowController awayStatusWindowControllerForOwner:owner];
        // Tell it to update in case we were already away
        [AIAwayStatusWindowController updateAwayStatusWindow];
    }    

    [self accountStatusChanged:nil];
}

//Update our away window when the away status changes
- (void)accountStatusChanged:(NSNotification *)notification
{
    if(notification == nil || [notification object] == nil){ //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];

        if([modifiedKey compare:@"AwayMessage"] == 0){
            // Get an away status window
            [AIAwayStatusWindowController awayStatusWindowControllerForOwner:owner];
            // Tell it to update
            [AIAwayStatusWindowController updateAwayStatusWindow];
        }
    }
}

//Update our window when the prefs change
/*- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_AWAY_STATUS_WINDOW] == 0){
        // Get an away status window
        [AIAwayStatusWindowController awayStatusWindowControllerForOwner:owner];
        // Tell it to update in case we were already away
        [AIAwayStatusWindowController updateAwayStatusWindow];

    }
}*/
    

@end






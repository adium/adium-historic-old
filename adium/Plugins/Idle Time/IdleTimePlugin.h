//
//  Idle Time.h
//  Adium
//
//  Created by Greg Smith on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>


#define IDLE_TIME_DEFAULT_PREFERENCES	@"IdleDefaultPrefs"

#define PREF_GROUP_IDLE_TIME			@"Idle"
#define KEY_IDLE_TIME_ENABLED		@"Idle Enabled"
#define KEY_IDLE_TIME_IDLE_MINUTES	@"Threshold"

typedef enum {
    AINotIdle = 0,
    AIAutoIdle,
    AIManualIdle,
    AIDelayedManualIdle
} AIIdleState;

@protocol AIMiniToolbarItemDelegate;

@class IdleTimeWindowController, IdleTimePreferences;

@interface AIIdleTimePlugin : AIPlugin <AIMiniToolbarItemDelegate, AIContactListTooltipEntry> {
    IdleTimePreferences	*preferences;

    BOOL		isIdle;
    NSTimer		*idleTimer;

    BOOL		idleEnabled;
    double		idleThreshold;

    NSMenuItem		*menuItem;

    AIIdleState		idleState;
    double		manualIdleTime;

}

- (void)installPlugin;
- (void)uninstallPlugin;
- (void)setIdleState:(AIIdleState)inState;
- (void)setManualIdleTime:(double)inSeconds;
- (void)showManualIdleWindow:(id)sender;

@end
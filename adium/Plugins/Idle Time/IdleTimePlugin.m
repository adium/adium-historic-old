//
//  Idle Time.m
//  Adium
//
//  Created by Greg Smith on Wed Dec 18 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "IdleTimePlugin.h"
#import <AIUtilities/AIUtilities.h>
#import "IdleTimeWindowController.h"
#import "IdleTimePreferences.h"

#define    IDLE_ACTIVE_INTERVAL		30.0	//Checking delay when the user is active
#define    IDLE_INACTIVE_INTERVAL	1.0	//Checking delay when the user is idle

extern double CGSSecondsSinceLastInputEvent(unsigned long evType);

@interface AIIdleTimePlugin (PRIVATE)
- (void)dealloc;
- (void)preferencesChanged:(NSNotification *)notification;
- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects;
- (void)setIsIdle:(BOOL)inIsIdle;
- (void)idleTimer:(NSTimer *)inTimer;
- (void)removeIdleTimer;
- (void)setAllAccountsIdleTo:(double)inSeconds;
- (double)currentIdleTime;
@end

@implementation AIIdleTimePlugin

- (void)installPlugin
{
    isIdle = NO;
    idleTimer = nil;
    
    //Register our defaults and install the preference view
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DEFAULT_PREFERENCES forClass:[self class]] forGroup:GROUP_IDLE_TIME]; //Register our default preferences
    preferences = [[IdleTimePreferences idleTimePreferencesWithOwner:owner] retain]; 

    //Observe preference changed notifications, and setup our initial values
    [[[owner preferenceController] preferenceNotificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];

    //Install the menu item to manually set idle time
    NSMenuItem		*menuItem;

    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Set Idle Time" target:self action:@selector(showIdleTimeWindow:) keyEquivalent:@"I"] autorelease];
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_File_Status];
    
    //Install all the toolbar item to manually set idle time
    AIMiniToolbarItem	*toolbarItem;

    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"IdleTime"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"idle" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showIdleTimeWindow:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Set Idle Time"];
    [toolbarItem setPaletteLabel:@"Set Idle Time"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];
}

- (void)uninstallPlugin
{
    //unregister, remove, ...
}

//Show the 'set idle time' window
- (IBAction)showIdleTimeWindow:(id)sender
{
    [[IdleTimeWindowController idleTimeWindowControllerWithOwner:owner] showWindow:nil];
}


// Private ---------------------------------------------------------------------------------
//dealloc
- (void)dealloc
{
    [self removeIdleTimer];
    [IdleTimeWindowController closeSharedInstance];
    //Close/release idle time window

    [super dealloc];
}

//An idle preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:GROUP_IDLE_TIME] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:GROUP_IDLE_TIME];
    
        //Store the new values locally
        idleEnabled = [[prefDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue];
        idleThreshold = [[prefDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue] * 60; //convert to seconds

        //Reset our idle timers
        [self setIsIdle:NO];
    }
}

//Configure our 'set idle' toolbar item
- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    return(YES);
}

//Set our idle state
- (void)setIsIdle:(BOOL)inIsIdle
{    
    if(!idleEnabled){
        //If idle is disabled, we set our idle to NO and do not install timers
        isIdle = NO;
        
    }else{
        isIdle = inIsIdle;
    
        if(isIdle){ //Idle
            [self setAllAccountsIdleTo:[self currentIdleTime]];
            [self removeIdleTimer];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_INACTIVE_INTERVAL) target:self selector:@selector(idleTimer:) userInfo:nil repeats:YES] retain]; //Install the new idle timer
    
        }else if(!isIdle){ //Unidle
            [self setAllAccountsIdleTo:0];
            [self removeIdleTimer];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_ACTIVE_INTERVAL) target:self selector:@selector(idleTimer:) userInfo:nil repeats:YES] retain]; //Install the new idle timer
    
        }
    }
}

//Called periodically to monitor the user's activity
- (void)idleTimer:(NSTimer *)inTimer
{
    if(isIdle){ //If they're idle, make sure they are still idle
        if([self currentIdleTime] < idleThreshold){ //The user is no longer idle
            [self setIsIdle:NO];
        }

    }else{ //If they're active, make sure they haven't gone idle
        if([self currentIdleTime] > idleThreshold){ //The user has gone idle
            [self setIsIdle:YES];
        }
    }
}

//Remove any active idle timer
- (void)removeIdleTimer
{
    if(idleTimer){
        [idleTimer invalidate];
        [idleTimer release];
        idleTimer = nil;
    }
}

//Set the idle time of all accounts
- (void)setAllAccountsIdleTo:(double)inSeconds
{
    [[owner accountController] setStatusObject:[NSNumber numberWithDouble:inSeconds] forKey:@"IdleTime" account:nil];
    [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"IdleSetManually" account:nil];
}

//Returns the current # of seconds the user has been idle
- (double)currentIdleTime
{
    return(CGSSecondsSinceLastInputEvent(-1));
}

@end

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

#define IDLE_ACTIVE_INTERVAL		30.0	//Checking delay when the user is active
#define IDLE_INACTIVE_INTERVAL		1.0	//Checking delay when the user is idle

#define IDLE_REMOVE_IDLE_TITLE		@"Remove Idle"
#define IDLE_SET_CUSTOM_IDLE_TITLE	@"Set Custom IdleÉ"
#define IDLE_SET_IDLE_TITLE		@"Set Idle"

extern double CGSSecondsSinceLastInputEvent(unsigned long evType);

@interface AIIdleTimePlugin (PRIVATE)
- (void)preferencesChanged:(NSNotification *)notification;
- (double)currentIdleTime;

- (void)_openIdleState:(AIIdleState)inState;
- (void)_closeIdleState:(AIIdleState)inState;
- (void)_setAllAccountsIdleTo:(double)inSeconds;

- (void)installIdleMenu;
- (void)updateIdleMenu;
- (void)selectIdleMenu:(id)sender;
@end

@implementation AIIdleTimePlugin

- (void)installPlugin
{
    isIdle = NO;
    idleTimer = nil;

    //Start up new state
    idleState = AINotIdle;
    [self _openIdleState:idleState];

    //Register our defaults and install the preference view
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DEFAULT_PREFERENCES forClass:[self class]] forGroup:PREF_GROUP_IDLE_TIME]; //Register our default preferences
    preferences = [[IdleTimePreferences idleTimePreferencesWithOwner:owner] retain]; 

    //Observe account status changes
//    [[owner notificationCenter] addObserver:self selector:@selector(accountStatusChanged:) name:Account_StatusChanged object:nil];

    //Observe preference changed notifications, and setup our initial values
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //Install the menu item to manually set idle time
    [self installIdleMenu];

    //Install our tooltip entry
    [[owner interfaceController] registerContactListTooltipEntry:self];

    //Install all the toolbar item to manually set idle time
/*    AIMiniToolbarItem	*toolbarItem;

    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"IdleTime"];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"idle" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showManualIdleWindow:)];
    [toolbarItem setEnabled:YES];
    [toolbarItem setToolTip:@"Set Idle Time"];
    [toolbarItem setPaletteLabel:@"Set Idle Time"];
    [toolbarItem setDelegate:self];
    [[AIMiniToolbarCenter defaultCenter] registerItem:[toolbarItem autorelease]];*/
}

- (void)uninstallPlugin
{
    //unregister, remove, ...
}

//Set the requested manual idle time
- (void)setManualIdleTime:(double)inSeconds
{
    manualIdleTime = inSeconds;
    [self setIdleState:AIManualIdle];
}


// Private ---------------------------------------------------------------------------------
//dealloc
- (void)dealloc
{
    [self _closeIdleState:idleState]; //Close down current state
    [IdleTimeWindowController closeSharedInstance]; //Close/release idle time window

    [super dealloc];
}

//An idle preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if([(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_IDLE_TIME] == 0){
        NSDictionary	*prefDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];
    
        //Store the new values locally
        idleEnabled = [[prefDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue];
        idleThreshold = [[prefDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue] * 60; //convert to seconds

        //Reset our idle state (We don't reset if idle, since that would clear the idle status)
        if(idleState == AINotIdle){
            [self setIdleState:AINotIdle];
        }
    }
}

//Configure our 'set idle' toolbar item
- (BOOL)configureToolbarItem:(AIMiniToolbarItem *)inToolbarItem forObjects:(NSDictionary *)inObjects
{
    return(YES);
}



//Idle Control -----------------------------------------------------------------------------------
/*There are 4 states of idle:
    Normal (Not Idle):  [On load, 'remove idle' is selected]
        Install timer, check every 30 seconds
        If (  idle condition > threshold )
        Set idle time to idle condition
    
    Idle (Auto-Set):
        Install time, check every 1 second
        if (idle condition < threshold)
        Remove idle time
    
    Idle (Manually Set on delay): ['set idle' is selected]
        Install timer for threshold
        On fire, set idle time to threshold
    
    Idle (Manually Set): ['set custom idle' is selected]
        Set idle time, no timer
*/
- (void)setIdleState:(AIIdleState)inState
{
    NSLog(@"IdleState:%i",(int)inState);
    [self _closeIdleState:idleState]; //Close down current state
    [self _openIdleState:inState]; //Start up new state
    idleState = inState;
}

- (void)_openIdleState:(AIIdleState)inState
{
    switch(inState){
        case AINotIdle:
            //Set idle to 0 seconds (Not idle)
            [self _setAllAccountsIdleTo:0];
            
            //Install a timer to check the user's activity every 30 seconds.
            [idleTimer invalidate]; [idleTimer release];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_ACTIVE_INTERVAL)
                                                          target:self
                                                        selector:@selector(notIdleTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
        break;
        case AIAutoIdle:
            //Set idle to the user's current system idle
            [self _setAllAccountsIdleTo:[self currentIdleTime]];

            //Install a timer to check the user's activity every 1 seconds.
            [idleTimer invalidate]; [idleTimer release];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_INACTIVE_INTERVAL)
                                                          target:self
                                                        selector:@selector(autoIdleTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
        break;
        case AIManualIdle:
            //Set idle to a custom manualIdleTime
            [self _setAllAccountsIdleTo:manualIdleTime];
            
        break;
        case AIDelayedManualIdle:
            //Set idle to 0 (Not Idle)
            [self _setAllAccountsIdleTo:0];

            //Install a timer for the user's threshold.  After the threshold is up, we set the user as idle.  This makes it easier to fake idle status, since the user doesn't isntantly have a 5/10 minute idle time.
            [idleTimer invalidate]; [idleTimer release];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(idleThreshold)
                                                          target:self
                                                        selector:@selector(delayedManualIdleTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
        break;
    }    
}

- (void)_closeIdleState:(AIIdleState)inState
{
    switch(inState){
        case AINotIdle:
        case AIAutoIdle:
        case AIDelayedManualIdle:
            //Remove our timer
            [idleTimer invalidate]; [idleTimer release]; idleTimer = nil;
        break;
        case AIManualIdle:
            //Nothing needs to be done
        break;
    }
}

//Make sure the user hasn't gone idle
- (void)notIdleTimer:(NSTimer *)inTimer
{
    if([self currentIdleTime] > idleThreshold){ //The user has gone idle
        [self setIdleState:AIAutoIdle];
    }
}

//Make sure the user is still idle
- (void)autoIdleTimer:(NSTimer *)inTimer
{
    if([self currentIdleTime] < idleThreshold){ //The user is no longer idle
        [self setIdleState:AINotIdle];
    }
}

//Switch the user over to regular manual idle mode
- (void)delayedManualIdleTimer:(NSTimer *)inTimer
{
    manualIdleTime = idleThreshold;
    [self setIdleState:AIManualIdle];
}

//Set the idle time of all accounts
- (void)_setAllAccountsIdleTo:(double)inSeconds
{
    if(inSeconds){
        [[owner accountController] setStatusObject:[NSDate dateWithTimeIntervalSinceNow:(-inSeconds)] forKey:@"IdleSince" account:nil];
        [[owner accountController] setStatusObject:[NSNumber numberWithBool:NO] forKey:@"IdleSetManually" account:nil];
    }else{
        [[owner accountController] setStatusObject:nil forKey:@"IdleSince" account:nil];
        [[owner accountController] setStatusObject:nil forKey:@"IdleSetManually" account:nil];
    }
    
}

//Returns the current # of seconds the user has been idle
- (double)currentIdleTime
{
    return(CGSSecondsSinceLastInputEvent(-1));
}

//Show the set manual idle time window
- (void)showManualIdleWindow:(id)sender
{
    [[IdleTimeWindowController idleTimeWindowControllerWithOwner:self] showWindow:nil];
}


//Idle Menu ---------------------------------------------------------------
//Install the idle time menu
- (void)installIdleMenu
{
    //Create the menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:IDLE_SET_IDLE_TITLE
                                           target:self
                                           action:@selector(selectIdleMenu:)
                                    keyEquivalent:@"I"] autorelease];

    
    //Add it to the menubar
    [[owner menuController] addMenuItem:menuItem toLocation:LOC_File_Status];
}

//Update our menu when the idle status changes
/*- (void)accountStatusChanged:(NSNotification *)notification
{
    if([notification object] == nil){ //We ignore account-specific status changes
        NSString	*modifiedKey = [[notification userInfo] objectForKey:@"Key"];

        if([modifiedKey compare:@"IdleSince"] == 0){
            [self updateIdleMenu]; //Update our away menu
        }
    }
}*/

//Update the idle time menu
- (void)updateIdleMenu
{
    if(idleState != AINotIdle){ //Remove Idle
        [menuItem setTitle:IDLE_REMOVE_IDLE_TITLE];
        
    }else if([NSEvent optionKey]){ //Set custom idle...
        [menuItem setTitle:IDLE_SET_CUSTOM_IDLE_TITLE];
        
    }else{ //Set idle
        [menuItem setTitle:IDLE_SET_IDLE_TITLE];
        
    }
}

//User selected the idle menu
- (void)selectIdleMenu:(id)sender
{
    if(idleState != AINotIdle){ //Remove Idle
        [self setIdleState:AINotIdle];
        
    }else if([NSEvent optionKey]){ //Set custom idle...
        [self showManualIdleWindow:nil];

    }else{ //Set idle
        [self setIdleState:AIDelayedManualIdle];
        
    }
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    [self updateIdleMenu];

    return(YES);
}



//Tooltip entry ---------------------------------------------------------------------------------
- (NSString *)label
{
    return(@"Idle");
}

- (NSString *)entryForObject:(AIListObject *)inObject
{
    NSString	*entry = nil;

    if([inObject isKindOfClass:[AIListContact class]]){
        int idle = [[(AIListContact *)inObject statusArrayForKey:@"Idle"] greatestIntegerValue];

        if(idle){
            int	hours = (int)(idle / 60);
            int	minutes = (int)(idle % 60);

            if(hours){
                entry = [NSString stringWithFormat:@"%i hour%@, %i minute%@", hours, (hours == 1 ? @"": @"s"), minutes, (minutes == 1 ? @"": @"s")];
            }else{
                entry = [NSString stringWithFormat:@"%i minute%@", minutes, (minutes == 1 ? @"": @"s")];
            }
        }
    }

    return(entry);
}


@end









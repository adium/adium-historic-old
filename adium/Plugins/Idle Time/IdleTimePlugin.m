/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

#import "IdleTimePlugin.h"
#import "IdleTimeWindowController.h"
#import "IdleTimePreferences.h"

#define IDLE_ACTIVE_INTERVAL		30.0	//Checking delay when the user is active
#define IDLE_INACTIVE_INTERVAL		1.0	//Checking delay when the user is idle

#define IDLE_REMOVE_IDLE_TITLE		AILocalizedString(@"Remove Idle","Remove the manual idle")
#define IDLE_SET_CUSTOM_IDLE_TITLE	AILocalizedString(@"Set Custom IdleÉ","Set a custom idle")
#define IDLE_SET_IDLE_TITLE			AILocalizedString(@"Set Idle",nil)

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
    [[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DEFAULT_PREFERENCES forClass:[self class]] forGroup:PREF_GROUP_IDLE_TIME]; //Register our default preferences
    preferences = [[IdleTimePreferences idleTimePreferences] retain]; 

    //Observe preference changed notifications, and setup our initial values
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
    
    //Install the menu item to manually set idle time
    [self installIdleMenu];

    //Install all the toolbar item to manually set idle time
/*    AIMiniToolbarItem	*toolbarItem;

    toolbarItem = [[AIMiniToolbarItem alloc] initWithIdentifier:@"IdleTime"];
    [toolbarItem setImage:[NSImage imageNamed:@"idle" forClass:[self class]]];
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
    
    [menuItem_setIdle release]; menuItem_setIdle = nil;
    if ([NSApp isOnPantherOrBetter]) {
            [menuItem_removeIdle release]; menuItem_removeIdle = nil;
            [menuItem_alternate release]; menuItem_alternate = nil;
    }
    
    [super dealloc];
}

//An idle preference has changed
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || 
	   [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_IDLE_TIME] == 0){
		
        NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];
	
        //Store the new values locally
        idleEnabled = [[prefDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue];
        idleThreshold = [[prefDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue] * 60; //convert to seconds
		autoAwayEnabled = [[prefDict objectForKey:KEY_AUTO_AWAY_ENABLED] boolValue];
		autoAwayThreshold = [[prefDict objectForKey:KEY_AUTO_AWAY_IDLE_MINUTES] intValue] * 60; //also convert this to seconds
		
		NSNumber *autoAwayMessageIndexNumber = [prefDict objectForKey:KEY_AUTO_AWAY_MESSAGE_INDEX];
		if (autoAwayMessageIndexNumber){
			autoAwayMessageIndex = [autoAwayMessageIndexNumber intValue];
		}else{
			autoAwayMessageIndex = -1;	
		}

        //Reset our idle state (We don't reset if idle, since that would clear the idle status)
        if(idleState == AINotIdle){
            [self setIdleState:AINotIdle];
        }
    }
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
    [self _closeIdleState:idleState]; //Close down current state
    [self _openIdleState:inState]; //Start up new state
    idleState = inState;
    if ([NSApp isOnPantherOrBetter] && (idleState != AIAutoAway)) {
        [self updateIdleMenu];
    }
}

- (void)_openIdleState:(AIIdleState)inState
{
    switch(inState){
        case AINotIdle:
            //Set idle to 0 seconds (Not idle)
            [self _setAllAccountsIdleTo:0];

            if(idleEnabled || autoAwayEnabled){
                //Install a timer to check the user's activity every 30 seconds.
                [idleTimer invalidate]; [idleTimer release];
                idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_ACTIVE_INTERVAL)
                                                              target:self
                                                            selector:@selector(notIdleTimer:)
                                                            userInfo:nil
                                                             repeats:YES] retain];
            }
                
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

            //Install a timer for the user's threshold.  After the threshold is up, we set the user as idle.  This makes it easier to fake idle status, since the user doesn't instantly have a 5/10 minute idle time.
			[idleTimer invalidate]; [idleTimer release];
            idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(idleThreshold)
                                                          target:self
                                                        selector:@selector(delayedManualIdleTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
        break;
		case AIAutoAway:
		{
			//Load the array of away messages
			NSArray				*awaysArray = [[adium preferenceController] preferenceForKey:KEY_SAVED_AWAYS
																					   group:PREF_GROUP_AWAY_MESSAGES];
			if (autoAwayMessageIndex >= 0 && (autoAwayMessageIndex < [awaysArray count])){
				//If the autoAwayMessageIndex corresponds to a valid away message, set us as away
				NSDictionary		*awayDict = [awaysArray objectAtIndex:autoAwayMessageIndex];
				NSAttributedString  *awayMessage = [awayDict objectForKey:@"Message"];
				NSAttributedString  *awayAutoResponse = [awayDict objectForKey:@"Autoresponse"];
				
				[[adium preferenceController] setPreference:awayMessage
													 forKey:@"AwayMessage"
													  group:GROUP_ACCOUNT_STATUS];
				[[adium preferenceController] setPreference:awayAutoResponse
													 forKey:@"Autoresponse" 
													  group:GROUP_ACCOUNT_STATUS];
			}
			
			//Timer gets killed when we set Auto Away.  If we're already idle, set autoIdleTimer, otherwise set notIdleTimer
			[idleTimer invalidate]; [idleTimer release];
			NSDate	*currentIdle = [[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			if (currentIdle != nil){
				idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_INACTIVE_INTERVAL)
															  target:self
															selector:@selector(autoIdleTimer:)
															userInfo:nil
															 repeats:YES] retain];
			}else{
				idleTimer = [[NSTimer scheduledTimerWithTimeInterval:(IDLE_ACTIVE_INTERVAL)
											  target:self
											selector:@selector(notIdleTimer:)
											userInfo:nil
											 repeats:YES] retain];
            }
				
		}
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
		case AIAutoAway:
			//Nothing needs to be done
		break;
    }
}

//Make sure the user hasn't gone idle
- (void)notIdleTimer:(NSTimer *)inTimer
{
	if(([self currentIdleTime] > idleThreshold) && idleEnabled){ //The user has gone idle
        [self setIdleState:AIAutoIdle];
    }
	
    if(([self currentIdleTime] > autoAwayThreshold) && autoAwayEnabled && ([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil)){ //The user has gone idle (time to set auto away)
		[self setIdleState:AIAutoAway];
    }
}

//Make sure the user is still idle
- (void)autoIdleTimer:(NSTimer *)inTimer
{
    if([self currentIdleTime] < idleThreshold){ //The user is no longer idle
		[self setIdleState:AINotIdle];
    }
   
	 if(([self currentIdleTime] > autoAwayThreshold) && autoAwayEnabled && ([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil)){ //Check just incase the user wants to go away automatically AFTER being set idle
		[self setIdleState:AIAutoAway];
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
    NSDate	*currentIdle = [[adium preferenceController] preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
        
    if(inSeconds){
        NSDate	*newIdle = [NSDate dateWithTimeIntervalSinceNow:(-inSeconds)];

        if(![currentIdle isEqualToDate:newIdle]){
			[[adium preferenceController] setPreference:newIdle forKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
        }
        
    }else{
        if(currentIdle != nil){
            [[adium preferenceController] setPreference:nil forKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
        }

    }
    
}

//Returns the current # of seconds the user has been idle
- (double)currentIdleTime
{
    double idleTime = CGSSecondsSinceLastInputEvent(-1);

    //On MDD Powermacs, the above function will return a large value when the machine is active (-1?).
    //Here we check for that value and correctly return a 0 idle time.
    if(idleTime >= 18446744000.0) idleTime = 0.0; //18446744073.0

    return(idleTime);
}

//Show the set manual idle time window
- (void)showManualIdleWindow:(id)sender
{
    [[IdleTimeWindowController idleTimeWindowControllerForPlugin:self] showWindow:nil];
}


//Idle Menu ---------------------------------------------------------------
//Install the idle time menu
- (void)installIdleMenu
{
    //Create the menu item
    menuItem_setIdle = [[NSMenuItem alloc] initWithTitle:IDLE_SET_IDLE_TITLE
                                           target:self
                                           action:@selector(selectIdleMenu:)
                                    keyEquivalent:@""];
    //Add it to the menubar
    [[adium menuController] addMenuItem:menuItem_setIdle toLocation:LOC_File_Status];

    //On panther, set up our extra menu items
    if ([NSApp isOnPantherOrBetter]) {
        //currently shows setIdle
        idleMenuState = SetIdle;
        
        //Create the remove menu item
        menuItem_removeIdle = [[NSMenuItem alloc] initWithTitle:IDLE_REMOVE_IDLE_TITLE
                                                         target:self
                                                         action:@selector(selectIdleMenu:)
                                                  keyEquivalent:@""];    
        
        //Create the custom menu item
        menuItem_alternate = [[NSMenuItem alloc] initWithTitle:IDLE_SET_CUSTOM_IDLE_TITLE 
                                                         target:self 
                                                         action:@selector(selectCustomIdleMenu:) 
                                                  keyEquivalent:@""];
        [menuItem_alternate setAlternate:YES];
        [menuItem_alternate setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
        [[adium menuController] addMenuItem:menuItem_alternate toLocation:LOC_File_Status];
    }
}

//Update the idle time menu
- (void)updateIdleMenu
{
    if ([NSApp isOnPantherOrBetter]) {
        if( (idleState != AINotIdle) && (idleMenuState == SetIdle) ) { //Remove Idle    
            [NSMenu swapMenuItem:menuItem_setIdle with:menuItem_removeIdle];
            [NSMenu swapMenuItem:menuItem_alternate with:menuItem_alternate];
            idleMenuState = RemoveIdle;
        } else if( (idleState == AINotIdle) && (idleMenuState == RemoveIdle) ){
            [NSMenu swapMenuItem:menuItem_removeIdle with:menuItem_setIdle];
            [NSMenu swapMenuItem:menuItem_alternate with:menuItem_alternate];
            idleMenuState = SetIdle;
        }
    } else {
        if(idleState != AINotIdle){ //Remove Idle
            [menuItem_setIdle setTitle:IDLE_REMOVE_IDLE_TITLE];
        }else if([NSEvent optionKey]){ //Set custom idle... (JAGUAR)
            [menuItem_setIdle setTitle:IDLE_SET_CUSTOM_IDLE_TITLE];
        }else{ //Set idle
            [menuItem_setIdle setTitle:IDLE_SET_IDLE_TITLE];
        }
    }
}

//User selected the idle menu
- (void)selectIdleMenu:(id)sender
{
    if([[menuItem_setIdle title] isEqualToString:IDLE_SET_CUSTOM_IDLE_TITLE]){ //Set custom idle... (JAGUAR)
        [self showManualIdleWindow:nil];
    }else if(idleState != AINotIdle){ //Remove Idle
        [self setIdleState:AINotIdle];
    }else{ //Set idle
        [self setIdleState:AIDelayedManualIdle];
    }
}

- (void)selectCustomIdleMenu:(id)sender
{
    [self showManualIdleWindow:nil];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    if (![NSApp isOnPantherOrBetter]) {
        [self updateIdleMenu];
    }
    return(YES);
}

@end





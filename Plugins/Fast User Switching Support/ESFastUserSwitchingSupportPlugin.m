//
//  ESFastUserSwitchingSupportPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Nov 25 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "ESFastUserSwitchingSupportPlugin.h"

#define FAST_USER_SWITCH_AWAY_STRING AILocalizedString(@"I have switched logged in users. Someone else may be using the computer.","Fast user switching away message")

@interface ESFastUserSwitchingSupportPlugin (PRIVATE)
-(void)switchHandler:(NSNotification*) notification;
@end

@implementation ESFastUserSwitchingSupportPlugin
- (void)installPlugin
{
    if([NSApp isOnPantherOrBetter]) //only install on Panther
    {
        setAwayThroughFastUserSwitch = NO;
        setMuteThroughFastUserSwitch = NO;
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                            selector:@selector(switchHandler:) 
                                                                name:NSWorkspaceSessionDidBecomeActiveNotification 
                                                                object:nil];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self 
                                                            selector:@selector(switchHandler:) 
                                                                name:NSWorkspaceSessionDidResignActiveNotification
                                                                object:nil];
    }
}

-(void)uninstallPlugin
{
	//Clear the fast switch away if we had it up before
	[self switchHandler:nil];

	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
}

-(void)switchHandler:(NSNotification*) notification
{
    if (notification && 
		[[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification]) {
		//Deactivation - go away
 
        //Go away if we aren't already away
        if ([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil) {
            NSAttributedString *away = [[NSAttributedString alloc] initWithString:FAST_USER_SWITCH_AWAY_STRING
																	   attributes:[[adium contentController] defaultFormattingAttributes]];
            [[adium preferenceController] setPreference:[away dataRepresentation] 
												 forKey:@"AwayMessage"
												  group:GROUP_ACCOUNT_STATUS];
//			[[adium preferenceController] setPreference:[away dataRepresentation] forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
			[away release];
            setAwayThroughFastUserSwitch = YES;
        }
		
		//Set a temporary mute if none already exists
		NSNumber *oldTempMute = [[adium preferenceController] preferenceForKey:KEY_SOUND_TEMPORARY_MUTE
																		 group:PREF_GROUP_SOUNDS];
		if (!oldTempMute || ![oldTempMute boolValue]) {
			[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES] 
												 forKey:KEY_SOUND_TEMPORARY_MUTE
												  group:PREF_GROUP_SOUNDS];
			setMuteThroughFastUserSwitch = YES;
		}
    } else {  
		//Activation - return from away
        
		//Remove the away status flag if we set it originally
        if (setAwayThroughFastUserSwitch) {
            //Remove the away status flag	
            [[adium preferenceController] setPreference:nil forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
            [[adium preferenceController] setPreference:nil forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
            setAwayThroughFastUserSwitch = NO;
        }
		
		//Clear the temporary mute if necessary
		if (setMuteThroughFastUserSwitch) {
			[[adium preferenceController] setPreference:nil
												 forKey:KEY_SOUND_TEMPORARY_MUTE
												  group:PREF_GROUP_SOUNDS];
		}
    }    
}

@end

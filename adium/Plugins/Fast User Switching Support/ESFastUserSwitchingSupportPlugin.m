//
//  ESFastUserSwitchingSupportPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Nov 25 2003.
//

#import "ESFastUserSwitchingSupportPlugin.h"

#define FAST_USER_SWITCH_AWAY_STRING @"I have switched logged in users. Someone else may be using the computer."

@implementation ESFastUserSwitchingSupportPlugin
- (void)installPlugin
{
    if([NSApp isOnPantherOrBetter]) //only install on Panther
    {
        setAwayThroughFastUserSwitch = NO;
        
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

}

-(void)switchHandler:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification])
    {       //Deactivation
 
        //Go away if we aren't already away
        if ([[adium preferenceController] preferenceForKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS] == nil)
        {
            NSAttributedString *away = [[NSAttributedString alloc] initWithString:FAST_USER_SWITCH_AWAY_STRING];
            [[adium preferenceController] setPreference:[away dataRepresentation] forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
			[[adium preferenceController] setPreference:[away dataRepresentation] forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
			[away release];
            setAwayThroughFastUserSwitch = YES;
        }
    }
    else    //Activation
    {
        //Remove the away status flag if we set it originally
        if (setAwayThroughFastUserSwitch) {
            //Remove the away status flag	
            [[adium preferenceController] setPreference:nil forKey:@"AwayMessage" group:GROUP_ACCOUNT_STATUS];
            [[adium preferenceController] setPreference:nil forKey:@"Autoresponse" group:GROUP_ACCOUNT_STATUS];
            setAwayThroughFastUserSwitch = NO;
        }
    }    
}

@end

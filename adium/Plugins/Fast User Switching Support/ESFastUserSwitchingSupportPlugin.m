//
//  ESFastUserSwitchingSupportPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Nov 25 2003.
//

#import "ESFastUserSwitchingSupportPlugin.h"

#define FAST_USER_SWITCH_AWAY_STRING @"Someone else is using my computer right now."

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
        if ([[adium accountController] propertyForKey:@"AwayMessage" account:nil] == nil)
        {
            NSAttributedString *away = [[NSAttributedString alloc] initWithString:FAST_USER_SWITCH_AWAY_STRING];
            [[adium accountController] setProperty:[away dataRepresentation]
                                            forKey:@"AwayMessage" 
                                           account:nil];
            [away release];
            setAwayThroughFastUserSwitch = YES;
        }
    }
    else    //Activation
    {
        //Remove the away status flag if we set it originally
        if (setAwayThroughFastUserSwitch) {
            //Remove the away status flag	
            [[adium accountController] setProperty:nil forKey:@"AwayMessage" account:nil];
            [[adium accountController] setProperty:nil forKey:@"Autoresponse" account:nil];
            setAwayThroughFastUserSwitch = NO;
        }
    }    
}

@end

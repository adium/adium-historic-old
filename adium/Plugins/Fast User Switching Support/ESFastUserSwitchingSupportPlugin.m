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
    if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2) //only install on Panther
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

}

-(void)switchHandler:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification])
    {       //Deactivation
 
        //Go away if we aren't already away
        if ([[owner accountController] propertyForKey:@"AwayMessage" account:nil] == nil)
        {
            NSAttributedString *away = [[NSAttributedString alloc] initWithString:FAST_USER_SWITCH_AWAY_STRING];
            [[owner accountController] setProperty:[away dataRepresentation]
                                            forKey:@"AwayMessage" 
                                           account:nil];
            [away release];
            setAwayThroughFastUserSwitch = YES;
        }
        
        //Mute if we aren't already muted
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL];
        if([[preferenceDict objectForKey:KEY_SOUND_MUTE] intValue] == NO){
            [[owner preferenceController] setPreference:[NSNumber numberWithBool:YES]
                                                 forKey:KEY_SOUND_TEMPORARY_MUTE
                                                  group:PREF_GROUP_GENERAL];   
            setMuteThroughFastUserSwitch = YES;
        }
        
    }
    else    //Activation
    {
        //Remove the away status flag if we set it originally
        if (setAwayThroughFastUserSwitch) {
            //Remove the away status flag	
            [[owner accountController] setProperty:nil forKey:@"AwayMessage" account:nil];
            [[owner accountController] setProperty:nil forKey:@"Autoresponse" account:nil];
            setAwayThroughFastUserSwitch = NO;
        }
        if (setMuteThroughFastUserSwitch) {
         //Turn off the temporary mute   
            [[owner preferenceController] setPreference:[NSNumber numberWithBool:NO]
                                                 forKey:KEY_SOUND_TEMPORARY_MUTE
                                                  group:PREF_GROUP_GENERAL];   
            setMuteThroughFastUserSwitch = NO;
        }
        
    }    
}

@end

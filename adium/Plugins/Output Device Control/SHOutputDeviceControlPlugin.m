//
//  SHOutputDeviceControlPlugin.m
//  Adium
//
//  Created by Stephen Holt on Mon Apr 12 2004.

#import "SHOutputDeviceControlPlugin.h"
#import "SHOutputDeviceControlPreferences.h"

@interface SHOutputDeviceControlPlugin (PRIVATE)

@end

@implementation SHOutputDeviceControlPlugin

- (void)installPlugin
{
    //Install our preference view
    if([NSApp isOnPantherOrBetter]){
        preferences = [[SHOutputDeviceControlPreferences preferencePane] retain];
    }else{
        return(nil);
    }
}

- (void)uninstallPlugin
{
    [[adium notificationCenter] removeObserver:preferences];
    [[NSNotificationCenter defaultCenter] removeObserver:preferences];
}
@end

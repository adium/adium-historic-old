//
//  AIDockBehaviorPlugin.m
//  Adium
//
//  Created by Colin Barrett on Tue Jan 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AIUtilities/AIUtilities.h>
#import "AIDockBehaviorPlugin.h"

@implementation AIDockBehaviorPlugin

- (void)installPlugin
{
    //register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithBool:YES], @"dock_bounce_onDidReceiveContent", nil]
    forGroup:@"DockBehavior"];
    
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithDouble:0.0], @"dock_bounce_onDidReceiveContent_delay", nil]
    forGroup:@"DockBehavior"];
    
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys: 
        [NSNumber numberWithInt:4], @"dock_bounce_onDidReceiveContent_num", nil]
    forGroup:@"DockBehavior"];
    
    //install our observers
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(messageIn:) name:Content_DidReceiveContent object:nil];
}

- (void)messageIn:(NSNotification *)notification
{
    if([[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent" group:@"DockBehavior" object:[notification object]] boolValue]) // are we bouncing at all?
    {
        if([[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent_num" group:@"DockBehavior" object:[notification object]] intValue] == 1 && [[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent_num" group:@"DockBehavior" object:[notification object]] doubleValue] > 0.0) //if we only bounce once, and don't have a delay, use the method with less overhead
        {
            [[owner dockController] bounce];
        }
        else
        {
            [[owner dockController] 
                bounceWithInterval:[[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent_delay" group:@"DockBehavior" object:[notification object]] doubleValue] 
                times:[[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent_num" group:@"DockBehavior" object:[notification object]] intValue]
            ];
        }
    }
}

@end
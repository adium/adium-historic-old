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
    
    //install our observers
    [[[owner contentController] contentNotificationCenter] addObserver:self selector:@selector(messageIn:) name:Content_DidReceiveContent object:nil];
}

- (void)messageIn:(NSNotification *)notification
{
    //if([[[owner preferenceController] preferenceForKey:@"dock_bounce_onDidReceiveContent" group:@"DockBehavior" object:nil] boolValue])
    //{
        [[owner dockController] bounce];
    //}
}

@end
//
//  ESStatusSortPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

#import "ESStatusSortPlugin.h"
#import "ESStatusSort.h"

@implementation ESStatusSortPlugin

- (void)installPlugin
{
    [[adium contactController] registerListSortController:[[[ESStatusSort alloc] init] autorelease]];
}

- (void)uninstallPlugin
{
    //[[adium contactController] unregisterContactSortController:self];
}

@end

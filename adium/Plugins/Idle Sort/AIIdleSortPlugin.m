//
//  AIIdleSortPlugin.m
//  Adium
//
//  Created by Arno Hautala on Mon May 12 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIdleSortPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIIdleSortNoGroups.h"

@implementation AIIdleSortPlugin

- (void)installPlugin
{
    [[owner contactController] registerListSortController:[[[AIIdleSortNoGroups alloc] init] autorelease]];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterContactSortController:self];
}


@end

//
//  AIIdleAwaySortPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIIdleAwaySortPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIIdleAwaySortNoGroups.h"

@implementation AIIdleAwaySortPlugin

- (void)installPlugin
{
    [[owner contactController] registerListSortController:[[[AIIdleAwaySortNoGroups alloc] init] autorelease]];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterContactSortController:self];
}


@end

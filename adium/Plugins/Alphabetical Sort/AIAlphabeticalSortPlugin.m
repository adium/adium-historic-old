//
//  AIAlphabeticalSortPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jan 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAlphabeticalSortPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAlphabeticalSort.h"
#import "AIAlphabeticalSortNoGroups.h"

int alphabeticalSort(id objectA, id objectB, void *context);

@implementation AIAlphabeticalSortPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactSortController:[[[AIAlphabeticalSort alloc] init] autorelease]];
    [[owner contactController] registerContactSortController:[[[AIAlphabeticalSortNoGroups alloc] init] autorelease]];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterContactSortController:self];
}

@end

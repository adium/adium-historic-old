//
//  ESStatusSortPlugin.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Tue Mar 09 2004.
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

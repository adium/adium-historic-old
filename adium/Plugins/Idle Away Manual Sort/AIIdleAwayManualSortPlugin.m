//
//  AIIdleAwayManualSortPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Jun 12 2003.
//

#import "AIIdleAwayManualSortPlugin.h"
#import "AIIdleAwayManualSort.h"

@implementation AIIdleAwayManualSortPlugin
- (void)installPlugin
{
    [[adium contactController] registerListSortController:[[[AIIdleAwayManualSort alloc] init] autorelease]];
}


- (void)uninstallPlugin
{
    //[[adium contactController] unregisterContactSortController:self];
}



@end

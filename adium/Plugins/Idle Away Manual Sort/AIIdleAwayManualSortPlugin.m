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
    [[owner contactController] registerListSortController:[[[AIIdleAwayManualSort alloc] init] autorelease]];
}


- (void)uninstallPlugin
{
    //[[owner contactController] unregisterContactSortController:self];
}



@end

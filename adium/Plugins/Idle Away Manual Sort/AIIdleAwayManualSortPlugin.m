//
//  AIIdleAwayManualSortPlugin.m
//  Adium
//
//  Created by Evan Schoenberg on Thu Jun 12 2003.
//

#import "AIIdleAwayManualSortPlugin.h"
#import "AIIdleAwayManualSort.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

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

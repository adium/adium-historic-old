//
//  AIManualSortPlugin.m
//  Adium
//
//  Created by Adam Iser on Sun Mar 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIManualSortPlugin.h"
#import "AIManualSort.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>


@implementation AIManualSortPlugin

- (void)installPlugin
{
    [[owner contactController] registerContactSortController:[[[AIManualSort alloc] init] autorelease]];
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterContactSortController:self];
}

@end

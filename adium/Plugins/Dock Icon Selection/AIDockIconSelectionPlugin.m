//
//  AIDockIconSelectionPlugin.m
//  Adium
//
//  Created by Adam Iser on Sat May 24 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIDockIconSelectionPlugin.h"
#import "AIDockIconPreferences.h"
#import "AIAdium.h"
#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>

@implementation AIDockIconSelectionPlugin

//
- (void)installPlugin
{
    //Install our preference view
    preferences = [[AIDockIconPreferences dockIconPreferencesWithOwner:owner] retain];
}

//
- (void)uninstallPlugin
{
}

@end









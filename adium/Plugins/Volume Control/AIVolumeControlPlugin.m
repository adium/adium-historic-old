//
//  AIVolumeControlPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Apr 16 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import "AIVolumeControlPlugin.h"
#import "AIVolumeControlPreferences.h"


@interface AIVolumeControlPlugin (PRIVATE)

@end

@implementation AIVolumeControlPlugin

- (void)installPlugin
{
    //Install our preference view
    preferences = [[AIVolumeControlPreferences volumeControlPreferencesWithOwner:owner] retain];
}

@end

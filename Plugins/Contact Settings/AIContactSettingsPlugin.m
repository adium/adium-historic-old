//
//  AIContactSettingsPlugin.m
//  Adium
//
//  Created by Adam Iser on Thu Jun 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactSettingsPlugin.h"
#import "AIContactSettingsPane.h"

@implementation AIContactSettingsPlugin

- (void)installPlugin
{
	[AIContactSettingsPane contactInfoPane];
}

@end

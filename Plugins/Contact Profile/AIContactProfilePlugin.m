//
//  AIContactInfoPlugin.m
//  Adium
//
//  Created by Adam Iser on Wed Jun 11 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import "AIContactProfilePlugin.h"
#import "AIContactProfilePane.h"

@implementation AIContactProfilePlugin

- (void)installPlugin
{
	[AIContactProfilePane contactInfoPane];
}

@end

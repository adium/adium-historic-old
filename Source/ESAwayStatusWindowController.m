//
//  ESAwayStatusWindowController.m
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESAwayStatusWindowController.h"


@implementation ESAwayStatusWindowController

+ (void)setStatusWindowVisible:(BOOL)shouldBeVisibile
{
	NSLog(@"The status window should now be %@",(shouldBeVisibile ? @"visible" : @"hidden"));
}

@end

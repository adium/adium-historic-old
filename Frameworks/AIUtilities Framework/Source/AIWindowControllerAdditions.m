//
//  AIWindowControllerAdditions.m
//  AIUtilities.framework
//
//  Created by David Smith on 9/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "AIWindowControllerAdditions.h"


@implementation NSWindowController (AIWindowControllerAdditions)

- (BOOL) canCustomizeToolbar
{
	return YES; //default implementation, should be overridden.
}

@end

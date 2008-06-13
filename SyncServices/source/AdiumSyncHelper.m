//
//  AdiumSyncHelper.m
//  Adium
//
//  Created by Stephen Holt on 6/13/08.
//  Copyright 2008 Adium. All rights reserved.
//

#import "AdiumSyncHelper.h"


@implementation AdiumSyncHelper

@end

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	AdiumSyncHelper *syncHelper = [[AdiumSyncHelper alloc] init];
	if([[ISyncManager sharedManager] isEnabled]) {
		[ISyncSession beginSessionWithClient:[syncHelper sessionClient] entityNames:[syncHelper entities] beforeDate:[NSDate distantFuture]];
	}
	[pool release];
}
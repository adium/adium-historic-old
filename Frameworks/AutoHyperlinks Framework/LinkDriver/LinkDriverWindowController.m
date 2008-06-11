//
//  LinkDriverWindowController.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 5/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LinkDriverWindowController.h"


@implementation LinkDriverWindowController
-(IBAction) linkifyTextView:(id)sender {
	[NSThread	detachNewThreadSelector:@selector(performLinkification:) toTarget:self withObject:linkifyView];
	[NSThread	detachNewThreadSelector:@selector(performLinkification:) toTarget:self withObject:otherView];
}

-(void) performLinkification:(NSTextView *)inView
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	[scanner linkifyTextView:[inView retain]];
	[pool release];
}
@end

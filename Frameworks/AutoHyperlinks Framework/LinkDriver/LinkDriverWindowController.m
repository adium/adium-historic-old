//
//  LinkDriverWindowController.m
//  AutoHyperlinks.framework
//
//  Created by Stephen Holt on 5/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "LinkDriverWindowController.h"

#define	SCANNER_KEY @"linkScanner"
#define VIEW_KEY @"linkView"

@implementation LinkDriverWindowController
-(IBAction) linkifyTextView:(id)sender {
	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:[NSDictionary dictionaryWithObjectsAndKeys:scanner,SCANNER_KEY,linkifyView,VIEW_KEY,nil]];
	[NSThread	detachNewThreadSelector:@selector(performLinkification:)
							   toTarget:self
							 withObject:[NSDictionary dictionaryWithObjectsAndKeys:scanner,SCANNER_KEY,otherView,VIEW_KEY,nil]];
}

-(void) performLinkification:(NSDictionary *)inDict
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	AHHyperlinkScanner	*scanner = [inDict objectForKey:SCANNER_KEY];
	NSTextView	*myView = [inDict objectForKey:VIEW_KEY];
	[scanner linkifyTextView:[myView retain]];
	[pool release];
}
@end

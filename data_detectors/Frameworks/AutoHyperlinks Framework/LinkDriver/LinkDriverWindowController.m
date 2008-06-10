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
	AHHyperlinkScanner	*scanner = [[AHHyperlinkScanner alloc] initWithStrictChecking:NO];
	[scanner linkifyTextView:linkifyView];
}
@end

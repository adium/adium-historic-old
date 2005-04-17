//
//  ESAwayStatusWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on 4/12/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import <Adium/AIWindowController.h>

@interface ESAwayStatusWindowController : AIWindowController {
	IBOutlet	NSButton		*button_return;
	
	IBOutlet	NSTabView		*tabView_configuration;
	
	//Single status tab
	IBOutlet	NSScrollView	*scrollView_singleStatus;
	IBOutlet	NSTextView		*textView_singleStatus;
	
	//Multiple statuses tab
	IBOutlet	NSScrollView	*scrollView_multiStatus;
	IBOutlet	NSTableView		*tableView_multiStatus;
	
	NSMutableArray				*_awayAccounts;
}

+ (void)updateStatusWindowWithVisibility:(BOOL)shouldBeVisibile;
- (IBAction)returnFromAway:(id)sender;

@end

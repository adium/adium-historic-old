//
//  ESVersionCheckerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.
//  Copyright (c) 2004-2005 The Adium Team. All rights reserved.
//

@interface ESVersionCheckerWindowController : AIWindowController {
	IBOutlet	NSTextField *textField_updateAvailable;
	IBOutlet	NSButton	*checkBox_checkAutomatically;
}

+ (void)showUpToDateWindow;
+ (void)showUpdateWindowFromBuild:(NSDate *)currentBuildDate toBuild:(NSDate *)latestBuildDate;
+ (void)showCannotConnectWindow;

- (IBAction)closeWindow:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)changePreference:(id)sender;

@end

//
//  ESVersionCheckerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.

@interface ESVersionCheckerWindowController : AIWindowController {
	IBOutlet	NSTextField *textField_updateAvailable;
	IBOutlet	NSButton	*checkBox_checkAutomatically;
}

+ (void)showUpToDateWindow;
+ (void)showUpdateWindowFromBuild:(NSDate *)currentBuildDate toBuild:(NSDate *)latestBuildDate;

- (IBAction)closeWindow:(id)sender;
- (IBAction)update:(id)sender;
- (IBAction)changePreference:(id)sender;

@end

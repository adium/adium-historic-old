//
//  ESVersionCheckerWindowController.h
//  Adium
//
//  Created by Evan Schoenberg on Mon Mar 29 2004.

@interface ESVersionCheckerWindowController : AIWindowController {
	IBOutlet	NSTabView   *tabView_hidden;
	
	IBOutlet	NSTextField *textField_upToDate;
	IBOutlet	NSButton	*button_upToDate_okay;
	
	IBOutlet	NSTextField *textField_updateAvailable;
	IBOutlet	NSButton	*button_updateAvailable_close;
	IBOutlet	NSButton	*button_updateAvailable_downloadPage;
	IBOutlet	NSButton	*checkBox_checkAutomatically;
}

+ (void)showVersionCheckerWindowWithLatestBuildDate:(NSDate *)latestBuildDate checkingManually:(BOOL)checkingManually;
- (void)showWindowWithLatestBuildDate:(NSDate *)latestBuildDate checkingManually:(BOOL)checkingManually;

- (IBAction)pressedButton:(id)sender;
- (IBAction)changePreference:(id)sender;
- (IBAction)closeWindow:(id)sender;

@end

//
//  CPFVersionChecker.h
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#define KEY_LAST_UPDATE_ASKED		@"LastUpdateAsked"
#define PREF_GROUP_UPDATING			@"Updating"
#define KEY_CHECK_AUTOMATICALLY 	@"Check Automatically"

@interface CPFVersionChecker : AIPlugin <AIListObjectObserver> {
    NSMenuItem 	*versionCheckerMenuItem;
	BOOL		observingListUpdates;
	BOOL		checkingManually;
	BOOL		timerActive;
	NSTimer		*timer;
}

- (void)checkForNewVersion:(id)sender;
- (void)timerCheckForNewVersion:(NSTimer *)timer;
- (void)startTimerChecking;
- (void)endTimerChecking;

@end

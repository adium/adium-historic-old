//
//  CPFVersionChecker.h
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

#define KEY_LAST_UPDATE_ASKED		@"LastUpdateAsked"
#define PREF_GROUP_UPDATING			@"Updating"
#define KEY_CHECK_AUTOMATICALLY 	@"Check Automatically"

@interface CPFVersionChecker : AIPlugin {
    NSMenuItem 	*versionCheckerMenuItem;
	NSTimer		*timer;
	BOOL		checkingManually;
	BOOL		checkWhenConnectionBecomesAvailable;
}

- (void)manualCheckForNewVersion:(id)sender;
- (void)automaticCheckForNewVersion:(id)sender;

@end

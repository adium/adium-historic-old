//
//  CPFVersionChecker.h
//  Adium
//
//  Created by Christopher Forsythe on Sat Mar 20 2004.
//

//----------------------------------------------------------------------------------------------------------------------
//When this flag is set to YES, we will version check from the beta key.  This allows beta releases to receive update
//notifications separately from regular releases.  Version updates will also be more frequent and cannot be disabled.
//This is to discourage the use of beta releases after a regular release is made without completely preventing the
//program from launching.
#define BETA_RELEASE_EXPIRATION		YES
//----------------------------------------------------------------------------------------------------------------------

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

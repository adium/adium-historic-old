//
//  ESAnnouncerPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Sun Sep 14 2003.
//

#import "ESAnnouncerPreferences.h"
#import "ESAnnouncerPlugin.h"

@implementation ESAnnouncerPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Sound);
}
- (NSString *)label{
    return(@"z");
}
- (NSString *)nibName{
    return(@"AnnouncerPrefs");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:ANNOUNCER_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_ANNOUNCER];
	return(defaultsDict);
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
 	[self configureControlsFromPrefs];
	[self configureControlDimming];
}

//Save changed preference
-(IBAction)changePreference:(id)sender
{
	[self configureControlDimming];
}

-(void)savePreferences
{	
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_time state]]
										 forKey:KEY_ANNOUNCER_TIME
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_sender state]]
										 forKey:KEY_ANNOUNCER_SENDER
										  group:PREF_GROUP_ANNOUNCER];
}

-(IBAction)closeOptions:(id)sender
{
	if(sender == pushButton_OK) {
		[self savePreferences];
	}
		
	[panel_options orderOut:nil];
    [NSApp endSheet:panel_options returnCode:0];
}

-(IBAction)openOptions:(id)sender
{
	[self configureControlsFromPrefs];
	
	[NSApp beginSheet:panel_options
	   modalForWindow:[view window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}


//Make the window's controls reflect the current preference state
- (void)configureControlsFromPrefs
{
	NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];
	
    [checkBox_time setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_TIME] boolValue]];
    [checkBox_sender setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_SENDER] boolValue]];
}

//Dim unavailable controls
- (void)configureControlDimming
{

}

@end

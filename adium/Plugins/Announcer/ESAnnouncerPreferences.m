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
    return(AIPref_Messages_Display);
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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];
    
	[checkBox_enableSpeech setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_ENABLED] boolValue]];

	[self configureControlsFromPrefs];
	[self configureControlDimming];
}

//Save changed preference
-(IBAction)changePreference:(id)sender
{
	if(sender == checkBox_enableSpeech) {
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_enableSpeech state]]
											 forKey:KEY_ANNOUNCER_ENABLED
											  group:PREF_GROUP_ANNOUNCER];
	}
	[self configureControlDimming];
}

-(void)savePreferences
{
	
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_enableSpeech state]]
										 forKey:KEY_ANNOUNCER_ENABLED
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_outgoing state]]
										 forKey:KEY_ANNOUNCER_OUTGOING
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_incoming state]]
										 forKey:KEY_ANNOUNCER_INCOMING
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_status state]]
										 forKey:KEY_ANNOUNCER_STATUS
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_time state]]
										 forKey:KEY_ANNOUNCER_TIME
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_sender state]]
										 forKey:KEY_ANNOUNCER_SENDER
										  group:PREF_GROUP_ANNOUNCER];
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[checkBox_messageText state]]
										 forKey:KEY_ANNOUNCER_MESSAGETEXT
										  group:PREF_GROUP_ANNOUNCER];
	
}

-(IBAction)closeOptions:(id)sender
{
	if(sender == pushButton_OK) {
		[self savePreferences];
	}
	
	[panel_options orderOut:panel_options];
}

-(IBAction)openOptions:(id)sender
{
	[self configureControlsFromPrefs];
	[panel_options makeKeyAndOrderFront:panel_options];
}


//Make the window's controls reflect the current preference state
- (void)configureControlsFromPrefs
{
	NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_ANNOUNCER];
	
    [checkBox_outgoing setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_OUTGOING] boolValue]];
    [checkBox_incoming setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_INCOMING] boolValue]];
    [checkBox_status setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_STATUS] boolValue]];
    [checkBox_time setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_TIME] boolValue]];
    [checkBox_sender setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_SENDER] boolValue]];
    [checkBox_messageText setState:[[preferenceDict objectForKey:KEY_ANNOUNCER_MESSAGETEXT] boolValue]];
    
}

//Dim unavailable controls
- (void)configureControlDimming
{
    BOOL messages = ([checkBox_outgoing state] || [checkBox_incoming state]);
    BOOL enabled = [checkBox_enableSpeech state];
	
	[pushButton_options setEnabled:enabled];
	
    [checkBox_messageText setEnabled:(messages)];
    [checkBox_sender setEnabled:(messages)];
    [checkBox_time setEnabled:(messages || [checkBox_status state])];
    
}

@end

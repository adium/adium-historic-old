//
//  ESWKMVAdvancedPreferences.m
//  Adium
//
//  Created by Evan Schoenberg on Fri Apr 30 2004.
//

#import "ESWKMVAdvancedPreferences.h"
#import "AIWebKitMessageViewPlugin.h"

#define ALIAS						AILocalizedString(@"Alias",nil)
#define ALIAS_SCREENNAME			AILocalizedString(@"Alias (Screen Name)",nil)
#define SCREENNAME_ALIAS			AILocalizedString(@"Screen Name (Alias)",nil)
#define SCREENNAME					AILocalizedString(@"Screen Name",nil)

@interface ESWKMVAdvancedPreferences (PRIVATE)
- (NSMenu *)_contactNameMenu;
@end

@implementation ESWKMVAdvancedPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(AILocalizedString(@"Display Options","Message Display Options advanced preferences label"));
}
- (NSString *)nibName{
    return(@"WebKitAdvancedPreferencesView");
}

- (NSDictionary *)restorablePreferences
{
	NSDictionary *defaultPrefs = [NSDictionary dictionaryNamed:WEBKIT_DEFAULT_PREFS forClass:[self class]];
	NSDictionary *defaultsDict = [NSDictionary dictionaryWithObject:defaultPrefs forKey:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	return(defaultsDict);
}


//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*prefDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];

	NSMenu *nameFormatMenu = [self _contactNameMenu];
	[popUp_nameFormat setMenu:nameFormatMenu];
	[popUp_nameFormat selectItemAtIndex:[nameFormatMenu indexOfItemWithTag:[[prefDict objectForKey:KEY_WEBKIT_NAME_FORMAT] intValue]]];
	
	[checkBox_combineConsecutive setState:[[prefDict objectForKey:KEY_WEBKIT_COMBINE_CONSECUTIVE] boolValue]];
	[checkBox_combineConsecutive setToolTip:AILocalizedString(@"Not all styles will display properly if this is disabled. Also, it looks silly.","Advanced webkit preferences: combine consecutive messages warning")];
}

- (IBAction)changePreference:(id)sender
{
	if (sender == checkBox_combineConsecutive){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
											 forKey:KEY_WEBKIT_COMBINE_CONSECUTIVE
											  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];	
	}
}

- (void)configureControlDimming
{

}

- (IBAction)changeFormat:(id)sender
{
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender tag]]
										 forKey:KEY_WEBKIT_NAME_FORMAT
										  group:PREF_GROUP_WEBKIT_MESSAGE_DISPLAY];
}

- (NSMenu *)_contactNameMenu
{

	NSMenu		*choicesMenu;
	NSMenuItem  *menuItem;
	
	choicesMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:Display_Name];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:ALIAS_SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:Display_Name_Screen_Name];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME_ALIAS
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:Screen_Name_Display_Name];
    [choicesMenu addItem:menuItem];
	
    menuItem = [[[NSMenuItem alloc] initWithTitle:SCREENNAME
                                           target:self
                                           action:@selector(changeFormat:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setTag:Screen_Name];
    [choicesMenu addItem:menuItem];
	
	return choicesMenu;
}

@end

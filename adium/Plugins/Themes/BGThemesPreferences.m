//
//  BGThemesPreferences.m
//  Adium
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//

#import "BGThemesPreferences.h"
#import "BGThemesPlugin.h"
#import "BGThemeManageView.h"

#define ADIUM_APPLICATION_SUPPORT_DIRECTORY	@"~/Library/Application Support/Adium 2.0"
#define THEME_PATH  [[ADIUM_APPLICATION_SUPPORT_DIRECTORY stringByExpandingTildeInPath] stringByAppendingPathComponent:@"Themes"]

@implementation BGThemesPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Other);
}
- (NSString *)label{
    return(@"Themes");
}
- (NSString *)nibName{
    return(@"ThemesPrefs2");
}

- (NSDictionary *)restorablePreferences
{
	return(nil);
}

- (void)viewDidLoad
{
    [themesList setPlugin:themePlugin];
	
    //Configure our buttons
    [createButton setImage:[AIImageUtilities imageNamed:@"plus" forClass:[self class]]];
    [removeButton setImage:[AIImageUtilities imageNamed:@"minus" forClass:[self class]]];    
}

- (void)viewWillClose
{
	[themesList release]; themesList = nil;
}

-(IBAction)createTheme:(id)sender
{
	[NSApp beginSheet:createWindow
	   modalForWindow:[view window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
    [NSApp runModalForWindow:createWindow];
	[NSApp endSheet:createWindow];
	[createWindow orderOut:self];
}

-(IBAction)createAction:(id)sender
{
    if([sender tag] == 0) {
		[NSApp stopModal];
    }
    if([sender tag] == 1) {
        // tell the plugin to create a theme using all the attributes of the create tab
        if([nameField objectValue] == @"" || [nameField objectValue] == @" ") { // sadly doesn't catch all invalid instances :(
            NSRunAlertPanel(@"No theme name entered",@"A valid name is required to save a theme. Please enter one before saving.",@"Return",nil,nil);
        } else {
            [themePlugin createThemeNamed:[nameField objectValue] by:[authorField objectValue] version:[versionField objectValue]];
        }
        [nameField setObjectValue:@""];
        [authorField setObjectValue:@""];
        [versionField setObjectValue:@""];
        [NSApp stopModal];
    }
}

-(void)createDone
{
    [[adium notificationCenter] postNotificationName:Themes_Changed object:nil];
}

-(void)setPlugin:(id)newPlugin
{
    themePlugin = newPlugin;
}

@end

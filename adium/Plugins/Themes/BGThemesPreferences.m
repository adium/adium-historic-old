//
//  BGThemesPreferences.m
//  Adium XCode
//
//  Created by Brian Ganninger on Sat Jan 03 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
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
    [nameField setObjectValue:@""];
    [createStatus setObjectValue:@""];
    [manageStatus setObjectValue:@""];
    [themesList setPlugin:themePlugin];
}

- (void)viewWillClose
{
	[themesList release]; themesList = nil;
}

-(IBAction)createTheme:(id)sender
{
    // tell the plugin to create a theme using all the attributes of the create tab
    if([nameField objectValue] == @"" || [nameField objectValue] == @" ") // sadly doesn't catch all invalid instances :(
    {
        NSRunAlertPanel(@"No theme name entered",@"A valid name is required to save a theme. Please enter one before saving.",@"Return",nil,nil);
    }
    else
    {
        [themePlugin createThemeNamed:[nameField objectValue] by:[authorField objectValue] version:[versionField objectValue]];
    }
}

-(void)createDone
{
    [createStatus setObjectValue:@"New theme created."];
    [[adium notificationCenter] postNotificationName:Themes_Changed object:nil];
}

-(void)applyStart // in theory this should be kind enough to start the UI when applying
{
    [manageStatus setObjectValue:@"Applying theme... one moment please"];
}

-(void)applyDone // in theory this should be kind enough to refresh the UI when done applying
{
    [manageStatus setObjectValue:@"New theme applied. Enjoy."]; 
}

-(void)setPlugin:(id)newPlugin
{
    themePlugin = newPlugin;
}

-(IBAction)generatePreview:(id)sender
{
    NSLog(@"where's my screenshot?");
}

-(IBAction)openThemesFolder:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:THEME_PATH withApplication:@"Finder"];
}

@end

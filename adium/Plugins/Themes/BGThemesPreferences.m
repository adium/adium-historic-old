/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
| This program is free software; you can redistribute it and/or modify it under the terms of the GNU
| General Public License as published by the Free Software Foundation; either version 2 of the License,
| or (at your option) any later version.
|
| This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
| the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
| Public License for more details.
|
| You should have received a copy of the GNU General Public License along with this program; if not,
| write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
\------------------------------------------------------------------------------------------------------ */

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
    [createButton setImage:[NSImage imageNamed:@"plus" forClass:[self class]]];
    [removeButton setImage:[NSImage imageNamed:@"minus" forClass:[self class]]];    
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

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import "AICLPreferences.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"
#import "AIListLayoutWindowController.h"
#import "AIListThemeWindowController.h"

//Handles the interface interaction, and sets preference values
//The outline view plugin is responsible for reading & setting the preferences, as well as observing changes in them

@interface AICLPreferences (PRIVATE)
- (void)configureView;
- (void)changeFont:(id)sender;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
- (void)configureControlDimming;
@end

@implementation AICLPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_ContactList);
}
- (NSString *)label{
    return(@"General Appearance");
}
- (NSString *)nibName{
    return(@"AICLPrefView");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
	
	currentLayoutName = [@"Default" retain];
	currentThemeName = [@"Default" retain];
	[self updateLayouts];
	[self updateThemes];
	
	
#warning cells
	NSCell *dataCell;
		
	dataCell = [[[AIImageTextCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_layout tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
	
	dataCell = [[[AIGradientCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];	
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_layout tableColumnWithIdentifier:@"preview"] setDataCell:dataCell];

	dataCell = [[[AIGradientCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_theme tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
	
	dataCell = [[[AIGradientCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];	
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_theme tableColumnWithIdentifier:@"preview"] setDataCell:dataCell];
	
	
	
	
	//Display
    [self showFont:[[preferenceDict objectForKey:KEY_SCL_FONT] representedFont] inField:textField_fontName];
    [colorWell_contact setColor:[[preferenceDict objectForKey:KEY_SCL_CONTACT_COLOR] representedColor]];
    [colorWell_background setColor:[[preferenceDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColor]];
    [checkBox_showLabels setState:[[preferenceDict objectForKey:KEY_SCL_SHOW_LABELS] boolValue]];
	
    //Grid
    [checkBox_alternatingGrid setState:[[preferenceDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue]];
    [colorWell_grid setColor:[[preferenceDict objectForKey:KEY_SCL_GRID_COLOR] representedColor]];	
}

//Preference view is closing
- (void)viewWillClose
{
	if([colorWell_contact isActive]) [colorWell_contact deactivate];
	if([colorWell_background isActive]) [colorWell_background deactivate];
	if([colorWell_grid isActive]) [colorWell_grid deactivate];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setFont){
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST_DISPLAY];
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*contactListFont = [[preferenceDict objectForKey:KEY_SCL_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_fontName window] setDelegate:self];

        //Setup and show the font panel
        [[textField_fontName window] makeFirstResponder:[textField_fontName window]];
        [fontManager setSelectedFont:contactListFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];
        
    }else if(sender == checkBox_alternatingGrid){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_ALTERNATING_GRID
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];

    }else if(sender == checkBox_showLabels){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_SHOW_LABELS
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];

    }else if(sender == colorWell_contact){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_CONTACT_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];

    }else if(sender == colorWell_grid){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GRID_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];
        
    }else if(sender == colorWell_background){
        [[adium preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_BACKGROUND_COLOR
                                              group:PREF_GROUP_CONTACT_LIST_DISPLAY];    
	}
}

//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];
    
    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_fontName];
    [[adium preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_SCL_FONT group:PREF_GROUP_CONTACT_LIST_DISPLAY];
}

//Display the name of a font in our text field
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField
{
    if(inFont){
        [inTextField setStringValue:[NSString stringWithFormat:@"%@ %g", [inFont fontName], [inFont pointSize]]];
    }else{
        [inTextField setStringValue:@""];
    }
}

#warning newLayout
- (IBAction)spawnLayout:(id)sender
{
	[AIListLayoutWindowController listLayoutOnWindow:[[self view] window]
											withName:[NSString stringWithFormat:@"%@ Copy",currentLayoutName]];
}

- (IBAction)spawnTheme:(id)sender
{
	[AIListThemeWindowController listThemeOnWindow:[[self view] window]
										  withName:[NSString stringWithFormat:@"%@ Copy",currentThemeName]];
}









- (void)updateLayouts
{
	[layoutArray release];
	layoutArray = [[self availableSetsWithExtension:LIST_LAYOUT_EXTENSION fromFolder:LIST_LAYOUT_FOLDER] retain];
	NSLog(@"%@",layoutArray);
	[tableView_layout reloadData];
}

- (void)updateThemes
{
	[themeArray release];
	themeArray = [[self availableSetsWithExtension:LIST_THEME_EXTENSION fromFolder:LIST_THEME_FOLDER] retain];
	NSLog(@"%@",themeArray);
	[tableView_theme reloadData];
}







- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if(tableView == tableView_layout){
		return([layoutArray count]);
	}else{
		return([themeArray count]);
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*column = [tableColumn identifier];
	
	if(tableView == tableView_layout){
		NSDictionary	*layoutDict = [layoutArray objectAtIndex:row];
		
		if([column isEqualToString:@"type"]){
			return(@"-");
		}else if([column isEqualToString:@"name"]){
			return([layoutDict objectForKey:@"name"]);
		}else if([column isEqualToString:@"preview"]){
			return(@"-");
		}
	}else if(tableView == tableView_theme){
		NSDictionary	*themeDict = [themeArray objectAtIndex:row];
		
		if([column isEqualToString:@"type"]){
			return(@"-");
		}else if([column isEqualToString:@"name"]){
			return([themeDict objectForKey:@"name"]);
		}else if([column isEqualToString:@"preview"]){
			return(@"-");
		}
	}

	return(@"-");
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSTableView	*tableView = [notification object];

	if(tableView == tableView_layout){
		NSDictionary	*layoutDict = [layoutArray objectAtIndex:[tableView selectedRow]];
		[self applySet:[layoutDict objectForKey:@"preferences"] toPreferenceGroup:PREF_GROUP_LIST_LAYOUT];
		
	}else if(tableView == tableView_theme){
		NSDictionary	*themeDict = [themeArray objectAtIndex:[tableView selectedRow]];
		[self applySet:[themeDict objectForKey:@"preferences"] toPreferenceGroup:PREF_GROUP_LIST_THEME];
		
	}
}







//Sets ----------------------------
- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[adium resourcePathsForName:folder] objectEnumerator];
	NSString		*resourcePath;
	
    while(resourcePath = [enumerator nextObject]) {
        NSEnumerator 	*fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        NSString		*filePath;
		
        //Find all the message styles
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:extension] == NSOrderedSame){					
				NSString		*themePath = [resourcePath stringByAppendingPathComponent:filePath];
				NSDictionary 	*themeDict = [NSDictionary dictionaryWithContentsOfFile:themePath];
				
				if(themeDict){
					[setArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[filePath stringByDeletingPathExtension], @"name",
						themePath, @"path",
						themeDict, @"preferences",
						nil]];
				}
			}
		}
	}
	
	return(setArray);
}

- (void)applySet:(NSDictionary *)setDictionary toPreferenceGroup:(NSString *)preferenceGroup
{
	NSEnumerator	*enumerator = [setDictionary keyEnumerator];
	NSString		*key;
	
	[[adium preferenceController] delayPreferenceChangedNotifications:YES];
	while(key = [enumerator nextObject]){
		[[adium preferenceController] setPreference:[setDictionary objectForKey:key]
											 forKey:key
											  group:preferenceGroup];
	}
	[[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

#warning bah
+ (BOOL)createSetFromPreferenceGroup:(NSString *)preferenceGroup withName:(NSString *)setName extension:(NSString *)extension inFolder:(NSString *)folder
{
	NSString	*destFolder = [[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:folder];
	NSString	*fileName = [setName stringByAppendingPathExtension:extension];
	NSString	*path = [destFolder stringByAppendingPathComponent:fileName];
	
	if([[[[AIObject sharedAdiumInstance] preferenceController] preferencesForGroup:preferenceGroup] writeToFile:path atomically:NO]){
#warning	[self buildThemesList];
		return(YES);
	}else{
		NSRunAlertPanel(@"Error Saving Theme",
						@"Unable to write file %@ to %@",
						@"Okay",
						nil,
						nil,
						fileName,
						path);
		return(NO);
	}
}







@end

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
#import "AIListThemePreviewCell.h"

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
	
	
	
	//Images
	layoutStandard = [[NSImage imageNamed:@"style-standard" forClass:[self class]] retain];
	layoutBorderless = [[NSImage imageNamed:@"style-borderless" forClass:[self class]] retain];
	layoutMockie = [[NSImage imageNamed:@"style-mockie" forClass:[self class]] retain];
	layoutPillows = [[NSImage imageNamed:@"style-pillows" forClass:[self class]] retain];
	
	//
	[button_themeEdit setTitle:@"Edit"];
	[button_layoutEdit setTitle:@"Edit"];
	
	
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

	dataCell = [[[AIImageTextCell alloc] init] autorelease];
    [dataCell setFont:[NSFont systemFontOfSize:12]];
	[dataCell setIgnoresFocus:YES];
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_theme tableColumnWithIdentifier:@"name"] setDataCell:dataCell];
	
//	dataCell = [[[AIGradientCell alloc] init] autorelease];
//    [dataCell setFont:[NSFont systemFontOfSize:12]];
//	[dataCell setIgnoresFocus:YES];	
//	[dataCell setDrawsGradientHighlight:YES];
//	[[tableView_theme tableColumnWithIdentifier:@"preview"] setDataCell:dataCell];
	
	dataCell = [[[AIListThemePreviewCell alloc] init] autorelease];
	[dataCell setIgnoresFocus:YES];	
	[dataCell setDrawsGradientHighlight:YES];
	[[tableView_theme tableColumnWithIdentifier:@"preview"] setDataCell:dataCell];
	
	
	//
    [tableView_layout setTarget:self];
	[tableView_layout setDoubleAction:@selector(editLayout:)];
    [tableView_theme setTarget:self];
	[tableView_theme setDoubleAction:@selector(editTheme:)];
	
	
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

- (IBAction)editTheme:(id)sender
{
	[AIListThemeWindowController listThemeOnWindow:[[self view] window] withName:currentThemeName];
}
- (IBAction)editLayout:(id)sender
{
	[AIListLayoutWindowController listLayoutOnWindow:[[self view] window] withName:currentLayoutName];
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


//Delete
- (IBAction)deleteLayout:(id)sender
{
	NSDictionary	*selected = [layoutArray objectAtIndex:[tableView_layout selectedRow]];
	NSBeginAlertSheet(AILocalizedString(@"Delete Layout",nil), 
					  AILocalizedString(@"Delete",nil), 
					  AILocalizedString(@"Cancel",nil),
					  @"",
					  [[self view] window],
					  self,
					  @selector(deleteLayoutSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  selected,
					  AILocalizedString(@"Delete the layout \"%@\" from %@?",nil), 
					  [selected objectForKey:@"name"],
					  [selected objectForKey:@"path"]);
}
- (void)deleteLayoutSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSDictionary *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn && contextInfo){
		NSString *path = [contextInfo objectForKey:@"path"];
		if(path){
			[[NSFileManager defaultManager] trashFileAtPath:path];
			[self updateLayouts];
		}
	}
}


//Delete
- (IBAction)deleteTheme:(id)sender
{
	NSDictionary	*selected = [layoutArray objectAtIndex:[tableView_layout selectedRow]];
	NSBeginAlertSheet(AILocalizedString(@"Delete Theme",nil), 
					  AILocalizedString(@"Delete",nil), 
					  AILocalizedString(@"Cancel",nil),
					  @"",
					  [[self view] window],
					  self,
					  @selector(deleteThemeSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  selected,
					  AILocalizedString(@"Delete the theme \"%@\" from %@?",nil), 
					  [selected objectForKey:@"name"],
					  [selected objectForKey:@"path"]);
}
- (void)deleteThemeSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSDictionary *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn && contextInfo){
		NSString *path = [contextInfo objectForKey:@"path"];
		if(path){
			[[NSFileManager defaultManager] trashFileAtPath:path];
			[self updateThemes];
		}
	}
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
		
		if([column isEqualToString:@"name"]){
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

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	NSString	*column = [tableColumn identifier];

	if(tableView == tableView_layout){
		if([column isEqualToString:@"name"]){
			NSImage	*image = nil;
			switch([[[[layoutArray objectAtIndex:row] objectForKey:@"preferences"] objectForKey:KEY_LIST_LAYOUT_WINDOW_STYLE] intValue]){
				case WINDOW_STYLE_STANDARD: image = layoutStandard; break;
				case WINDOW_STYLE_BORDERLESS: image = layoutBorderless; break;
				case WINDOW_STYLE_MOCKIE: image = layoutMockie; break;
				case WINDOW_STYLE_PILLOWS: image = layoutPillows; break;
			}
			[cell setImage:image];
		}else{
			[cell setImage:nil];
		}
	}else if(tableView == tableView_theme){
		if([column isEqualToString:@"preview"]){
			[cell setThemeDict:[[themeArray objectAtIndex:row] objectForKey:@"preferences"]];
		}		
	}
	
}










//Sets ----------------------------
int availableSetSort(NSDictionary *objectA, NSDictionary *objectB, void *context){
	return([[objectA objectForKey:@"name"] caseInsensitiveCompare:[objectB objectForKey:@"name"]]);
}

- (NSArray *)availableSetsWithExtension:(NSString *)extension fromFolder:(NSString *)folder
{
	NSMutableArray	*setArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [[adium resourcePathsForName:folder] objectEnumerator];
	NSString		*resourcePath;
	
    while(resourcePath = [enumerator nextObject]) {
        NSEnumerator 	*fileEnumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:resourcePath] objectEnumerator];
        NSString		*filePath;
		
        //Find all the sets
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
	
	return([setArray sortedArrayUsingFunction:availableSetSort context:nil]);
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

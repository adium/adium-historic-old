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

#import "BGThemesPreferences.h"
#import "BGThemesPlugin.h"

#define THEME_ADIUM_DEFAULT		@"Adium Default"
#define THEME_EXTENSION			@"AdiumTheme"

#define KEY_GROUP_SEPARATOR		@"_BGTheme_"

@interface BGThemesPreferences (PRIVATE)
-(void)buildThemesList;
-(void)saveTheme:(NSMutableDictionary *)saveTheme;
-(void)performApplyTheme:(NSString *)newThemeName;
-(void)createThemeNamed:(NSString *)newName by:(NSString *)newAuthor version:(NSString *)newVersion;
-(void)saveKey:(NSString *)key group:(NSString *)group toDict:(NSMutableDictionary *)dict;
-(void)applyPreferenceFromKey:(NSString *)key inDict:(NSDictionary *)dict;
-(NSString *)selectedThemePath;
- (void)_addThemeDictAtPath:(NSString *)themePath toArray:(NSMutableArray *)inThemes;
@end

@implementation BGThemesPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Other);
}
- (NSString *)label{
    return(AILocalizedString(@"Themes",nil));
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
	themes = nil;
    defaultThemePath = [[[NSBundle bundleForClass:[self class]] pathForResource:THEME_ADIUM_DEFAULT
																		 ofType:THEME_EXTENSION] retain];

    [tableView_themesList setDrawsAlternatingRows:YES];
    [tableView_themesList setTarget:self];
    [tableView_themesList setDoubleAction:@selector(applyTheme:)];
    [self buildThemesList];
	
	//Observe for installation of new styles
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
}

- (void)viewWillClose
{
	[defaultThemePath release]; defaultThemePath = nil;
	[themes release]; themes = nil;
	[[adium notificationCenter] removeObserver:self];	
}

-(IBAction)showCreateNewThemeSheet:(id)sender
{
	//Clear the old values first
	[textField_name setObjectValue:@""];
	[textField_author setObjectValue:@""];
	[textField_version setObjectValue:@""];
	
	[NSApp beginSheet:createWindow
	   modalForWindow:[tableView_themesList window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
	
    [NSApp runModalForWindow:createWindow];
	[NSApp endSheet:createWindow];
	[createWindow orderOut:self];
}

//Called by the modal sheet
-(IBAction)createNewThemeSheetAction:(id)sender
{
    if(sender == button_cancel) {
		[NSApp stopModal];
		
    }else if(sender == button_create) {
        // Create a theme using all the attributes of the create tab
		NSString	*name = [[textField_name stringValue] safeFilenameString];
		
		//Only valid if the safeFilenameString has a length even after removing all spaces (so "  " isn't valid)
		if ([[name compactedString] length]){
			[self createThemeNamed:name by:[textField_author objectValue] version:[textField_version objectValue]];
			
			[NSApp stopModal];
		}else{
            NSRunAlertPanel(AILocalizedString(@"No theme name entered",nil),
							AILocalizedString(@"A valid name is required to save a theme.",nil),
							AILocalizedString(@"Okay",nil)
							,nil,nil);
        }
    }
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if ([[notification object] caseInsensitiveCompare:THEME_EXTENSION] == 0){
		[self buildThemesList];
	}
}

int themeSort(id themeDictA, id themeDictB, void *context)
{
	return ([(NSString *)[themeDictA objectForKey:@"themeName"] caseInsensitiveCompare:(NSString *)[themeDictB objectForKey:@"themeName"]]);
}
		   
- (void)buildThemesList
{
    NSEnumerator		*enumerator, *fileEnumerator;
	NSString			*resourcePath;
	NSString			*filePath;
	NSFileManager		*mgr = [NSFileManager defaultManager];

	//Get all resource paths to search
	enumerator = [[adium resourcePathsForName:THEME_FOLDER_NAME] objectEnumerator];
	
	NSString			*AdiumTheme = THEME_EXTENSION;
	
	[themes release]; themes = [[NSMutableArray alloc] init];

    while(resourcePath = [enumerator nextObject]) {
        fileEnumerator = [[mgr directoryContentsAtPath:resourcePath] objectEnumerator];
        
        //Find all the message styles
        while((filePath = [fileEnumerator nextObject])){
            if([[filePath pathExtension] caseInsensitiveCompare:AdiumTheme] == NSOrderedSame){	
				NSString			*themePath = [resourcePath stringByAppendingPathComponent:filePath];
				
				[self _addThemeDictAtPath:themePath toArray:themes];
			}
		}
	}
	
	if(defaultThemePath){
		[self _addThemeDictAtPath:defaultThemePath toArray:themes];
    }
	
	//Sort themes
    [themes sortUsingFunction:themeSort context:nil];
	
	[self configureControlDimming];
	
    [tableView_themesList reloadData];
}

- (void)_addThemeDictAtPath:(NSString *)themePath toArray:(NSMutableArray *)inThemes
{				
	NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:themePath];
				
	if (themeDict){
		NSMutableDictionary *bookkeepingThemeDict = [NSMutableDictionary dictionary];
		NSString	*themeName = [themeDict objectForKey:@"themeName"];
		NSString	*themeAuthor = [themeDict objectForKey:@"themeAuthor"];
		NSString	*themeVersion = [themeDict objectForKey:@"themeVersion"];
		
		if (themeName) [bookkeepingThemeDict setObject:themeName forKey:@"themeName"];
		if (themeAuthor) [bookkeepingThemeDict setObject:themeAuthor forKey:@"themeAuthor"];
		if (themeVersion) [bookkeepingThemeDict setObject:themeVersion forKey:@"themeVersion"];
		[bookkeepingThemeDict setObject:themePath forKey:@"themePath"];
		
		[inThemes addObject:bookkeepingThemeDict];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [themes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	return ([[themes objectAtIndex:row] objectForKey:[tableColumn identifier]]);
}

- (NSString *)selectedThemePath
{
	int selectedRow = [tableView_themesList selectedRow];

	if (selectedRow != -1) { 
		NSDictionary	*themeDict = [themes objectAtIndex:selectedRow];

		//Themes could soon disappear, so let's make sure this string object remains useable.
		return ([[[themeDict objectForKey:@"themePath"] copy] autorelease]);
	}
	
	return nil;
}

-(IBAction)deleteTheme:(id)sender
{
    NSString *warningText = [NSString stringWithFormat:AILocalizedString(@"Do you really want to permanently delete %@?",nil), [[self selectedThemePath] lastPathComponent]];
    int returnCode = NSRunAlertPanel(AILocalizedString(@"Delete Theme",nil), 
									 warningText, 
									 AILocalizedString(@"Delete",nil), 
									 AILocalizedString(@"Cancel",nil),
									 nil);
	if(returnCode == 1)
	{
		NSString *selectedThemePath = [self selectedThemePath];
		if (selectedThemePath) {
			[[NSFileManager defaultManager] removeFileAtPath:selectedThemePath handler:self];

			[self buildThemesList];
		}
	}
}

- (IBAction)applyTheme:(id)sender
{
    if([themes count] == 0) {
        NSRunAlertPanel(AILocalizedString(@"No themes present",nil),
						AILocalizedString(@"To apply a theme please install one and select it first.",nil),
						AILocalizedString(@"Okay",nil),nil,nil);
    } else {  
		NSString *selectedThemePath = [self selectedThemePath];
		
		//First, create the last theme used theme if we aren't restoring to it
		if (![[[selectedThemePath lastPathComponent] stringByDeletingPathExtension] isEqualToString:AILocalizedString(@"Last Theme Used",nil)] != NSOrderedSame){
			[self createThemeNamed:AILocalizedString(@"Last Theme Used",nil) by:@"Adium" version:@""];			
		}
		
		//Now apply the selected theme
        [self performApplyTheme:selectedThemePath];
    }
}

// -------- private -------------

// Enable/disable controls depending on presence of themes
- (void)configureControlDimming
{
	BOOL enableButtons = [themes count];
	
	[button_apply setEnabled:enableButtons];
	[button_delete setEnabled:enableButtons];
}


-(void)createThemeNamed:(NSString *)newName by:(NSString *)newAuthor version:(NSString *)newVersion
{
    NSArray				*themableKeys;
    NSString			*group;
    NSString			*key;
    NSEnumerator		*keyEnumerator;
    NSMutableDictionary *newTheme = [NSMutableDictionary dictionary];
    NSEnumerator		*enumerator = [[[adium preferenceController] themablePreferences] keyEnumerator];
	
    // set basic attributes of theme
    [newTheme setObject:newName forKey:@"themeName"];
    [newTheme setObject:newAuthor forKey:@"themeAuthor"];
    [newTheme setObject:newVersion forKey:@"themeVersion"];
	
    // build theme from all themable preferences
	NSDictionary	*themablePreferences = [[adium preferenceController] themablePreferences];
	
    while (group = [enumerator nextObject]){
        themableKeys = [themablePreferences objectForKey:group]; 
        keyEnumerator = [themableKeys objectEnumerator];
        while (key = [keyEnumerator nextObject]){
            [self saveKey:key group:group toDict:newTheme];
        }
    }
	
    [self saveTheme:newTheme];
}

-(void)saveTheme:(NSMutableDictionary *)saveTheme
{
    // write a file containing the theme's dictionary to the themes folder   
	NSString *savePath = [THEME_FOLDER_PATH stringByAppendingPathComponent:[[saveTheme objectForKey:@"themeName"] stringByAppendingPathExtension:@"AdiumTheme"]];
	
	if([saveTheme writeToFile:savePath atomically:NO]) {
		//Rebuild the themes list since it changed
		[self buildThemesList];
	}else{
		NSRunAlertPanel(@"Your theme was not saved",@"Adium was unable to save your theme in the Themes directory. Please try again.",@"Okay",nil,nil);
	}
	
}

// ======= efficiency by evands =========
- (void)saveKey:(NSString *)key group:(NSString *)group toDict:(NSMutableDictionary *)dict
{
    [dict setObject:[[adium preferenceController] preferenceForKey:key group:group] forKey:[NSString stringWithFormat:@"%@%@%@",key,KEY_GROUP_SEPARATOR,group]];
}

- (void)applyPreferenceFromKey:(NSString *)key inDict:(NSDictionary *)dict
{
    //Get the components, which should be the key and the group
    NSArray *adiumComponents = [key componentsSeparatedByString:KEY_GROUP_SEPARATOR];
	
    //Verify we got components - two of them, to be exact
    if(adiumComponents && ([adiumComponents count]==2)){
        [[adium preferenceController] setPreference:[dict objectForKey:key]
											 forKey:[adiumComponents objectAtIndex:0]
											  group:[adiumComponents objectAtIndex:1]];
    }
}
/// ====== end efficiency ================

-(void)performApplyTheme:(NSString *)newThemeName
{
    // read in the theme dictionary
    NSDictionary	*updateTheme = [NSDictionary dictionaryWithContentsOfFile:newThemeName];
    NSEnumerator	*updateEnum = [updateTheme keyEnumerator];
    NSString		*key;  
	
    // set every preference by key and then adium will update
    [[adium preferenceController] delayPreferenceChangedNotifications:YES];
    while(key = [updateEnum nextObject])
    {
        [self applyPreferenceFromKey:key inDict:updateTheme];
    }
    [[adium preferenceController] delayPreferenceChangedNotifications:NO];
}

@end

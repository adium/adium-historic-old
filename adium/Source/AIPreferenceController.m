/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIPreferenceController.h"
#import "AIPreferenceViewController.h"
#import "AIPreferenceWindowController.h"
#import "AIPreferenceCategory.h"

#define PREF_FOLDER_NAME 	@"Preferences"		//Name of the preferences folder

@interface AIPreferenceController (PRIVATE)
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName;
@end

@implementation AIPreferenceController

//init
- (void)initController
{
    AIMiniToolbarItem	*toolbarItem;

    categoryArray = [[NSMutableArray alloc] init];
    groupDict = [[NSMutableDictionary alloc] init];
    
    [categoryArray addObject:[AIPreferenceCategory categoryWithName:PREFERENCE_CATEGORY_CONNECTIONS image:[AIImageUtilities imageNamed:@"notfound" forClass:[self class]]]];
    [categoryArray addObject:[AIPreferenceCategory categoryWithName:PREFERENCE_CATEGORY_INTERFACE image:[AIImageUtilities imageNamed:@"notfound" forClass:[self class]]]];

    //Register our toolbar item
    toolbarItem = [[[AIMiniToolbarItem alloc] initWithIdentifier:@"ShowPreferences"] autorelease];
    [toolbarItem setImage:[AIImageUtilities imageNamed:@"settings" forClass:[self class]]];
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(showPreferenceWindow:)];
    [toolbarItem setToolTip:@"Preferences"];
    [toolbarItem setPaletteLabel:@"Open Adium's Preferences"];
    [toolbarItem setEnabled:YES];
    [[AIMiniToolbarCenter defaultCenter] registerItem:toolbarItem];
}

//dealloc
- (void)dealloc
{
    [categoryArray release]; categoryArray = nil;
    [groupDict release]; groupDict = nil;

    [super dealloc];
}

//Return the array of categories
- (NSArray *)categoryArray
{
    return(categoryArray);
}

//Show the preference window
- (IBAction)showPreferenceWindow:(id)sender
{
    [[AIPreferenceWindowController preferenceWindowControllerWithOwner:self] showWindow:nil];
}


//Adding Preferences ----------------------------------------------------------------------
//Add a view to the preferences
- (void)addPreferenceView:(AIPreferenceViewController *)inView
{
    NSString			*destCategoryName;
    AIPreferenceCategory	*destCategory = nil;
    AIPreferenceCategory	*category;
    NSEnumerator		*enumerator;
    
    destCategoryName = [inView categoryName];
    enumerator = [categoryArray objectEnumerator];

    //find the existing category
    while((category = [enumerator nextObject])){
        if([destCategoryName compare:[category name]] == 0){
            destCategory = category;
        }
    }
    
    //if it doesn't exist, create and add the category
    if(!destCategory){
        NSLog(@"unknown category");
    }
    
    [destCategory addView:inView];
}

- (void)openPreferencesToView:(AIPreferenceViewController *)inView
{
    AIPreferenceWindowController	*preferenceWindow = [AIPreferenceWindowController preferenceWindowControllerWithOwner:self];

    [preferenceWindow showView:inView];
    [preferenceWindow showWindow:nil];
}

//Register a dictionary of defaults
- (void)registerDefaults:(NSDictionary *)defaultDict forGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;
    NSEnumerator	*enumerator;
    NSString		*key;

    //Load the group if necessary
    prefDict = [self loadPreferenceGroup:groupName];

    //Set defaults for any value that doesn't have a key
    enumerator = [[defaultDict allKeys] objectEnumerator];
    while((key = [enumerator nextObject])){
        if(![prefDict objectForKey:key]){
            [prefDict setObject:[defaultDict objectForKey:key] forKey:key];
        }
    }
}

//Using Handle Specific Preferences --------------------------------------------------------------
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName handle:(AIContactHandle *)handle
{
    //Search the handle specific prefs for the key
    
    //if not found, get the group and find the base value
    return([[self preferencesForGroup:groupName] objectForKey:inKey]);
}


//Using General Preferences ----------------------------------------------------------------------
//Return a dictionary of preferences
- (NSDictionary *)preferencesForGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;

    //Load the group if necessary
    prefDict = [self loadPreferenceGroup:groupName];
    
    //Return the preference dictionary
    return(prefDict);    
}
 
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;
    NSString 		*path;

    //Load the group if necessary
    prefDict = [self loadPreferenceGroup:groupName];

    //Set the preference and save the dictionary
    [prefDict setObject:value forKey:inKey];

    path = [[owner loginController] userDirectory]; //[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PREF_FOLDER_NAME];
    [prefDict writeToPath:path withName:groupName];    
}


//Internal ----------------------------------------------------------------------
//Load a preference group
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;

    if(!(prefDict = [groupDict objectForKey:groupName])){
        NSString 	*path = [[owner loginController] userDirectory];//[[AIAdium applicationSupportDirectory] stringByAppendingPathComponent:PREF_FOLDER_NAME];

        prefDict = [NSMutableDictionary dictionaryAtPath:path withName:groupName create:YES];
        [groupDict setObject:prefDict forKey:groupName];
    }
    
    return(prefDict);
}

@end



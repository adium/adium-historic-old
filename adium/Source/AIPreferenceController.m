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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"
#import "AIPreferenceController.h"
#import "AIPreferenceWindowController.h"
#import "AIPreferenceCategory.h"

#define PREF_FOLDER_NAME 	@"Preferences"		//Name of the preferences folder

@interface AIPreferenceController (PRIVATE)
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName;
- (void)savePreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)groupName;
@end

@implementation AIPreferenceController

//init
- (void)initController
{
    AIMiniToolbarItem	*toolbarItem;

    paneArray = [[NSMutableArray alloc] init];
    groupDict = [[NSMutableDictionary alloc] init];
    
    [owner registerEventNotification:Preference_GroupChanged displayName:@"Preferences Changed"];

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

//close
- (void)closeController
{
    [AIPreferenceWindowController closeSharedInstance]; //Close the preference window
    
    //Preferences are (always) saved as they're modified, so there's no need to save them here.
}

//dealloc
- (void)dealloc
{
    [paneArray release]; paneArray = nil;
    [groupDict release]; groupDict = nil;

    [super dealloc];
}

//Return the array of preference panes
- (NSArray *)paneArray
{
    return(paneArray);
}

//Show the preference window
- (IBAction)showPreferenceWindow:(id)sender
{
    [[AIPreferenceWindowController preferenceWindowControllerWithOwner:owner] showWindow:nil];
}


//Adding Preferences ----------------------------------------------------------------------
//Add a view to the preferences
- (void)addPreferencePane:(AIPreferencePane *)inPane
{
    //Add the pane to our array
    [paneArray addObject:inPane];
}

- (void)openPreferencesToPane:(AIPreferencePane *)inPane
{
/*    AIPreferenceWindowController	*preferenceWindow = [AIPreferenceWindowController preferenceWindowControllerWithOwner:owner];

    [preferenceWindow showView:inView];
    [preferenceWindow showWindow:nil];*/
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


//Using Handle/Group Specific Preferences --------------------------------------------------------------
//Return an object specific preference.
- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object
{
    return([self preferenceForKey:inKey group:groupName objectKey:[NSString stringWithFormat:@"(%@)", [object UIDAndServiceID]]]);
}

- (id)preferenceForKey:(NSString *)inKey group:(NSString *)groupName objectKey:(NSString *)prefDictKey
{
    NSMutableDictionary	*prefDict, *objectPrefDict;
    id			value = nil;

    //Load the preference
    prefDict = [self loadPreferenceGroup:groupName];
    objectPrefDict = [prefDict objectForKey:prefDictKey];
    if(objectPrefDict) value = [objectPrefDict objectForKey:inKey];

    //If an object specific is not found, use the global preference
    if(!value){
        value = [[self preferencesForGroup:groupName] objectForKey:inKey];
    }

    return(value);
}

//Set an object specific preference
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName object:(AIListObject *)object
{
    [self setPreference:value forKey:inKey group:groupName objectKey:[NSString stringWithFormat:@"(%@)", [object UIDAndServiceID]]];
}

- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName objectKey:(NSString *)prefDictKey
{
    NSMutableDictionary	*prefDict, *objectPrefDict;
    
    //Load the preferences
    prefDict = [self loadPreferenceGroup:groupName];
    objectPrefDict = [[prefDict objectForKey:prefDictKey] mutableCopy];
    if(!objectPrefDict) objectPrefDict = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Set and save the new value
    if(value != nil){
        [objectPrefDict setObject:value forKey:inKey];
    }else{
        [objectPrefDict removeObjectForKey:inKey];
    }
    [prefDict setObject:objectPrefDict forKey:prefDictKey];
    [self savePreferences:prefDict forGroup:groupName];
    
    //Broadcast a group changed notification
    [[owner notificationCenter] postNotificationName:Preference_GroupChanged object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
}
    
//Using General Preferences ----------------------------------------------------------------------
//Return a dictionary of preferences
- (NSDictionary *)preferencesForGroup:(NSString *)groupName
{
    return([self loadPreferenceGroup:groupName]);    
}
 
//Set a preference value
- (void)setPreference:(id)value forKey:(NSString *)inKey group:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;

    //Load the preferences
    prefDict = [self loadPreferenceGroup:groupName];

    //Set and save the new value
    if(value != nil){
        [prefDict setObject:value forKey:inKey];
    }else{
        [prefDict removeObjectForKey:inKey];
    }
    [self savePreferences:prefDict forGroup:groupName];

    //Broadcast a group changed notification
    [[owner notificationCenter] postNotificationName:Preference_GroupChanged object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:groupName,@"Group",inKey,@"Key",nil]];
}

//Internal ----------------------------------------------------------------------
//Load a preference group
- (NSMutableDictionary *)loadPreferenceGroup:(NSString *)groupName
{
    NSMutableDictionary	*prefDict;

    if(!(prefDict = [groupDict objectForKey:groupName])){
        NSString 	*path = [[owner loginController] userDirectory];

        prefDict = [NSMutableDictionary dictionaryAtPath:path withName:groupName create:YES];
        [groupDict setObject:prefDict forKey:groupName];
    }
    
    return(prefDict);
}

//Save a preference group
- (void)savePreferences:(NSMutableDictionary *)prefDict forGroup:(NSString *)groupName
{
    NSString	*path = [[owner loginController] userDirectory];
    
    [prefDict writeToPath:path withName:groupName];
}

@end



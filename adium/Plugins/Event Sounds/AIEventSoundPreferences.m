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

#import "AIEventSoundPreferences.h"
#import "AIEventSoundsPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#define	EVENT_SOUND_PREF_NIB		@"EventSoundPrefs"
#define EVENT_SOUND_PREF_TITLE		@"Sounds"
#define SOUND_MENU_ICON_SIZE		16

#define TABLE_COLUMN_SOUND		@"sound"
#define TABLE_COLUMN_EVENT		@"event"

@interface AIEventSoundPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin;
- (void)configureView;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)saveEventSoundArray;
- (NSMenu *)eventMenu;
- (NSMenu *)soundSetMenu;
- (NSMenu *)soundListMenu;
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row;
- (BOOL)shouldSelectRow:(int)inRow;
@end

@implementation AIEventSoundPreferences

+ (AIEventSoundPreferences *)eventSoundPreferencesWithOwner:(id)inOwner forPlugin:(id)inPlugin
{
    return([[[self alloc] initWithOwner:inOwner forPlugin:inPlugin] autorelease]);
}

//The user selected a sound set
- (IBAction)selectSoundSet:(id)sender
{
    if(sender && [sender representedObject]){ //User selected a soundset        
        [[owner preferenceController] setPreference:[sender representedObject] forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS];
        
    }else{ //User selected 'Custom...'
        [[owner preferenceController] setPreference:@"" forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS]; //Remove the soundset preference
        
    }
}

//Delete the selected sound
- (IBAction)deleteEventSound:(id)sender
{
    //Remove the event
    [eventSoundArray removeObjectAtIndex:[tableView_sounds selectedRow]];

    //Save event sound preferences
    [self saveEventSoundArray];
}

//Plays the selected table view sound
- (IBAction)playSelectedSound:(id)sender
{
    int		selectedRow = [tableView_sounds selectedRow];

    if(selectedRow >= 0 && selectedRow < [eventSoundArray count]){
        NSString	*soundPath = [[eventSoundArray objectAtIndex:selectedRow] objectForKey:KEY_EVENT_SOUND_PATH];

        if(soundPath != nil && [soundPath length] != 0){
            [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
        }
    }
}

//Select a sound from one of the sound popUp menus
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];

    if(soundPath != nil && [soundPath length] != 0){
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
    }
}

//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEventSound:(id)sender
{
    NSMutableDictionary	*soundDict;

    //If the user just modified a premade sound set, save it as their custom set, and switch them to 'custom'.
    if(!usingCustomSoundSet){
        [self saveEventSoundArray];
        [self selectSoundSet:nil];
    }
    
    //Add the new event
    soundDict = [[NSMutableDictionary alloc] init];
    [soundDict setObject:[sender representedObject] forKey:KEY_EVENT_SOUND_NOTIFICATION];
    [soundDict setObject:@"WhatShouldTheDefaultSoundBe!?" forKey:KEY_EVENT_SOUND_PATH];
    [eventSoundArray addObject:soundDict];

    //Save event sound preferences
    [self saveEventSoundArray];
}

//Show a simple info sheet with the extended soundset info
- (IBAction)showSoundSetInfo:(id)sender
{
    NSString	*soundSetPath;
    NSString	*description;
    
    //
    soundSetPath = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS] objectForKey:KEY_EVENT_SOUND_SET];

    //Load the soundset
    if([plugin loadSoundSetAtPath:soundSetPath creator:nil description:&description sounds:nil]){
        //Display the info sheet
        NSBeginInformationalAlertSheet([soundSetPath lastPathComponent],
                                       @"Okay",
                                       nil, nil,
                                       [button_soundSetInfo window],
                                       nil, nil, nil, nil,
                                       description);
        
    } 


}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
    plugin = [inPlugin retain];
    
    //Load the pref view nib
    [NSBundle loadNibNamed:EVENT_SOUND_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:EVENT_SOUND_PREF_TITLE categoryName:PREFERENCE_CATEGORY_SOUNDS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    
    //Configure the view and load our preferences
    [self configureView];
    [self preferencesChanged:nil];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    NSPopUpButtonCell			*dataCell;

    //Build the event menu
    [popUp_addEvent setMenu:[self eventMenu]];

    //Build the soundset menu
    [popUp_soundSet setMenu:[self soundSetMenu]];

    //Configure the 'Sound' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:[self soundListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_sounds tableColumnWithIdentifier:TABLE_COLUMN_SOUND] setDataCell:dataCell];

    //Configure the table view
    [tableView_sounds setDrawsAlternatingRows:YES];
    [tableView_sounds setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_sounds setTarget:self];
    [tableView_sounds setDoubleAction:@selector(playSelectedSound:)];
}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the 'Soundset' changed
        if(notification == nil || [key compare:KEY_EVENT_SOUND_SET] == 0){
            NSString		*soundSetPath;
            NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
            
            //Release the current soundset
            [eventSoundArray release]; eventSoundArray = nil;

            //Load the new soundset
            soundSetPath = [preferenceDict objectForKey:KEY_EVENT_SOUND_SET];
            if(soundSetPath && [soundSetPath length] != 0){ //Soundset
                NSString	*creator;

                //Load the soundset
                if([plugin loadSoundSetAtPath:soundSetPath creator:&creator description:nil sounds:&eventSoundArray]){

                    [popUp_soundSet selectItemWithRepresentedObject:soundSetPath];	//Update the soundset popUp
                    [textField_creator setStringValue:creator];			//Update the creator string
                    [button_soundSetInfo setEnabled:YES]; 				//Enable the info button

                    usingCustomSoundSet = NO;
                } 

                
            }else{ //Custom
                eventSoundArray = [[preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] mutableCopy]; //Load the user's custom set
                if(!eventSoundArray) eventSoundArray = [[NSMutableArray alloc] init];
                
                [popUp_soundSet selectItemAtIndex:0];				//Update the soundset popUp
                [textField_creator setStringValue:@""];				//Blank the creator string
                [button_soundSetInfo setEnabled:NO]; 				//Disable the info button

                usingCustomSoundSet = YES;

            }
        }

        //Update the outline view
        [tableView_sounds reloadData];
    }
}

//Save the event sounds
- (void)saveEventSoundArray
{
    [[owner preferenceController] setPreference:eventSoundArray forKey:KEY_EVENT_CUSTOM_SOUNDSET group:PREF_GROUP_SOUNDS];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*eventDict;
    NSMenu		*eventMenu = [[NSMenu alloc] init];

    //Add the static/display menu item
    [eventMenu addItemWithTitle:@"Add EventÉ" target:nil action:nil keyEquivalent:@""];

    //Add a menu item for each event
    enumerator = [[owner eventNotifications] objectEnumerator];
    while((eventDict = [enumerator nextObject])){
        NSMenuItem	*menuItem;

        menuItem = [[[NSMenuItem alloc] initWithTitle:[eventDict objectForKey:KEY_EVENT_DISPLAY_NAME]
                                               target:self
                                               action:@selector(newEventSound:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[eventDict objectForKey:KEY_EVENT_NOTIFICATION]];

        [eventMenu addItem:menuItem];
    }

    return(eventMenu);
}

//Builds and returns a sound set menu
- (NSMenu *)soundSetMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundSetMenu = [[NSMenu alloc] init];

    [soundSetMenu addItemWithTitle:@"CustomÉ" target:self action:@selector(selectSoundSet:) keyEquivalent:@""]; //'Custom'
    [soundSetMenu addItem:[NSMenuItem separatorItem]]; //Divider
    
    enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSString	*setPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        NSMenuItem	*menuItem;
        NSString	*soundSetFile;

        //Ensure this folder contains a soundset file (Otherwise, we ignore it)
        soundSetFile = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.txt", setPath, [setPath lastPathComponent]]];
        if(soundSetFile && [soundSetFile length] != 0){

            //Add a menu item for the set
            menuItem = [[[NSMenuItem alloc] initWithTitle:[setPath lastPathComponent]
                                                   target:self
                                                   action:@selector(selectSoundSet:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:[soundSetDict objectForKey:KEY_SOUND_SET]];
            [soundSetMenu addItem:menuItem];

        }
    }

    return(soundSetMenu);
}

//Builds and returns a sound list menu
- (NSMenu *)soundListMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundMenu = [[NSMenu alloc] init];
    
    enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSEnumerator	*soundEnumerator;
        NSString	*soundSetPath;
        NSString	*soundPath;
        NSMenuItem	*menuItem;

        //Add an item for the set
        if([soundMenu numberOfItems] != 0){
            [soundMenu addItem:[NSMenuItem separatorItem]]; //Divider
        }
        soundSetPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        menuItem = [[[NSMenuItem alloc] initWithTitle:[soundSetPath lastPathComponent]
                                               target:nil
                                               action:nil
                                        keyEquivalent:@""] autorelease];
        [menuItem setEnabled:NO];
        [soundMenu addItem:menuItem];

        //Add an item for each sound
        soundEnumerator = [[soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS] objectEnumerator];
        while((soundPath = [soundEnumerator nextObject])){
            NSImage	*soundImage;
            NSString	*soundTitle;

            //Get the sound title and image
            soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
            soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
            [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];
            
            //Build the menu item
            menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
                                                   target:self
                                                   action:@selector(selectSound:)
                                            keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:soundPath];
            [menuItem setImage:soundImage];

            [soundMenu addItem:menuItem];
        }
    }

    [soundMenu setAutoenablesItems:NO];
    
    return(soundMenu);
}



//TableView datasource --------------------------------------------------------
//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([eventSoundArray count]);
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*soundDict;
        NSString	*notification;
        NSDictionary	*eventDict;
        NSString	*displayName;

        //Get the notification string
        soundDict = [eventSoundArray objectAtIndex:row];
        notification = [soundDict objectForKey:KEY_EVENT_SOUND_NOTIFICATION];

        //Get that notification's display name
        eventDict = [[owner eventNotifications] objectForKey:notification];
        displayName = [eventDict objectForKey:KEY_EVENT_DISPLAY_NAME];
                    
        return(displayName ? displayName : notification);
        
    }else{
        return(nil);

    }
}

//
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
    
    if([identifier compare:TABLE_COLUMN_SOUND] == 0){
        NSMenuItem		*selectedMenuItem;
        NSMutableDictionary	*selectedSoundDict;
        NSString		*newSoundPath;
    
        //
        selectedMenuItem = [[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedSoundDict = [[eventSoundArray objectAtIndex:row] mutableCopy];
        newSoundPath = [selectedMenuItem representedObject];

        if([newSoundPath compare:[selectedSoundDict objectForKey:KEY_EVENT_SOUND_PATH]] != 0){ //Ignore a duplicate selection
            //If the user just modified a premade sound set, save it as their custom set, and switch them to 'custom'.
            if(!usingCustomSoundSet){
                [self saveEventSoundArray];
                [self selectSoundSet:nil];
            }

            //Set the new sound path
            [selectedSoundDict setObject:newSoundPath forKey:KEY_EVENT_SOUND_PATH];
            [eventSoundArray replaceObjectAtIndex:row withObject:selectedSoundDict];

            //Save event sound preferences
            [self saveEventSoundArray];
        }
    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_SOUND] == 0){
        [cell selectItemWithRepresentedObject:[[eventSoundArray objectAtIndex:row] objectForKey:KEY_EVENT_SOUND_PATH]];
    }
}

//
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEventSound:nil]; //Delete it
}

//
- (BOOL)shouldSelectRow:(int)inRow
{
    [button_delete setEnabled:(inRow != -1)]; //Enable/disable the delete button correctly

    return(YES);
}

@end




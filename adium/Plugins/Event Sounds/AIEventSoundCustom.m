//
//  AIEventSoundCustom.m
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIEventSoundCustom.h"
#import "AIEventSoundsPlugin.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "AIAdium.h"

#define NIB_EVENT_SOUND_CUSTOM		@"EventSoundCustomPanel"
#define	TABLE_COLUMN_SOUND		@"sound"
#define	TABLE_COLUMN_EVENT		@"event"
#define SOUND_MENU_ICON_SIZE		16
#define ADD_EVENT_MENU_ITEM		@"Add EventÉ"

@interface AIEventSoundCustom (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner;
- (NSMenu *)soundListMenu;
- (NSMenu *)eventMenu;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)saveEventSoundArray;
@end

@implementation AIEventSoundCustom

//
AIEventSoundCustom	*sharedInstance = nil;
+ (id)showEventSoundCustomPanelWithOwner:(id)inOwner
{
    if(!sharedInstance){
        sharedInstance = [[self alloc] initWithWindowNibName:NIB_EVENT_SOUND_CUSTOM owner:inOwner];
    }
    return(sharedInstance);
}

//
+ (void)closeEventSoundCustomPanel
{
    if(sharedInstance){
        [sharedInstance closeWindow:nil];
        [sharedInstance release]; sharedInstance = nil;
    }
}

//
- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)inOwner
{
    [super initWithWindowNibName:windowNibName owner:self];

    owner = inOwner;
    firstSound = nil;
    [self showWindow:nil];
    
    return(self);
}

//
- (void)dealloc
{
    [firstSound release];
    [eventSoundArray release]; eventSoundArray = nil;
    
    [super dealloc];
}

//
- (void)windowDidLoad
{
    NSPopUpButtonCell		*dataCell;

    //Center
    [[self window] center];

    //
    [popUp_addEvent setMenu:[self eventMenu]];

    //Configure the 'Sound' table column
    dataCell = [[[AITableViewPopUpButtonCell alloc] init] autorelease];
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

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Close this window
- (IBAction)closeWindow:(id)sender
{
    if([self windowShouldClose:nil]){
        [[self window] close];
    }
}

//Called as the window closes
- (BOOL)windowShouldClose:(id)sender
{
    //
    [[owner notificationCenter] removeObserver:self];

    //Clean up shared instance
    [self autorelease];
    sharedInstance = nil;

    return(YES);
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

    //Add the new event
    soundDict = [[NSMutableDictionary alloc] init];
    [soundDict setObject:[sender representedObject] forKey:KEY_EVENT_SOUND_NOTIFICATION];
    [soundDict setObject:firstSound forKey:KEY_EVENT_SOUND_PATH];
    [eventSoundArray addObject:soundDict];

    //Save event sound preferences
    [self saveEventSoundArray];
}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];

        //Load the user's custom set
        [eventSoundArray release];
        eventSoundArray = [[preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] mutableCopy];
        if(!eventSoundArray) eventSoundArray = [[NSMutableArray alloc] init];

        //Update the outline view
        [tableView_sounds reloadData];
    }
}

//Save the event sounds
- (void)saveEventSoundArray
{
    //save the custom soundset
    [[owner preferenceController] setPreference:eventSoundArray forKey:KEY_EVENT_CUSTOM_SOUNDSET group:PREF_GROUP_SOUNDS];
    
    //Remove the soundset preference because we now have a custom one
    [[owner preferenceController] setPreference:@"" forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS];
}

//Builds and returns an event menu
- (NSMenu *)eventMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*eventDict;
    NSMenu		*eventMenu = [[NSMenu alloc] init];

    //Add the static/display menu item
    [eventMenu addItemWithTitle:ADD_EVENT_MENU_ITEM target:nil action:nil keyEquivalent:@""];

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

            //Keep track of our first sound (used when creating a new event)
            if(!firstSound) firstSound = [soundPath retain];

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
        selectedMenuItem = (NSMenuItem *)[[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedSoundDict = [[eventSoundArray objectAtIndex:row] mutableCopy];
        newSoundPath = [selectedMenuItem representedObject];

        if([newSoundPath compare:[selectedSoundDict objectForKey:KEY_EVENT_SOUND_PATH]] != 0){ //Ignore a duplicate selection
            //If the user just modified a premade sound set, save it as their custom set, and switch them to 'custom'.
            //[self saveEventSoundArray];

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


@end


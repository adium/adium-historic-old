//
//  AIDockBehaviorPreferences.m
//  Adium
//
//  Created by Adam Atlas on Wed Jan 29 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AIDockBehaviorPreferences.h"
#import "AIDockBehaviorPlugin.h"

#define DOCK_BEHAVIOR_PREF_NIB		@"DockBehaviorPreferences"
#define DOCK_BEHAVIOR_PREF_TITLE	@"Dock Behavior"

#define TABLE_COLUMN_BEHAVIOR		@"behavior"
#define TABLE_COLUMN_EVENT		@"event"

@interface AIDockBehaviorPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)preferencesChanged:(NSNotification *)notification;
- (NSMenu *)behaviorListMenu;
- (NSMenu *)behaviorSetMenu;
- (NSMenu *)eventMenu;
- (void)saveDockEventArray;
@end

@implementation AIDockBehaviorPreferences

+ (id)dockBehaviorPreferencesWithOwner:(id)inOwner 
{
    return [[[self alloc] initWithOwner:inOwner] autorelease];
}

//The user selected a dock behavior preset
- (IBAction)selectBehaviorSet:(id)sender
{
    if(sender && [sender representedObject]){ //User selected a behavior set
//        [[owner preferenceController] setPreference:[sender representedObject] forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS];

    }else{ //User selected 'Custom...'
//        [[owner preferenceController] setPreference:@"" forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS]; //Remove the soundset preference

    }
}

//Delete the selected event
- (IBAction)deleteEvent:(id)sender
{
    //Remove the event
    [dockEventArray removeObjectAtIndex:[tableView_events selectedRow]];

    //Save event sound preferences
    [self saveDockEventArray];
}

//Select a behavior from one of the event popUp menus
//- (IBAction)selectBehavior:(id)sender
//{
/*    NSString	*soundPath = [sender representedObject];

    if(soundPath != nil && [soundPath length] != 0){
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
    }*/
//}

//Called by the event popUp menu (Inserts a new event)
- (IBAction)newEvent:(id)sender
{
    NSMutableDictionary	*eventDict;

    //If the user just modified a premade behavior set, save it as their custom set, and switch them to 'custom'.
    if(!usingCustomBehaviorSet){
        [self saveDockEventArray];
        [self selectBehaviorSet:nil];
    }

    //Add the new event
    eventDict = [[NSMutableDictionary alloc] init];
    [eventDict setObject:[sender representedObject] forKey:KEY_DOCK_EVENT_NOTIFICATION];
    [eventDict setObject:[NSNumber numberWithInt:0] forKey:KEY_DOCK_EVENT_BEHAVIOR];
    [dockEventArray addObject:eventDict];

    //Save event preferences
    [self saveDockEventArray];
}





//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:DOCK_BEHAVIOR_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:DOCK_BEHAVIOR_PREF_TITLE categoryName:PREFERENCE_CATEGORY_INTERFACE view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Configure the view and load our preferences
    [self configureView];
    [self preferencesChanged:nil];

    return self;
}

//configure our view
- (void)configureView
{
    NSPopUpButtonCell			*dataCell;

    //Build the event menu
    [popUp_addEvent setMenu:[self eventMenu]];

    //Build the behavior set menu
    [popUp_behaviorSet setMenu:[self behaviorSetMenu]];

    //Configure the 'Behavior' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:[self behaviorListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_events tableColumnWithIdentifier:TABLE_COLUMN_BEHAVIOR] setDataCell:dataCell];

    //Configure the table view
    [tableView_events setDrawsAlternatingRows:YES];
    [tableView_events setAlternatingRowColor:[NSColor colorWithCalibratedRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
    [tableView_events setTarget:self];
//    [tableView_sounds setDoubleAction:@selector(playSelectedSound:)];

}

//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_DOCK_BEHAVIOR] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];

        //If the 'Soundset' changed
/*        if(notification == nil || [key compare:KEY_EVENT_SOUND_SET] == 0){
            NSString		*soundSetPath;
            NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];

            //Release the current soundset
            [eventSoundArray release]; eventSoundArray = nil;

            //Load the new soundset
            soundSetPath = [preferenceDict objectForKey:KEY_EVENT_SOUND_SET];
            if(soundSetPath && [soundSetPath length] != 0){ //Soundset
                NSString	*creator;

                [plugin loadSoundSetAtPath:soundSetPath creator:&creator description:nil sounds:&eventSoundArray]; //Load the soundset
                [popUp_soundSet selectItemWithRepresentedObject:soundSetPath];	//Update the soundset popUp
                [textField_creator setStringValue:creator];			//Update the creator string
                [button_soundSetInfo setEnabled:YES]; 				//Enable the info button

                usingCustomSoundSet = NO;

            }else{ //Custom
                eventSoundArray = [[preferenceDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] mutableCopy]; //Load the user's custom set
                if(!eventSoundArray) eventSoundArray = [[NSMutableArray alloc] init];

                [popUp_soundSet selectItemAtIndex:0];				//Update the soundset popUp
                [textField_creator setStringValue:@""];				//Blank the creator string
                [button_soundSetInfo setEnabled:NO]; 				//Disable the info button

                usingCustomSoundSet = YES;

            }
        }*/

        //Update the outline view
        [tableView_events reloadData];
    }
}

//Save the event sounds
- (void)saveDockEventArray
{
    [[owner preferenceController] setPreference:dockEventArray forKey:KEY_EVENT_CUSTOM_DOCK_BEHAVIOR group:PREF_GROUP_DOCK_BEHAVIOR];
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
                                               action:@selector(newEvent:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[eventDict objectForKey:KEY_EVENT_NOTIFICATION]];

        [eventMenu addItem:menuItem];
    }

    return(eventMenu);
}

//Builds and returns a behavior set menu
- (NSMenu *)behaviorSetMenu
{
//    NSEnumerator	*enumerator;
//    NSDictionary	*soundSetDict;
    NSMenu		*behaviorSetMenu = [[NSMenu alloc] init];

    [behaviorSetMenu addItemWithTitle:@"CustomÉ" target:self action:@selector(selectBehaviorSet:) keyEquivalent:@""]; //'Custom'
    [behaviorSetMenu addItem:[NSMenuItem separatorItem]]; //Divider

/*    enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSString	*setTitle = [[soundSetDict objectForKey:KEY_SOUND_SET] lastPathComponent];
        NSMenuItem	*menuItem;

        menuItem = [[[NSMenuItem alloc] initWithTitle:setTitle
                                               target:self
                                               action:@selector(selectSoundSet:)
                                        keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:[soundSetDict objectForKey:KEY_SOUND_SET]];
        [soundSetMenu addItem:menuItem];
    }*/

    return(behaviorSetMenu);
}

//Builds and returns a dock behavior list menu
- (NSMenu *)behaviorListMenu
{
    NSMenuItem	*menuItem;
//    NSEnumerator	*enumerator;
//    NSDictionary	*soundSetDict;
    NSMenu		*behaviorMenu = [[NSMenu alloc] init];



    //Build the menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Bounce Once"
                                           target:self
                                           action:@selector(selectBehavior:)
                                    keyEquivalent:@""] autorelease];
    [behaviorMenu addItem:menuItem];

    
    //Build the menu item
    menuItem = [[[NSMenuItem alloc] initWithTitle:@"Bounce Repeatedly"
                                           target:self
                                           action:@selector(selectBehavior:)
                                    keyEquivalent:@""] autorelease];
    [behaviorMenu addItem:menuItem];
    


    /*
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
*/
    [behaviorMenu setAutoenablesItems:NO];

    return(behaviorMenu);
}




//TableView datasource --------------------------------------------------------
//
- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return([dockEventArray count]);
}

//
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_EVENT] == 0){
        NSDictionary	*behaviorDict;
        NSString	*notification;
        NSDictionary	*eventDict;
        NSString	*displayName;

        //Get the notification string
        behaviorDict = [dockEventArray objectAtIndex:row];
        notification = [behaviorDict objectForKey:KEY_DOCK_EVENT_NOTIFICATION];

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

    if([identifier compare:TABLE_COLUMN_BEHAVIOR] == 0){
/*        NSMenuItem		*selectedMenuItem;
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
        }*/
    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];

    if([identifier compare:TABLE_COLUMN_BEHAVIOR] == 0){
//        [cell selectItemWithRepresentedObject:[[eventSoundArray objectAtIndex:row] objectForKey:KEY_EVENT_SOUND_PATH]];
    }
}

//
- (BOOL)shouldSelectRow:(int)inRow
//- (void)tableViewSelectionIsChanging:(NSNotification *)notification;
{
    [button_delete setEnabled:(inRow != -1)]; //Enable/disable the delete button correctly

    return(YES);
}





/*- (id)initWithOwner:(id)inOwner forPlugin:(id)inPlugin
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];
    plugin = [inPlugin retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:EVENT_SOUND_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:EVENT_SOUND_PREF_TITLE categoryName:PREFERENCE_CATEGORY_OTHER view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Observer preference changes
    [[owner notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];

    //Configure the view and load our preferences
    [self configureView];
    [self preferencesChanged:nil];

    return(self);
}*/










/*
- (IBAction)changePreference:(id)sender 
{
    [self configureDimming]; // this has to go first.
    
    if(sender == enableBouncingCheckBox)
    {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT
                                        group:PREF_GROUP_DOCK_BEHAVIOR];
    }
    else if(sender == bounceField)
    {	
        
    if([sender intValue] >= 0)
        {
            [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            NSBeep();
            [sender setSelected: YES];
        }
    }
    else if(sender == delayField)
    {    
        if([sender doubleValue] >= 0)
        {
            [[owner preferenceController] 
                setPreference:[NSNumber numberWithDouble:[sender doubleValue]]
                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY
                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            NSBeep();
            [sender setSelected: YES];
        }
    }
    else if(sender == bounceMatrix)
    {
        if([[sender selectedCell] tag] == 0) //forever mode
        {
            [[owner preferenceController] setPreference:[NSNumber numberWithInt:-1]
                                            forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM
                                            group:PREF_GROUP_DOCK_BEHAVIOR];
        }
        else
        {
            [[sender window] makeFirstResponder:bounceField];
        }
    }
    
    else if(sender == enableAnimationCheckBox)
    {
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                        forKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_ANIMATE
                                        group:PREF_GROUP_DOCK_BEHAVIOR];
    }
} 

//-------Private----------------------------------

- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:DOCK_BEHAVIOR_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:DOCK_BEHAVIOR_PREF_TITLE categoryName:PREFERENCE_CATEGORY_INTERFACE view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load the preferences, and configure our view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_DOCK_BEHAVIOR] retain];
    [self configureView];

    return self;
}

//configure our view
- (void)configureView 
{
    [enableBouncingCheckBox setState:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT] boolValue]];
    
    if([[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue] == -1)
    {
        [bounceMatrix selectCellWithTag:0];
    }
    else
    {
        [bounceMatrix selectCellWithTag:1];
        [bounceField setIntValue: 
            [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_NUM] intValue]];
    }
    
    [delayField setDoubleValue:
        [[preferenceDict objectForKey:PREF_DOCK_BOUNCE_ON_RECEIVE_CONTENT_DELAY] doubleValue]];
    
    [self configureDimming];
}

//enable and disable the items
- (void)configureDimming
{	
    [delayField setEnabled:([enableBouncingCheckBox state] || [enableAnimationCheckBox state])];
    [bounceMatrix setEnabled:([enableBouncingCheckBox state] || [enableAnimationCheckBox state])];
    [bounceField setEnabled:
        ([[bounceMatrix selectedCell] tag] == 1 
        && ([enableBouncingCheckBox state] || [enableAnimationCheckBox state]))];
}
*/
@end

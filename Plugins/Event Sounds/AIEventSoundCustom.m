//
//  AIEventSoundCustom.m
//  Adium
//
//  Created by Adam Iser on Sun Oct 05 2003.
//

#import "AIEventSoundCustom.h"
#import "AIEventSoundsPlugin.h"

#define NIB_EVENT_SOUND_CUSTOM		@"EventSoundCustomPanel"
#define	TABLE_COLUMN_SOUND			@"sound"
#define	TABLE_COLUMN_EVENT			@"event"
#define ADD_EVENT_MENU_ITEM			AILocalizedString(@"Add Event...",nil)


@interface AIEventSoundCustom (PRIVATE)
- (id)initWithWindowNibName:(NSString *)windowNibName;
- (NSMenu *)soundListMenu;
- (NSMenu *)eventMenu;
- (void)preferencesChanged:(NSNotification *)notification;
- (void)saveEventSoundArray;
@end

@implementation AIEventSoundCustom

//
AIEventSoundCustom	*sharedEventSoundInstance = nil;
+ (id)showEventSoundCustomPanel
{
    if(!sharedEventSoundInstance){
        sharedEventSoundInstance = [[self alloc] initWithWindowNibName:NIB_EVENT_SOUND_CUSTOM];
    }
    return(sharedEventSoundInstance);
}

//
+ (void)closeEventSoundCustomPanel
{
    if(sharedEventSoundInstance){
        [sharedEventSoundInstance closeWindow:nil];
        [sharedEventSoundInstance release]; sharedEventSoundInstance = nil;
    }
}

//
- (id)initWithWindowNibName:(NSString *)windowNibName
{
    [super initWithWindowNibName:windowNibName];
	
    firstSound = nil;
    soundMenu_cached = nil;
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
    [popUp_addEvent setMenu:[[adium contactAlertsController] menuOfEventsWithTarget:self forGlobalMenu:YES]];
	
    //Configure the table view
    [tableView_sounds setDrawsAlternatingRows:YES];
    [tableView_sounds setTarget:self];
    [tableView_sounds setDoubleAction:@selector(playSelectedSound:)];
	
    //Observer preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
    
    //Configure the 'Sound' table column
    dataCell = [[AITableViewPopUpButtonCell alloc] init];
    [dataCell setMenu:[self soundListMenu]];
    [dataCell setControlSize:NSSmallControlSize];
    [dataCell setFont:[NSFont menuFontOfSize:11]];
    [dataCell setBordered:NO];
    [[tableView_sounds tableColumnWithIdentifier:TABLE_COLUMN_SOUND] setDataCell:dataCell];
	[dataCell release];
    
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
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
    //Clean up shared instance
    [self autorelease];
    sharedEventSoundInstance = nil;
	
    return(YES);
}


//Delete the selected sound
- (IBAction)deleteEventSound:(id)sender
{
	int row = [tableView_sounds selectedRow];
	
	//Proceed if a row is selected
	if (row != -1) {
		//Remove the event
		[eventSoundArray removeObjectAtIndex:[tableView_sounds selectedRow]];
		
		//Save event sound preferences
		[self saveEventSoundArray];
	}
}

//Plays the selected table view sound
- (IBAction)playSelectedSound:(id)sender
{
    int		selectedRow = [tableView_sounds selectedRow];
	
    if(selectedRow >= 0 && selectedRow < [eventSoundArray count]){
        NSString	*soundPath = [[eventSoundArray objectAtIndex:selectedRow] objectForKey:KEY_EVENT_SOUND_PATH];
		
        if(soundPath != nil && [soundPath length] != 0){
            [[adium soundController] playSoundAtPath:[soundPath stringByExpandingBundlePath]]; //Play the sound
        }
    }
}

//Called by the event popUp menu (Inserts a new event)
- (IBAction)selectEvent:(id)sender
{
    NSMutableDictionary	*soundDict;
	
    //Add the new event
    soundDict = [[NSMutableDictionary alloc] init];
    [soundDict setObject:[sender representedObject] forKey:KEY_EVENT_SOUND_EVENT_ID];
    [soundDict setObject:[firstSound stringByCollapsingBundlePath] forKey:KEY_EVENT_SOUND_PATH];
    [eventSoundArray addObject:soundDict];
	
    //Save event sound preferences
    [self saveEventSoundArray];
}

//Called when the preferences change, update our preference display
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//Load the user's custom set
	[eventSoundArray release];
	eventSoundArray = [[prefDict objectForKey:KEY_EVENT_CUSTOM_SOUNDSET] mutableCopy];
	if(!eventSoundArray) eventSoundArray = [[NSMutableArray alloc] init];
	
	//Update the outline view
	[tableView_sounds reloadData];
}

//Save the event sounds
- (void)saveEventSoundArray
{
    //save the custom soundset
    [[adium preferenceController] setPreference:eventSoundArray forKey:KEY_EVENT_CUSTOM_SOUNDSET group:PREF_GROUP_SOUNDS];
    
    //Remove the soundset preference because we now have a custom one
    [[adium preferenceController] setPreference:@"" forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS];
}

//Builds and returns a sound list menu
- (NSMenu *)soundListMenu
{
    NSEnumerator	*enumerator;
    
    if (!soundMenu_cached)
    {
        NSDictionary	*soundSetDict;
        NSMenu		*soundMenu = [[NSMenu alloc] init];
        NSMenuItem	*menuItem;
        
        enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
        while((soundSetDict = [enumerator nextObject])){
            NSEnumerator    *soundEnumerator;
            NSString        *soundSetPath;
            NSString        *soundPath;
            NSArray         *soundSetContents = [soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS];
            //Add an item for the set
            if (soundSetContents && [soundSetContents count]) {
                if([soundMenu numberOfItems] != 0){
                    [soundMenu addItem:[NSMenuItem separatorItem]]; //Divider
                }
                soundSetPath = [soundSetDict objectForKey:KEY_SOUND_SET];
                menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[soundSetPath lastPathComponent]
																				 target:nil
																				 action:nil
																		  keyEquivalent:@""] autorelease];
                [menuItem setEnabled:NO];
                [soundMenu addItem:menuItem];
                
                //Add an item for each sound
                soundEnumerator = [soundSetContents objectEnumerator];
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
                    menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
																					 target:self
																					 action:@selector(selectSound:)
																			  keyEquivalent:@""] autorelease];
                    [menuItem setRepresentedObject:[soundPath stringByCollapsingBundlePath]];
                    [menuItem setImage:soundImage];
                    
                    [soundMenu addItem:menuItem];
                }
            }
        }
        //Add the Other... item
        menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER_ELLIPSIS
																		 target:self
																		 action:@selector(selectSound:)
																  keyEquivalent:@""] autorelease];            
        [soundMenu addItem:menuItem];
        
        [soundMenu setAutoenablesItems:NO];
        soundMenu_cached = soundMenu;
    }
    
    //Add custom sounds to the menu as needed
    NSDictionary * soundRowDict;
    enumerator = [eventSoundArray objectEnumerator];
    while (soundRowDict = [enumerator nextObject]) {
        //add it if it's not already in the menu
        NSString *soundPath = [soundRowDict objectForKey:KEY_EVENT_SOUND_PATH];
        if(soundPath && ([soundPath length] != 0) && [soundMenu_cached indexOfItemWithRepresentedObject:soundPath] == -1) {
            NSImage	*soundImage;
            NSString	*soundTitle;
            NSMenuItem	*menuItem;
			
            //Add an "Other" header if necessary
            if([soundMenu_cached indexOfItemWithTitle:OTHER] == -1) {
                [soundMenu_cached insertItem:[NSMenuItem separatorItem] atIndex:([soundMenu_cached numberOfItems]-1)]; //Divider
                menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER
																				 target:nil
																				 action:nil
																		  keyEquivalent:@""] autorelease];
                [menuItem setEnabled:NO];
                [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
            }
            
            //Get the sound title and image
            soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
            soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
            [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];
            
            //Build the menu item
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
																			 target:self
																			 action:@selector(selectSound:)
																	  keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:soundPath];
            [menuItem setImage:soundImage];
            
            [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
        }
    }
    
    return(soundMenu_cached);
}
//Select a sound from one of the sound popUp menus
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];
    
    if(soundPath != nil && [soundPath length] != 0){
        [[adium soundController] playSoundAtPath:[soundPath stringByExpandingBundlePath]]; //Play the sound
    } else { //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel 
            beginSheetForDirectory:nil
                              file:nil
                             types:[NSSound soundUnfilteredFileTypes] //allow all the sounds NSSound understands
                    modalForWindow:[self window]
                     modalDelegate:self
                    didEndSelector:@selector(concludeOtherPanel:returnCode:contextInfo:)
                       contextInfo:nil];        
    }
}
//Finish up the Other... panel
- (void)concludeOtherPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton){
        NSString			*soundPath;
		NSMutableDictionary	*selectedSoundDict;
        NSPopUpButtonCell	*dataCell;
		
		soundPath = [[panel filenames] objectAtIndex:0];
        
        [[adium soundController] playSoundAtPath:soundPath]; //Play the sound
		
        //Set the new sound path
        selectedSoundDict = [[eventSoundArray objectAtIndex:setRow] mutableCopy];
        [selectedSoundDict setObject:[soundPath stringByCollapsingBundlePath] forKey:KEY_EVENT_SOUND_PATH];
		
        [eventSoundArray replaceObjectAtIndex:setRow withObject:selectedSoundDict];
        
		[selectedSoundDict release];
		
        //Save event sound preferences
        [self saveEventSoundArray];
        
        //Reconfigure the 'Sound' table column
        dataCell = [[AITableViewPopUpButtonCell alloc] init];
        [dataCell setMenu:[self soundListMenu]];
        [dataCell setControlSize:NSSmallControlSize];
        [dataCell setFont:[NSFont menuFontOfSize:11]];
        [dataCell setBordered:NO];
        [[tableView_sounds tableColumnWithIdentifier:TABLE_COLUMN_SOUND] setDataCell:dataCell];
		[dataCell release];
    }
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
	
    if([identifier isEqualToString:TABLE_COLUMN_EVENT]){
        NSDictionary	*soundDict;
        NSString		*eventID;
		
        //Get the notification string
        soundDict = [eventSoundArray objectAtIndex:row];
        eventID = [soundDict objectForKey:KEY_EVENT_SOUND_EVENT_ID];
		
        //Get that notification's display name
        return([[adium contactAlertsController] globalShortDescriptionForEventID:eventID]);
		
    }else{
        return(nil);
		
    }
}

//
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
	
    if([identifier isEqualToString:TABLE_COLUMN_SOUND]){
        NSMenuItem			*selectedMenuItem;
        NSMutableDictionary	*selectedSoundDict;
        NSString			*newSoundPath;
		
        //
        selectedMenuItem = (NSMenuItem *)[[[tableColumn dataCell] menu] itemAtIndex:[object intValue]];
        selectedSoundDict = [[eventSoundArray objectAtIndex:row] mutableCopy];
        newSoundPath = [selectedMenuItem representedObject];
        setRow = row;
        if(newSoundPath && ![newSoundPath isEqualToString:[selectedSoundDict objectForKey:KEY_EVENT_SOUND_PATH]]){ //Ignore a duplicate selection
																												   //If the user just modified a premade sound set, save it as their custom set, and switch them to 'custom'.
																												   //[self saveEventSoundArray];
			
            //Set the new sound path
            [selectedSoundDict setObject:newSoundPath forKey:KEY_EVENT_SOUND_PATH];
            [eventSoundArray replaceObjectAtIndex:row withObject:selectedSoundDict];
			
            //Save event sound preferences
            [self saveEventSoundArray];
        }
		
		[selectedSoundDict release];
    }
}

//
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    NSString	*identifier = [tableColumn identifier];
	
    if([identifier isEqualToString:TABLE_COLUMN_SOUND]){
        [cell selectItemWithRepresentedObject:[[eventSoundArray objectAtIndex:row] objectForKey:KEY_EVENT_SOUND_PATH]];
    }
}

//
- (void)tableViewDeleteSelectedRows:(NSTableView *)tableView
{
    [self deleteEventSound:nil]; //Delete it
}


@end


//
//  ESEventSoundContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//

#import "ESEventSoundContactAlert.h"
#import "AIEventSoundsPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"EventSoundContactAlert"

#define PLAY_A_SOUND    AILocalizedString(@"Play a sound",nil)

@interface ESEventSoundContactAlert (PRIVATE)
- (NSMenu *)soundListMenu;
- (void)autosizeAndCenterPopUpButton:(NSPopUpButton *)button;
@end

@implementation ESEventSoundContactAlert

-(id)init
{
    soundMenu_cached = nil;

    return ([super init]);
}

-(void)dealloc{
    [soundMenu_cached release];
    [super dealloc];
}

-(NSString *)nibName
{
    return CONTACT_ALERT_ACTION_NIB;
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:PLAY_A_SOUND
                                           target:self
                                           action:@selector(selectedAlert:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:SOUND_ALERT_IDENTIFIER];
    return (menuItem);
}

//setup display for playing a sound
- (IBAction)selectedAlert:(id)sender
{   
    //Get the current dictionary
    NSDictionary *currentDict = [[adium contactAlertsController] currentDictForContactAlert:self];
        
    [popUp_actionDetails setMenu:[self soundListMenu]];
    
    //Set the menu to its previous setting if the stored event matches
    if ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] isEqualToString:SOUND_ALERT_IDENTIFIER]) {
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[currentDict objectForKey:KEY_EVENT_DETAILS]]];        
    }
    
    [popUp_actionDetails autosizeAndCenterHorizontally];
    
    [self configureWithSubview:view_details_menu];
}

//--Sounds--
//Builds and returns a sound list menu
- (NSMenu *)soundListMenu
{
    if (!soundMenu_cached)
    {
        NSEnumerator	*enumerator;
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
                menuItem = [[[NSMenuItem alloc] initWithTitle:[soundSetPath lastPathComponent]
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
        }
        //Add the Other... item
        menuItem = [[[NSMenuItem alloc] initWithTitle:OTHER_ELLIPSIS
                                               target:self
                                               action:@selector(selectSound:)
                                        keyEquivalent:@""] autorelease];            
        [soundMenu addItem:menuItem];
        
        [soundMenu setAutoenablesItems:NO];
        soundMenu_cached = soundMenu;
    }
    
    //Add custom sounds to the menu as needed
    //Get the current dictionary
    NSDictionary *currentDict = [[adium contactAlertsController] currentDictForContactAlert:self];
    if (currentDict && ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] compare:SOUND_ALERT_IDENTIFIER] == 0)) {
        //add it if it's not already in the menu
        NSString *soundPath = [currentDict objectForKey:KEY_EVENT_DETAILS];
        if (soundPath && ([soundPath length] != 0) && [popUp_actionDetails indexOfItemWithRepresentedObject:soundPath] == -1) {
            NSImage	*soundImage;
            NSString	*soundTitle;
            NSMenuItem	*menuItem;
            
            //Add an "Other" header if necessary
            if ([popUp_actionDetails indexOfItemWithTitle:OTHER] == -1) {
                [soundMenu_cached insertItem:[NSMenuItem separatorItem] atIndex:([soundMenu_cached numberOfItems]-1)]; //Divider
                menuItem = [[[NSMenuItem alloc] initWithTitle:OTHER
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
            menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
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
    [popUp_actionDetails autosizeAndCenterHorizontally];
    
    if(soundPath != nil && [soundPath length] != 0){
        [[adium soundController] playSoundAtPath:soundPath]; //Play the sound
      
        [self setObject:soundPath forKey:KEY_EVENT_DETAILS];
        
        //Save event sound preferences
        [self saveEventActionArray];
    } else { //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel 
            beginSheetForDirectory:nil
                              file:nil
                             types:[NSSound soundUnfilteredFileTypes] //allow all the sounds NSSound understands
                    modalForWindow:[[adium contactAlertsController] currentWindowForContactAlert:self]
                     modalDelegate:self
                    didEndSelector:@selector(concludeOtherPanel:returnCode:contextInfo:)
                       contextInfo:nil];  

    }
}
//Finish up the Other... panel
- (void)concludeOtherPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton){
        NSString *soundPath = [[panel filenames] objectAtIndex:0];
        
        [[adium soundController] playSoundAtPath:soundPath]; //Play the sound
        
        [self setObject:soundPath forKey:KEY_EVENT_DETAILS];
        
        //Save event sound preferences
        [self saveEventActionArray];
        
        //Update the menu and and the selection
        [popUp_actionDetails setMenu:[self soundListMenu]];
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:soundPath]];
        [popUp_actionDetails autosizeAndCenterHorizontally];
    }
}


@end

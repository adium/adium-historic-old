//
//  ESEventSoundContactAlert.m
//  Adium XCode
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ESEventSoundContactAlert.h"
#import "AIEventSoundsPlugin.h"

#define CONTACT_ALERT_ACTION_NIB @"EventSoundContactAlert"

@interface ESEventSoundContactAlert (PRIVATE)
- (NSMenu *)soundListMenu;
- (void)autosizeAndCenterPopUpButton:(NSPopUpButton *)button;
@end

@implementation ESEventSoundContactAlert

- (id)initWithOwner:(id)inOwner
{
    owner = inOwner;
    
    [NSBundle loadNibNamed:CONTACT_ALERT_ACTION_NIB owner:self];
    
    [super init];
    return (self);
}

- (NSMenuItem *)alertMenuItem
{
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:@"Play a sound"
                                           target:self
                                           action:@selector(actionPlaySound:)
                                    keyEquivalent:@""] autorelease];
    [menuItem setRepresentedObject:CONTACT_ALERT_IDENTIFIER];
    NSLog(@"menuItem %@",CONTACT_ALERT_IDENTIFIER);
    return (menuItem);
}

//setup display for playing a sound
- (IBAction)actionPlaySound:(id)sender
{   
    //Get the current dictionary
    NSDictionary *currentDict = [[owner contactAlertsController] currentDictForContactAlert:self];
    
    //Set the menu to its previous setting if the stored event matches
    if ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] isEqualToString:CONTACT_ALERT_IDENTIFIER]) {
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:[currentDict objectForKey:KEY_EVENT_DETAILS]]];        
    }
    
    [popUp_actionDetails setMenu:[self soundListMenu]];
    [self autosizeAndCenterPopUpButton:popUp_actionDetails];
    
    [[owner contactAlertsController] configureWithSubview:view_details_menu forContactAlert:self];
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
        
        enumerator = [[[owner soundController] soundSetArray] objectEnumerator];
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
        menuItem = [[[NSMenuItem alloc] initWithTitle:@"Other..."
                                               target:self
                                               action:@selector(selectSound:)
                                        keyEquivalent:@""] autorelease];            
        [soundMenu addItem:menuItem];
        
        [soundMenu setAutoenablesItems:NO];
        soundMenu_cached = soundMenu;
    }
    
    //Add custom sounds to the menu as needed
    //Get the current dictionary
    NSDictionary *currentDict = [[owner contactAlertsController] currentDictForContactAlert:self];
    if (currentDict && ([(NSString *)[currentDict objectForKey:KEY_EVENT_ACTION] compare:CONTACT_ALERT_IDENTIFIER] == 0)) {
        //add it if it's not already in the menu
        NSString *soundPath = [currentDict objectForKey:KEY_EVENT_DETAILS];
        if (soundPath && ([soundPath length] != 0) && [popUp_actionDetails indexOfItemWithRepresentedObject:soundPath] == -1) {
            NSImage	*soundImage;
            NSString	*soundTitle;
            NSMenuItem	*menuItem;
            
            //Add an "Other" header if necessary
            if ([popUp_actionDetails indexOfItemWithTitle:@"Other"] == -1) {
                [soundMenu_cached insertItem:[NSMenuItem separatorItem] atIndex:([soundMenu_cached numberOfItems]-1)]; //Divider
                menuItem = [[[NSMenuItem alloc] initWithTitle:@"Other"
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
    [self autosizeAndCenterPopUpButton:popUp_actionDetails];
    
    if(soundPath != nil && [soundPath length] != 0){
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
      
        [self setObject:soundPath forKey:KEY_EVENT_DETAILS];
        
        //Save event sound preferences
        [self saveEventActionArray];
    } else { //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        //EDS - need view_main
   /*     [openPanel 
            beginSheetForDirectory:nil
                              file:nil
                             types:[NSSound soundUnfilteredFileTypes] //allow all the sounds NSSound understands
                    modalForWindow:[view_main window]
                     modalDelegate:self
                    didEndSelector:@selector(concludeOtherPanel:returnCode:contextInfo:)
                       contextInfo:nil];  
*/
    }
}
//Finish up the Other... panel
- (void)concludeOtherPanel:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSOKButton){
        NSString *soundPath = [[panel filenames] objectAtIndex:0];
        
        [[owner soundController] playSoundAtPath:soundPath]; //Play the sound
        
        [self setObject:soundPath forKey:KEY_EVENT_DETAILS];
        
        //Save event sound preferences
        [self saveEventActionArray];
        
        //Update the menu and and the selection
        [popUp_actionDetails setMenu:[self soundListMenu]];
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:soundPath]];
        [self autosizeAndCenterPopUpButton:popUp_actionDetails];
    }
}
- (void)autosizeAndCenterPopUpButton:(NSPopUpButton *)button
{
    NSString *buttonTitle = [button titleOfSelectedItem];
    if (buttonTitle && [buttonTitle length]) {
        [button sizeToFit];
        NSRect menuFrame = [button frame];
        menuFrame.origin.x = ([[button superview] frame].size.width / 2) - (menuFrame.size.width / 2);
        [button setFrame:menuFrame];   
        [[button superview] display];
    }
}


@end

//
//  ESEventSoundContactAlert.m
//  Adium
//
//  Created by Evan Schoenberg on Wed Nov 26 2003.
//

#import "ESEventSoundAlertDetailPane.h"
#import "AIEventSoundsPlugin.h"

#define PLAY_A_SOUND    			AILocalizedString(@"Play a sound",nil)

@interface ESEventSoundAlertDetailPane (PRIVATE)
- (NSMenu *)soundListMenu;
- (void)addSound:(NSString *)soundPath toMenu:(NSMenu *)soundMenu;
@end

@implementation ESEventSoundAlertDetailPane

//Pane Details
- (NSString *)label{
	return(@"");
}
- (NSString *)nibName{
    return(@"EventSoundContactAlert");    
}

//Configure the detail view
- (void)viewDidLoad
{
	//Loading and using the real file icons is slow, and all the sound files should have the same icons anyway.  So
	//we can cheat and load a sound icon from our bundle here (for all the menu items) for a nice speed boost.
	soundFileIcon = [NSImage imageNamed:@"SoundFileIcon" forClass:[self class]];
	
	//Prepare our sound menu
    [popUp_actionDetails setMenu:[self soundListMenu]];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails
{
	//If the user has a custom sound selected, we need to create an entry in the menu for it
	NSString	*selectedSound = [inDetails objectForKey:KEY_ALERT_SOUND_PATH];
	if([[popUp_actionDetails menu] indexOfItemWithRepresentedObject:selectedSound] == NSNotFound){
		[self addSound:selectedSound toMenu:[popUp_actionDetails menu]];
	}
	
    //Set the menu to its previous setting if the stored event matches
	int		soundIndex = [popUp_actionDetails indexOfItemWithRepresentedObject:[inDetails objectForKey:KEY_ALERT_SOUND_PATH]];
	if(soundIndex >= 0 && soundIndex < [popUp_actionDetails numberOfItems]){
		[popUp_actionDetails selectItemAtIndex:soundIndex];        
	}
}

//Return our current configuration
- (NSDictionary *)actionDetails
{
	NSString	*soundPath = [[popUp_actionDetails selectedItem] representedObject];

	if(soundPath && [soundPath length]){
		return([NSDictionary dictionaryWithObject:soundPath forKey:KEY_ALERT_SOUND_PATH]);
	}else{
		return(nil);
	}
}


//Sound Menu -----------------------------------------------------------------------------------------------------------
#pragma mark Sound Menu
//Builds and returns a sound list menu
- (NSMenu *)soundListMenu
{
	NSMenu			*soundMenu = [[NSMenu alloc] init];
	NSEnumerator	*enumerator;
	NSDictionary	*soundSetDict;
	NSMenuItem		*menuItem;
	
	//Add all soundsets to our menu
	enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
	while((soundSetDict = [enumerator nextObject])){
		NSEnumerator    *soundEnumerator;
		NSString        *soundPath;
		NSArray         *soundSetContents = [soundSetDict objectForKey:KEY_SOUND_SET_CONTENTS];
		
		if(soundSetContents && [soundSetContents count]){
			//Add an item for the set
			menuItem = [[[NSMenuItem alloc] initWithTitle:[[soundSetDict objectForKey:KEY_SOUND_SET] lastPathComponent]
												   target:nil
												   action:nil
											keyEquivalent:@""] autorelease];
			[menuItem setEnabled:NO];
			[soundMenu addItem:menuItem];
			
			//Add an item for each sound
			soundEnumerator = [soundSetContents objectEnumerator];
			while((soundPath = [soundEnumerator nextObject])){
				[self addSound:soundPath toMenu:soundMenu];
			}
			
			//Add a divider between sets
			[soundMenu addItem:[NSMenuItem separatorItem]];
		}
	}
	
	//Add the "Other..." item
	menuItem = [[[NSMenuItem alloc] initWithTitle:OTHER_ELLIPSIS
										   target:self
										   action:@selector(selectSound:)
									keyEquivalent:@""] autorelease];            
	[soundMenu addItem:menuItem];
	[soundMenu setAutoenablesItems:NO];
    
	
	
	
	
	
	
    //Add custom sounds to the menu as needed

    
	
	//Get the current dictionary
#warning copy paste alert
	
	
	
//        //add it if it's not already in the menu
//        NSString *soundPath = [currentDict objectForKey:KEY_EVENT_DETAILS];
//        if(soundPath && ([soundPath length] != 0) && [popUp_actionDetails indexOfItemWithRepresentedObject:soundPath] == -1){
//            NSImage	*soundImage;
//            NSString	*soundTitle;
//            NSMenuItem	*menuItem;
//            
//            //Add an "Other" header if necessary
//            if([popUp_actionDetails indexOfItemWithTitle:OTHER] == -1){
//                [soundMenu_cached insertItem:[NSMenuItem separatorItem] atIndex:([soundMenu_cached numberOfItems]-1)]; //Divider
//                menuItem = [[[NSMenuItem alloc] initWithTitle:OTHER
//                                                       target:nil
//                                                       action:nil
//                                                keyEquivalent:@""] autorelease];
//                [menuItem setEnabled:NO];
//                [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
//            }
//            
//            //Get the sound title and image
//            soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
//            soundImage = [[NSWorkspace sharedWorkspace] iconForFile:soundPath];
//            [soundImage setSize:NSMakeSize(SOUND_MENU_ICON_SIZE,SOUND_MENU_ICON_SIZE)];
//            
//            //Build the menu item
//            menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
//                                                   target:self
//                                                   action:@selector(selectSound:)
//                                            keyEquivalent:@""] autorelease];
//            [menuItem setRepresentedObject:soundPath];
//            [menuItem setImage:soundImage];
//            
//            [soundMenu_cached insertItem:menuItem atIndex:([soundMenu_cached numberOfItems]-1)];
//        }
//    }
    
    return([soundMenu autorelease]);
}

//Add a sound menu item
- (void)addSound:(NSString *)soundPath toMenu:(NSMenu *)soundMenu
{
	NSString	*soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
	NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:soundTitle
														target:self
														action:@selector(selectSound:)
												 keyEquivalent:@""] autorelease];
	
	[menuItem setRepresentedObject:[soundPath stringByCollapsingBundlePath]];
	[menuItem setImage:soundFileIcon];
	[soundMenu addItem:menuItem];
}












//Select a sound from one of the sound popUp menus
- (IBAction)selectSound:(id)sender
{
    NSString	*soundPath = [sender representedObject];
    
    if(soundPath != nil && [soundPath length] != 0){
        [[adium soundController] playSoundAtPath:[soundPath stringByExpandingBundlePath]]; //Play the sound
		
    }else{ //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel 
            beginSheetForDirectory:nil
                              file:nil
                             types:[NSSound soundUnfilteredFileTypes] //allow all the sounds NSSound understands
                    modalForWindow:nil
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

        //Update the menu and and the selection
        [popUp_actionDetails setMenu:[self soundListMenu]];
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:soundPath]];
        [popUp_actionDetails autosizeAndCenterHorizontally];
    }
}

@end

/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AIEventSoundsPlugin.h"
#import "AISoundController.h"
#import "ESEventSoundAlertDetailPane.h"
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AILocalizationTextField.h>

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
	[label_sound setStringValue:AILocalizedString(@"Sound:",nil)];

	//Loading and using the real file icons is slow, and all the sound files should have the same icons anyway.  So
	//we can cheat and load a sound icon from our bundle here (for all the menu items) for a nice speed boost.
	if(!soundFileIcon) soundFileIcon = [[NSImage imageNamed:@"SoundFileIcon" forClass:[self class]] retain];
	
	//Prepare our sound menu
    [popUp_actionDetails setMenu:[self soundListMenu]];
	
	[super viewDidLoad];
}

- (void)viewWillClose
{
	[soundFileIcon release]; soundFileIcon = nil;
	[super viewWillClose];
}

//Configure for the action
- (void)configureForActionDetails:(NSDictionary *)inDetails listObject:(AIListObject *)inObject
{
	//If the user has a custom sound selected, we need to create an entry in the menu for it
	NSString	*selectedSound = [inDetails objectForKey:KEY_ALERT_SOUND_PATH];
	if([[popUp_actionDetails menu] indexOfItemWithRepresentedObject:selectedSound] == -1){
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
			menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[soundSetDict objectForKey:KEY_SOUND_SET] lastPathComponent]
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
	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:OTHER_ELLIPSIS
																	 target:self
																	 action:@selector(selectSound:)
															  keyEquivalent:@""] autorelease];            
	[soundMenu addItem:menuItem];
	[soundMenu setAutoenablesItems:NO];
	
    return([soundMenu autorelease]);
}

//Add a sound menu item
- (void)addSound:(NSString *)soundPath toMenu:(NSMenu *)soundMenu
{
	NSString	*soundTitle = [[soundPath lastPathComponent] stringByDeletingPathExtension];
	NSMenuItem	*menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:soundTitle
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
		
		[self detailsForHeaderChanged];
    }else{ //selected "Other..."
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        
        [openPanel 
            beginSheetForDirectory:nil
                              file:nil
                             types:[NSSound soundUnfilteredFileTypes] //allow all the sounds NSSound understands
                    modalForWindow:[view window]
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
		[self addSound:soundPath toMenu:[popUp_actionDetails menu]];
        [popUp_actionDetails selectItemAtIndex:[popUp_actionDetails indexOfItemWithRepresentedObject:soundPath]];
		
		[self detailsForHeaderChanged];
    }
}

@end

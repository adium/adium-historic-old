/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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
#import "AIEventSoundCustom.h"

@interface AIEventSoundPreferences (PRIVATE)
- (NSMenu *)_soundSetMenu;
- (void)xtrasChanged:(NSNotification *)notification;
- (void)preferencesChanged:(NSNotification *)notification;
@end

@implementation AIEventSoundPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Sound);
}
- (NSString *)label{
    return(@"Sounds");
}
- (NSString *)nibName{
    return(@"EventSoundPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    //Observer preference changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_SOUNDS];
	
	//Observe for installation of new sound sets
	[[adium notificationCenter] addObserver:self
								   selector:@selector(xtrasChanged:)
									   name:Adium_Xtras_Changed
									 object:nil];
	[self xtrasChanged:nil];
}

//Preference view is closing
- (void)viewWillClose
{
    [AIEventSoundCustom closeEventSoundCustomPanel];
	[[adium preferenceController] unregisterPreferenceObserver:self];
    [[adium notificationCenter] removeObserver:self];
}

- (void)xtrasChanged:(NSNotification *)notification
{
	if (notification == nil || [[notification object] caseInsensitiveCompare:@"AdiumSoundset"] == 0){
		
		//Build the soundset menu
		[popUp_soundSet setMenu:[self _soundSetMenu]];
		
//		[self preferencesChanged:nil];
	}
}

//The user selected a sound set
- (IBAction)selectSoundSet:(id)sender
{
    if(sender && [sender representedObject]){
        [AIEventSoundCustom closeEventSoundCustomPanel];
        [[adium preferenceController] setPreference:[[sender representedObject] stringByCollapsingBundlePath] forKey:KEY_EVENT_SOUND_SET group:PREF_GROUP_SOUNDS];
        
    }else{
        NSString *soundSetPath = [[[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS] objectForKey:KEY_EVENT_SOUND_SET];

        //When the user moves from a preset to custom, we copy the preset sounds into custom.
        if(soundSetPath && [soundSetPath length] != 0){
            NSArray	*soundSet;

            if(soundSet = [plugin loadSoundSetAtPath:[soundSetPath stringByExpandingBundlePath] creator:nil description:nil]){
                [[adium preferenceController] setPreference:soundSet forKey:KEY_EVENT_CUSTOM_SOUNDSET group:PREF_GROUP_SOUNDS];
            }
        }

        //
        [AIEventSoundCustom showEventSoundCustomPanel];

    }
}

//Called when the preferences change, update our preference display
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	//If the 'Soundset' changed
	if(!key || ([key isEqualToString:KEY_EVENT_SOUND_SET])){
		NSString		*soundSetPath = [prefDict objectForKey:KEY_EVENT_SOUND_SET];
		
		//Update the soundset popUp
		if(soundSetPath && [soundSetPath length] != 0){
			[popUp_soundSet selectItemWithRepresentedObject:[soundSetPath stringByExpandingBundlePath]];	
		}else{
			[popUp_soundSet selectItem:[popUp_soundSet lastItem]];
		}
	}
}

//Builds and returns a sound set menu
- (NSMenu *)_soundSetMenu
{
    NSEnumerator	*enumerator;
    NSDictionary	*soundSetDict;
    NSMenu		*soundSetMenu = [[NSMenu alloc] init];
    
    enumerator = [[[adium soundController] soundSetArray] objectEnumerator];
    while((soundSetDict = [enumerator nextObject])){
        NSString	*setPath = [soundSetDict objectForKey:KEY_SOUND_SET];
        NSMenuItem	*menuItem;
        NSString	*soundSetFile;

        //Ensure this folder contains a soundset file (Otherwise, we ignore it)
        soundSetFile = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.txt", setPath, [[setPath stringByDeletingPathExtension] lastPathComponent]]];
        if(soundSetFile && [soundSetFile length] != 0){
			
            //Add a menu item for the set
            menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[[setPath stringByDeletingPathExtension] lastPathComponent]
																			 target:self
																			 action:@selector(selectSoundSet:)
																	  keyEquivalent:@""] autorelease];
            [menuItem setRepresentedObject:[soundSetDict objectForKey:KEY_SOUND_SET]];
            [soundSetMenu addItem:menuItem];
			
        }
    }
	
    //Custom option
    [soundSetMenu addItem:[NSMenuItem separatorItem]];
    [soundSetMenu addItemWithTitle:AILocalizedString(@"Custom...",nil) target:self action:@selector(selectSoundSet:) keyEquivalent:@""];

    return(soundSetMenu);
}

@end




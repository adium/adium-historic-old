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
#import "AIEventSoundCustom.h"

@interface AIEventSoundPreferences (PRIVATE)
- (NSMenu *)_soundSetMenu;
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
    //Build the soundset menu
    [popUp_soundSet setMenu:[self _soundSetMenu]];

    //Observer preference changes
    [[adium notificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
    [self preferencesChanged:nil];
}

//Preference view is closing
- (void)viewWillClose
{
    [AIEventSoundCustom closeEventSoundCustomPanel];
    [[adium notificationCenter] removeObserver:self];
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

            if([plugin loadSoundSetAtPath:[soundSetPath stringByExpandingBundlePath] creator:nil description:nil sounds:&soundSet]){
                [[adium preferenceController] setPreference:soundSet forKey:KEY_EVENT_CUSTOM_SOUNDSET group:PREF_GROUP_SOUNDS];
            }
        }

        //
        [AIEventSoundCustom showEventSoundCustomPanel];

    }
}

//The user toggled the mute when away checkbox
- (IBAction)toggleMuteWhileAway:(id)sender
{
    [[adium preferenceController] setPreference: [NSNumber numberWithBool:[button_muteWhileAway state]]
                                         forKey:KEY_EVENT_MUTE_WHILE_AWAY
                                          group:PREF_GROUP_SOUNDS];
}


//Called when the preferences change, update our preference display
- (void)preferencesChanged:(NSNotification *)notification
{
    if(notification == nil || [(NSString *)[[notification userInfo] objectForKey:@"Group"] compare:PREF_GROUP_SOUNDS] == 0){
        NSString	*key = [[notification userInfo] objectForKey:@"Key"];
        NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_SOUNDS];
        //If the 'Soundset' changed
        if(notification == nil || ([key compare:KEY_EVENT_SOUND_SET] == 0)){
            NSString		*soundSetPath = [preferenceDict objectForKey:KEY_EVENT_SOUND_SET];

            //Update the soundset popUp
            if(soundSetPath && [soundSetPath length] != 0){
                [popUp_soundSet selectItemWithRepresentedObject:[soundSetPath stringByExpandingBundlePath]];	
            }else{
                [popUp_soundSet selectItem:[popUp_soundSet lastItem]];
            }
        }
        [button_muteWhileAway setState:[[preferenceDict objectForKey:KEY_EVENT_MUTE_WHILE_AWAY] boolValue]];
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
            menuItem = [[[NSMenuItem alloc] initWithTitle:[[setPath stringByDeletingPathExtension] lastPathComponent]
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




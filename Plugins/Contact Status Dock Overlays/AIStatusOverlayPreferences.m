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

#import "AIStatusOverlayPreferences.h"
#import "AIContactStatusDockOverlaysPlugin.h"
#import <Adium/AILocalizationTextField.h>

@implementation AIStatusOverlayPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Dock);
}
- (NSString *)label{
    return(@"Contact Status Overlays");
}
- (NSString *)nibName{
    return(@"DockStatusOverlaysPrefs");
}

//Configures our view for the current preferences
- (void)viewDidLoad
{
	[checkBox_showContentOverlays setTitle:AILocalizedString(@"With unviewed messages","Option for'Show Contacts:'")];
	[checkBox_showStatusOverlays setTitle:AILocalizedString(@"Who connect and disconnect","Option for'Show Contacts:'")];
	[label_showContacts setStringValue:AILocalizedString(@"Show Contacts:",nil)];
	
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_DOCK_OVERLAYS];

    [checkBox_showStatusOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_STATUS] boolValue]];
    [checkBox_showContentOverlays setState:[[preferenceDict objectForKey:KEY_DOCK_SHOW_CONTENT] boolValue]];
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_showStatusOverlays){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_STATUS
                                              group:PREF_GROUP_DOCK_OVERLAYS];
        
    }else if(sender == checkBox_showContentOverlays){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DOCK_SHOW_CONTENT
                                              group:PREF_GROUP_DOCK_OVERLAYS];

    }
}

@end

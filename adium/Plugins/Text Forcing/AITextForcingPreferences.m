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

#import "AITextForcingPreferences.h"
#import "AITextForcingPlugin.h"

@interface AITextForcingPreferences (PRIVATE)
- (void)changeFont:(id)sender;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
@end

@implementation AITextForcingPreferences

//Preference pane properties
- (PREFERENCE_CATEGORY)category{
    return(AIPref_Advanced_Messages);
}
- (NSString *)label{
    return(@"Reformat Incoming Messages");
}
- (NSString *)nibName{
    return(@"TextForcingPrefs");
}

//Configure the preference view
- (void)viewDidLoad
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_TEXT_FORCING];
    
    //Font
    [self showFont:[[preferenceDict objectForKey:KEY_FORCE_DESIRED_FONT] representedFont] inField:textField_desiredFont];
    [checkBox_forceFont setState:[[preferenceDict objectForKey:KEY_FORCE_FONT] boolValue]];
    
    //Text
    [checkBox_forceTextColor setState:[[preferenceDict objectForKey:KEY_FORCE_TEXT_COLOR] boolValue]];
    [colorPopUp_textColor setColor:[[preferenceDict objectForKey:KEY_FORCE_DESIRED_TEXT_COLOR] representedColor]];
    
    //Background
    [checkBox_forceBackgroundColor setState:[[preferenceDict objectForKey:KEY_FORCE_BACKGROUND_COLOR] boolValue]];
    [colorPopUp_backgroundColor setColor:[[preferenceDict objectForKey:KEY_FORCE_DESIRED_BACKGROUND_COLOR] representedColor]];
    
    [self configureControlDimming]; //disable the unavailable controls
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == button_setFont){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_TEXT_FORCING];
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*selectedFont = [[preferenceDict objectForKey:KEY_FORCE_DESIRED_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_desiredFont window] setDelegate:self];

        //Setup and show the font panel
        [[textField_desiredFont window] makeFirstResponder:[textField_desiredFont window]];
        [fontManager setSelectedFont:selectedFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];

    }else if(sender == colorPopUp_textColor){
        [[owner preferenceController] setPreference:[[colorPopUp_textColor color] stringRepresentation]
                                             forKey:KEY_FORCE_DESIRED_TEXT_COLOR
                                              group:PREF_GROUP_TEXT_FORCING];

    }else if(sender == colorPopUp_backgroundColor){
        [[owner preferenceController] setPreference:[[colorPopUp_backgroundColor color] stringRepresentation]
                                             forKey:KEY_FORCE_DESIRED_BACKGROUND_COLOR
                                              group:PREF_GROUP_TEXT_FORCING];

    }else if(sender == checkBox_forceFont){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FORCE_FONT
                                              group:PREF_GROUP_TEXT_FORCING];
        [self configureControlDimming];
        
    }else if(sender == checkBox_forceTextColor){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FORCE_TEXT_COLOR
                                              group:PREF_GROUP_TEXT_FORCING];
        [self configureControlDimming];
        
    }else if(sender == checkBox_forceBackgroundColor){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_FORCE_BACKGROUND_COLOR
                                              group:PREF_GROUP_TEXT_FORCING];
        [self configureControlDimming];
    }

}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    //Font
    [button_setFont setEnabled:[checkBox_forceFont state]];
    [textField_desiredFont setEnabled:[checkBox_forceFont state]];
    
    //Text
    [colorPopUp_textColor setEnabled:[checkBox_forceTextColor state]];
    
    //Background
    [colorPopUp_backgroundColor setEnabled:[checkBox_forceBackgroundColor state]];
}

//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];

    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_desiredFont];
    [[owner preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_FORCE_DESIRED_FONT group:PREF_GROUP_TEXT_FORCING];
}

//Display a font name in our text field
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField
{
    if(inFont){
        [inTextField setStringValue:[NSString stringWithFormat:@"%@ %g", [inFont fontName], [inFont pointSize]]];
    }else{
        [inTextField setStringValue:@""];
    }
}

@end


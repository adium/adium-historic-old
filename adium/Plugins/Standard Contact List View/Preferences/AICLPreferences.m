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

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"
#import "AICLPreferences.h"
#import "AISCLOutlineView.h"
#import "AISCLViewPlugin.h"

#define CL_PREF_NIB			@"AICLPrefView"		//Name of preference nib
#define CL_PREF_GENERAL_TITLE		@"General Appearance"	//
#define CL_PREF_GROUPS_TITLE		@"Groups"		//

//Handles the interface interaction, and sets preference values
//The outline view plugin is responsible for reading & setting the preferences, as well as observing changes in them

@interface AICLPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)changeFont:(id)sender;
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField;
//- (void)showOpacityPercent;
- (void)configureControlDimming;
@end

@implementation AICLPreferences
//
+ (AICLPreferences *)contactListPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{

    if(sender == button_setFont){
        NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];
        NSFontManager	*fontManager = [NSFontManager sharedFontManager];
        NSFont		*contactListFont = [[preferenceDict objectForKey:KEY_SCL_FONT] representedFont];

        //In order for the font panel to work, we must be set as the window's delegate
        [[textField_fontName window] setDelegate:self];

        //Setup and show the font panel
        [[textField_fontName window] makeFirstResponder:[textField_fontName window]];
        [fontManager setSelectedFont:contactListFont isMultiple:NO];
        [fontManager orderFrontFontPanel:self];
        
    }else if(sender == checkBox_alternatingGrid){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_ALTERNATING_GRID
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == checkBox_showLabels){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_SHOW_LABELS
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == colorWell_group){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];        

    }else if(sender == colorWell_contact){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_CONTACT_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == colorWell_grid){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GRID_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];
        
    }else if(sender == colorWell_background){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_BACKGROUND_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];    

/*    }else if(sender == slider_opacity){
        float	opacity = (100.0 - [sender floatValue]) * 0.01;
        
        [self showOpacityPercent];
        [[owner preferenceController] setPreference:[NSNumber numberWithFloat:opacity]
                                             forKey:KEY_SCL_OPACITY
                                              group:PREF_GROUP_CONTACT_LIST];
        */
    }else if(sender == checkBox_boldGroups){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_BOLD_GROUPS
                                              group:PREF_GROUP_CONTACT_LIST];

    }else if(sender == checkBox_customGroupColor){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SCL_CUSTOM_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];
        [self configureControlDimming];
        
    }else if(sender == colorWell_group){
        [[owner preferenceController] setPreference:[[sender color] stringRepresentation]
                                             forKey:KEY_SCL_GROUP_COLOR
                                              group:PREF_GROUP_CONTACT_LIST];
    }
    
}


//Private ---------------------------------------------------------------------------
//Called in response to a font panel change
- (void)changeFont:(id)sender
{
    NSFontManager	*fontManager = [NSFontManager sharedFontManager];
    NSFont		*contactListFont = [fontManager convertFont:[fontManager selectedFont]];

    //Update the displayed font string & preferences
    [self showFont:contactListFont inField:textField_fontName];
    [[owner preferenceController] setPreference:[contactListFont stringRepresentation] forKey:KEY_SCL_FONT group:PREF_GROUP_CONTACT_LIST];
}

//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference panes
    generalPane = [AIPreferencePane preferencePaneInCategory:AIPref_ContactList_General withDelegate:self label:CL_PREF_GENERAL_TITLE];
    [[owner preferenceController] addPreferencePane:generalPane];

    groupsPane = [AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Groups withDelegate:self label:CL_PREF_GROUPS_TITLE];
    [[owner preferenceController] addPreferencePane:groupsPane];

    
    return(self);    
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefViewGeneral){
        [NSBundle loadNibNamed:CL_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    if(preferencePane == generalPane){
        return(view_prefViewGeneral);
    }else{
        return(view_prefViewGroups);
    }
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefViewGeneral release]; view_prefViewGeneral = nil;
    [view_prefViewGroups release]; view_prefViewGroups = nil;
}

//Display the name of a font in our text field
- (void)showFont:(NSFont *)inFont inField:(NSTextField *)inTextField
{
    if(inFont){
        [inTextField setStringValue:[NSString stringWithFormat:@"%@ %g", [inFont fontName], [inFont pointSize]]];
    }else{
        [inTextField setStringValue:@""];
    }
}

//Display the current opacity percent
/*- (void)showOpacityPercent
{
    float	opacity = [slider_opacity floatValue];

    [textField_opacityPercent setStringValue:[NSString stringWithFormat:@"%i",(int)opacity]];
}*/

//Configure our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_LIST];

    //Display
    [self showFont:[[preferenceDict objectForKey:KEY_SCL_FONT] representedFont] inField:textField_fontName];
    [colorWell_contact setColor:[[preferenceDict objectForKey:KEY_SCL_CONTACT_COLOR] representedColor]];
    [colorWell_background setColor:[[preferenceDict objectForKey:KEY_SCL_BACKGROUND_COLOR] representedColor]];
    [checkBox_showLabels setState:[[preferenceDict objectForKey:KEY_SCL_SHOW_LABELS] boolValue]];
    
    //Grid
    [checkBox_alternatingGrid setState:[[preferenceDict objectForKey:KEY_SCL_ALTERNATING_GRID] boolValue]];
    [colorWell_grid setColor:[[preferenceDict objectForKey:KEY_SCL_GRID_COLOR] representedColor]];

    //Groups
    [checkBox_boldGroups setState:[[preferenceDict objectForKey:KEY_SCL_BOLD_GROUPS] boolValue]];
    [checkBox_customGroupColor setState:[[preferenceDict objectForKey:KEY_SCL_CUSTOM_GROUP_COLOR] boolValue]];
    [colorWell_group setColor:[[preferenceDict objectForKey:KEY_SCL_GROUP_COLOR] representedColor]];

    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [colorWell_group setEnabled:[checkBox_customGroupColor state]];
}

@end

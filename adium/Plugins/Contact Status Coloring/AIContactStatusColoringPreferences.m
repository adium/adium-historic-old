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

#import "AIContactStatusColoringPlugin.h"
#import "AIContactStatusColoringPreferences.h"

#define	CONTACT_STATUS_COLORING_PREF_NIB	@"ContactStatusColoringPrefs"
#define CONTACT_STATUS_COLORING_PREF_TITLE	AILocalizedString(@"Status Coloring",nil)

@interface AIContactStatusColoringPreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIContactStatusColoringPreferences
//
+ (AIContactStatusColoringPreferences *)contactStatusColoringPreferences
{
    return([[[self alloc] init] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_away){
        [[adium preferenceController] setPreference:[[colorWell_away color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idle){
        [[adium preferenceController] setPreference:[[colorWell_idle color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOff){
        [[adium preferenceController] setPreference:[[colorWell_signedOff color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOn){
        [[adium preferenceController] setPreference:[[colorWell_signedOn color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_typing){
        [[adium preferenceController] setPreference:[[colorWell_typing color] stringRepresentation]
                                             forKey:KEY_TYPING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_unviewedContent){
        [[adium preferenceController] setPreference:[[colorWell_unviewedContent color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_online){
        [[adium preferenceController] setPreference:[[colorWell_online color] stringRepresentation]
                                             forKey:KEY_ONLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idleAndAway){
        [[adium preferenceController] setPreference:[[colorWell_idleAndAway color] stringRepresentation]
                                             forKey:KEY_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_offline){
        [[adium preferenceController] setPreference:[[colorWell_offline color] stringRepresentation]
                                             forKey:KEY_OFFLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
		
		
        
    }else if(sender == colorWell_signedOffLabel){
        [[adium preferenceController] setPreference:[[colorWell_signedOffLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOnLabel){
        [[adium preferenceController] setPreference:[[colorWell_signedOnLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_awayLabel){
        [[adium preferenceController] setPreference:[[colorWell_awayLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idleLabel){
        [[adium preferenceController] setPreference:[[colorWell_idleLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_typingLabel){
        [[adium preferenceController] setPreference:[[colorWell_typingLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_TYPING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_unviewedContentLabel){
        [[adium preferenceController] setPreference:[[colorWell_unviewedContentLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_onlineLabel){
        [[adium preferenceController] setPreference:[[colorWell_onlineLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_ONLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idleAndAwayLabel){
        [[adium preferenceController] setPreference:[[colorWell_idleAndAwayLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        
    }else if(sender == colorWell_offlineLabel){
        [[adium preferenceController] setPreference:[[colorWell_offlineLabel color] stringRepresentation]
                                             forKey:KEY_LABEL_OFFLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
		
        
    }else if(sender == checkBox_signedOff){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_OFF_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_signedOn){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_SIGNED_ON_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_away){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_idle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_typing){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_TYPING_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_unviewedContent){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_UNVIEWED_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_online){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_ONLINE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

    }else if(sender == checkBox_idleAndAway){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_AWAY_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];

	}else if(sender == checkBox_offline){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_OFFLINE_ENABLED
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
        [self configureControlDimming];
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:CONTACT_STATUS_COLORING_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:CONTACT_STATUS_COLORING_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;

}


//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING];

    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typing setColor:[[preferenceDict objectForKey:KEY_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
    [colorWell_online setColor:[[preferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAway setColor:[[preferenceDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offline setColor:[[preferenceDict objectForKey:KEY_OFFLINE_COLOR] representedColor]];

    [colorWell_awayLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_AWAY_COLOR] representedColor]];
    [colorWell_idleLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_IDLE_COLOR] representedColor]];
    [colorWell_signedOffLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOnLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typingLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContentLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_UNVIEWED_COLOR] representedColor]];
    [colorWell_onlineLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_ONLINE_COLOR] representedColor]];
    [colorWell_idleAndAwayLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_offlineLabel setColor:[[preferenceDict objectForKey:KEY_LABEL_OFFLINE_COLOR] representedColor]];

    [checkBox_signedOff setState:[[preferenceDict objectForKey:KEY_SIGNED_OFF_ENABLED] boolValue]];
    [checkBox_signedOn setState:[[preferenceDict objectForKey:KEY_SIGNED_ON_ENABLED] boolValue]];
    [checkBox_away setState:[[preferenceDict objectForKey:KEY_AWAY_ENABLED] boolValue]];
    [checkBox_idle setState:[[preferenceDict objectForKey:KEY_IDLE_ENABLED] boolValue]];
    [checkBox_typing setState:[[preferenceDict objectForKey:KEY_TYPING_ENABLED] boolValue]];
    [checkBox_unviewedContent setState:[[preferenceDict objectForKey:KEY_UNVIEWED_ENABLED] boolValue]];
    [checkBox_online setState:[[preferenceDict objectForKey:KEY_ONLINE_ENABLED] boolValue]];
    [checkBox_idleAndAway setState:[[preferenceDict objectForKey:KEY_IDLE_AWAY_ENABLED] boolValue]];
    [checkBox_offline setState:[[preferenceDict objectForKey:KEY_OFFLINE_ENABLED] boolValue]];

    
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [colorWell_signedOff setEnabled:[checkBox_signedOff state]];
    [colorWell_signedOffLabel setEnabled:[checkBox_signedOff state]];

    [colorWell_signedOn setEnabled:[checkBox_signedOn state]];
    [colorWell_signedOnLabel setEnabled:[checkBox_signedOn state]];

    [colorWell_away setEnabled:[checkBox_away state]];
    [colorWell_awayLabel setEnabled:[checkBox_away state]];

    [colorWell_idle setEnabled:[checkBox_idle state]];
    [colorWell_idleLabel setEnabled:[checkBox_idle state]];

    [colorWell_typing setEnabled:[checkBox_typing state]];
    [colorWell_typingLabel setEnabled:[checkBox_typing state]];

    [colorWell_unviewedContent setEnabled:[checkBox_unviewedContent state]];
    [colorWell_unviewedContentLabel setEnabled:[checkBox_unviewedContent state]];

    [colorWell_online setEnabled:[checkBox_online state]];
    [colorWell_onlineLabel setEnabled:[checkBox_online state]];

    [colorWell_idleAndAway setEnabled:[checkBox_idleAndAway state]];
    [colorWell_idleAndAwayLabel setEnabled:[checkBox_idleAndAway state]];
	
	[colorWell_offline setEnabled:[checkBox_offline state]];
    [colorWell_offlineLabel setEnabled:[checkBox_offline state]];
}

@end

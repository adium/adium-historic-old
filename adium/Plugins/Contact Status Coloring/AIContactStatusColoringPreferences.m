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
#import "AIContactStatusColoringPlugin.h"
#import "AIContactStatusColoringPreferences.h"

#define	CONTACT_STATUS_COLORING_PREF_NIB	@"ContactStatusColoringPrefs"
#define CONTACT_STATUS_COLORING_PREF_TITLE	@"Status - Contact Name"

@interface AIContactStatusColoringPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIContactStatusColoringPreferences

+ (AIContactStatusColoringPreferences *)contactStatusColoringPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_signedOff){
        [[owner preferenceController] setPreference:[[colorWell_signedOff color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOn){
        [[owner preferenceController] setPreference:[[colorWell_signedOn color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_online){
        [[owner preferenceController] setPreference:[[colorWell_online color] stringRepresentation]
                                             forKey:KEY_ONLINE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_away){
        [[owner preferenceController] setPreference:[[colorWell_away color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idle){
        [[owner preferenceController] setPreference:[[colorWell_idle color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idleAway){
        [[owner preferenceController] setPreference:[[colorWell_idleAway color] stringRepresentation]
                                             forKey:KEY_IDLE_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_openTab){
        [[owner preferenceController] setPreference:[[colorWell_openTab color] stringRepresentation]
                                             forKey:KEY_OPEN_TAB_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_unviewedContent){
        [[owner preferenceController] setPreference:[[colorWell_unviewedContent color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_warning){
        [[owner preferenceController] setPreference:[[colorWell_warning color] stringRepresentation]
                                             forKey:KEY_WARNING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];
    }

    [self configureControlDimming];
}

//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:CONTACT_STATUS_COLORING_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:CONTACT_STATUS_COLORING_PREF_TITLE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_CONTACT_STATUS_COLORING] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_online setColor:[[preferenceDict objectForKey:KEY_ONLINE_COLOR] representedColor]];
    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_idleAway setColor:[[preferenceDict objectForKey:KEY_IDLE_AWAY_COLOR] representedColor]];
    [colorWell_openTab setColor:[[preferenceDict objectForKey:KEY_OPEN_TAB_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];
    [colorWell_warning setColor:[[preferenceDict objectForKey:KEY_WARNING_COLOR] representedColor]];

    [colorWell_signedOffInverted setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_INVERTED_COLOR] representedColor]];
    [colorWell_signedOnInverted setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_INVERTED_COLOR] representedColor]];
    [colorWell_onlineInverted setColor:[[preferenceDict objectForKey:KEY_ONLINE_INVERTED_COLOR] representedColor]];
    [colorWell_awayInverted setColor:[[preferenceDict objectForKey:KEY_AWAY_INVERTED_COLOR] representedColor]];
    [colorWell_idleInverted setColor:[[preferenceDict objectForKey:KEY_IDLE_INVERTED_COLOR] representedColor]];
    [colorWell_idleAwayInverted setColor:[[preferenceDict objectForKey:KEY_IDLE_AWAY_INVERTED_COLOR] representedColor]];
    [colorWell_openTabInverted setColor:[[preferenceDict objectForKey:KEY_OPEN_TAB_INVERTED_COLOR] representedColor]];
    [colorWell_unviewedContentInverted setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_INVERTED_COLOR] representedColor]];
    [colorWell_warningInverted setColor:[[preferenceDict objectForKey:KEY_WARNING_INVERTED_COLOR] representedColor]];

    [self configureControlDimming]; //disable the unavailable controls
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
/*
    //Font
    [button_setFont setEnabled:[checkBox_forceFont state]];
    [textField_desiredFont setEnabled:[checkBox_forceFont state]];

    //Text
    [colorWell_textColor setEnabled:[checkBox_forceTextColor state]];

    //Background
    [colorWell_backgroundColor setEnabled:[checkBox_forceBackgroundColor state]];
*/
}

@end

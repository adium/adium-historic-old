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
@end

@implementation AIContactStatusColoringPreferences

+ (AIContactStatusColoringPreferences *)contactStatusColoringPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == colorWell_away){
        [[owner preferenceController] setPreference:[[colorWell_away color] stringRepresentation]
                                             forKey:KEY_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_idle){
        [[owner preferenceController] setPreference:[[colorWell_idle color] stringRepresentation]
                                             forKey:KEY_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOff){
        [[owner preferenceController] setPreference:[[colorWell_signedOff color] stringRepresentation]
                                             forKey:KEY_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_signedOn){
        [[owner preferenceController] setPreference:[[colorWell_signedOn color] stringRepresentation]
                                             forKey:KEY_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_typing){
        [[owner preferenceController] setPreference:[[colorWell_typing color] stringRepresentation]
                                             forKey:KEY_TYPING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_unviewedContent){
        [[owner preferenceController] setPreference:[[colorWell_unviewedContent color] stringRepresentation]
                                             forKey:KEY_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backSignedOff){
        [[owner preferenceController] setPreference:[[colorWell_backSignedOff color] stringRepresentation]
                                             forKey:KEY_BACK_SIGNED_OFF_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backSignedOn){
        [[owner preferenceController] setPreference:[[colorWell_backSignedOn color] stringRepresentation]
                                             forKey:KEY_BACK_SIGNED_ON_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backAway){
        [[owner preferenceController] setPreference:[[colorWell_backAway color] stringRepresentation]
                                             forKey:KEY_BACK_AWAY_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backIdle){
        [[owner preferenceController] setPreference:[[colorWell_backIdle color] stringRepresentation]
                                             forKey:KEY_BACK_IDLE_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backTyping){
        [[owner preferenceController] setPreference:[[colorWell_backTyping color] stringRepresentation]
                                             forKey:KEY_BACK_TYPING_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }else if(sender == colorWell_backUnviewedContent){
        [[owner preferenceController] setPreference:[[colorWell_backUnviewedContent color] stringRepresentation]
                                             forKey:KEY_BACK_UNVIEWED_COLOR
                                              group:PREF_GROUP_CONTACT_STATUS_COLORING];

    }
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
    [colorWell_away setColor:[[preferenceDict objectForKey:KEY_AWAY_COLOR] representedColor]];
    [colorWell_idle setColor:[[preferenceDict objectForKey:KEY_IDLE_COLOR] representedColor]];
    [colorWell_signedOff setColor:[[preferenceDict objectForKey:KEY_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_signedOn setColor:[[preferenceDict objectForKey:KEY_SIGNED_ON_COLOR] representedColor]];
    [colorWell_typing setColor:[[preferenceDict objectForKey:KEY_TYPING_COLOR] representedColor]];
    [colorWell_unviewedContent setColor:[[preferenceDict objectForKey:KEY_UNVIEWED_COLOR] representedColor]];

    [colorWell_backAway setColor:[[preferenceDict objectForKey:KEY_BACK_AWAY_COLOR] representedColor]];
    [colorWell_backIdle setColor:[[preferenceDict objectForKey:KEY_BACK_IDLE_COLOR] representedColor]];
    [colorWell_backSignedOff setColor:[[preferenceDict objectForKey:KEY_BACK_SIGNED_OFF_COLOR] representedColor]];
    [colorWell_backSignedOn setColor:[[preferenceDict objectForKey:KEY_BACK_SIGNED_ON_COLOR] representedColor]];
    [colorWell_backTyping setColor:[[preferenceDict objectForKey:KEY_BACK_TYPING_COLOR] representedColor]];
    [colorWell_backUnviewedContent setColor:[[preferenceDict objectForKey:KEY_BACK_UNVIEWED_COLOR] representedColor]];
}

@end

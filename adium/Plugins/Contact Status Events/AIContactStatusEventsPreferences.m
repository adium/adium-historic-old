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
#import "AIContactStatusEventsPlugin.h"
#import "AIContactStatusEventsPreferences.h"

#define STATUS_EVENTS_PREF_NIB		@"ContactStatusEventsPrefs"	//Name of preference nib
#define STATUS_EVENTS_PREF_TITLE	@"Status Event Lengths"		//Title of the preference view

@interface AIContactStatusEventsPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIContactStatusEventsPreferences

+ (AIContactStatusEventsPreferences *)contactStatusEventsPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == textField_signedOffLength){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_SIGNED_OFF_LENGTH
                                              group:PREF_GROUP_STATUS_EVENTS];

    }else if(sender == textField_signedOnLength){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_SIGNED_ON_LENGTH
                                              group:PREF_GROUP_STATUS_EVENTS];

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
    [NSBundle loadNibNamed:STATUS_EVENTS_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:STATUS_EVENTS_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_STATUS_EVENTS] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{

    [textField_signedOffLength setIntValue:[[preferenceDict objectForKey:KEY_SIGNED_OFF_LENGTH] intValue]];
    [textField_signedOnLength setIntValue:[[preferenceDict objectForKey:KEY_SIGNED_ON_LENGTH] intValue]];

    [self configureControlDimming]; //disable the unavailable controls
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
}

@end

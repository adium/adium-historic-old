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

#import "AIContactStatusEventsPlugin.h"
#import "AIContactStatusEventsPreferences.h"

#define STATUS_EVENTS_PREF_NIB		@"ContactStatusEventsPrefs"	//Name of preference nib
#define STATUS_EVENTS_PREF_TITLE	@"Status Event Lengths"		//Title of the preference view

@interface AIContactStatusEventsPreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIContactStatusEventsPreferences
//
+ (AIContactStatusEventsPreferences *)contactStatusEventsPreferences
{
    return([[[self alloc] init] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == textField_signedOffLength){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_SIGNED_OFF_LENGTH
                                              group:PREF_GROUP_STATUS_EVENTS];

    }else if(sender == textField_signedOnLength){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_SIGNED_ON_LENGTH
                                              group:PREF_GROUP_STATUS_EVENTS];

    }

    [self configureControlDimming];
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    [super init];

    //Register our preference pane
//    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:PREFERENCE_CATEGORY_ CONNECTIONS withDelegate:self]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:STATUS_EVENTS_PREF_NIB owner:self];

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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_EVENTS];

    [textField_signedOffLength setIntValue:[[preferenceDict objectForKey:KEY_SIGNED_OFF_LENGTH] intValue]];
    [textField_signedOnLength setIntValue:[[preferenceDict objectForKey:KEY_SIGNED_ON_LENGTH] intValue]];
}

@end

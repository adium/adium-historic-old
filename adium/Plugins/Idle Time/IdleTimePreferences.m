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

#import "IdleTimePreferences.h"
#import "IdleTimePlugin.h"

#define IDLE_TIME_PREF_NIB		@"IdleTimePrefs"	//Name of preference nib
#define IDLE_TIME_PREF_TITLE		@"Idle"			//Title of the preference view

@interface IdleTimePreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation IdleTimePreferences
//
+ (IdleTimePreferences *)idleTimePreferences
{
    return([[[self alloc] init] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_enableIdle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_TIME_ENABLED
                                              group:PREF_GROUP_IDLE_TIME];
        [self configureControlDimming];

    }else if(sender == textField_idleMinutes){
        [[adium preferenceController] setPreference:[NSNumber numberWithInt:[sender intValue]]
                                             forKey:KEY_IDLE_TIME_IDLE_MINUTES
                                              group:PREF_GROUP_IDLE_TIME];

    }
}


//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Status_Idle withDelegate:self label:IDLE_TIME_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:IDLE_TIME_PREF_NIB owner:self];

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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME];

    //Idle
    [checkBox_enableIdle setState:[[preferenceDict objectForKey:KEY_IDLE_TIME_ENABLED] boolValue]];
    [textField_idleMinutes setIntValue:[[preferenceDict objectForKey:KEY_IDLE_TIME_IDLE_MINUTES] intValue]];

    //
    [self configureControlDimming];
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [textField_idleMinutes setEnabled:[checkBox_enableIdle state]];
    [stepper_idleMinutes setEnabled:[checkBox_enableIdle state]];
}
    
@end

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
#import "AIIdleTimeDisplayPlugin.h"
#import "AIIdleTimeDisplayPreferences.h"

#define	IDLE_TIME_DISPLAY_PREF_NIB	@"IdleTimeDisplayPrefs"
#define IDLE_TIME_DISPLAY_PREF_TITLE	@"Idle Time Display"

@interface AIIdleTimeDisplayPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIIdleTimeDisplayPreferences

+ (AIIdleTimeDisplayPreferences *)idleTimeDisplayPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_displayIdle){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DISPLAY_IDLE_TIME
                                              group:PREF_GROUP_IDLE_TIME_DISPLAY];
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
    [NSBundle loadNibNamed:IDLE_TIME_DISPLAY_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:IDLE_TIME_DISPLAY_PREF_TITLE categoryName:PREFERENCE_CATEGORY_CONTACTLIST view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME_DISPLAY] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    [checkBox_displayIdle setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue]];

    [self configureControlDimming]; //disable the unavailable controls
}

//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
}

@end

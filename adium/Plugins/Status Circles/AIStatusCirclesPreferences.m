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

#import "AIStatusCirclesPlugin.h"
#import "AIStatusCirclesPreferences.h"

#define	STATUS_CIRCLES_PREF_NIB		@"StatusCirclesPrefs"
#define STATUS_CIRCLES_PREF_TITLE	@"Status Display"

@interface AIStatusCirclesPreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIStatusCirclesPreferences

+ (AIStatusCirclesPreferences *)statusCirclesPreferences
{
    return([[[self alloc] init] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_displayStatusCircle){
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
					     forKey:KEY_DISPLAY_STATUS_CIRCLE
					      group:PREF_GROUP_STATUS_CIRCLES];
	[self configureControlDimming];

    }else if(sender == checkBox_displayStatusCircleOnLeft){
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
					     forKey:KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT
					      group:PREF_GROUP_STATUS_CIRCLES];
        [checkBox_displayStatusCircleOnRight setState:NSOffState];

    }else if(sender == checkBox_displayStatusCircleOnRight){
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
					     forKey:KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT
					      group:PREF_GROUP_STATUS_CIRCLES];
        [checkBox_displayStatusCircleOnLeft setState:NSOffState];
	
    }else if(sender == checkBox_displayIdle){
	[[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
					     forKey:KEY_DISPLAY_IDLE_TIME
					      group:PREF_GROUP_STATUS_CIRCLES];
    }else if(sender == colorWell_idleColor){
        [[adium preferenceController] setPreference:[[colorWell_idleColor color] stringRepresentation]
                                             forKey:KEY_IDLE_TIME_COLOR
                                              group:PREF_GROUP_STATUS_CIRCLES];
    }
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:STATUS_CIRCLES_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:STATUS_CIRCLES_PREF_NIB owner:self];

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
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_STATUS_CIRCLES];

    [checkBox_displayStatusCircle setState:[[preferenceDict objectForKey:KEY_DISPLAY_STATUS_CIRCLE] boolValue]];
    [checkBox_displayStatusCircleOnLeft setState:[[preferenceDict objectForKey:KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT] boolValue]];
    [checkBox_displayStatusCircleOnRight setState:![[preferenceDict objectForKey:KEY_DISPLAY_STATUS_CIRCLE_ON_LEFT] boolValue]];
    [checkBox_displayIdle setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue]];
    [colorWell_idleColor setColor:[[preferenceDict objectForKey:KEY_IDLE_TIME_COLOR] representedColor]];

    [self configureControlDimming];
}
//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [checkBox_displayStatusCircleOnLeft setEnabled:[checkBox_displayStatusCircle state]];
    [checkBox_displayStatusCircleOnRight setEnabled:[checkBox_displayStatusCircle state]];
    [checkBox_displayIdle setEnabled:[checkBox_displayStatusCircle state]];
    [colorWell_idleColor setEnabled:[checkBox_displayStatusCircle state]];
}

@end

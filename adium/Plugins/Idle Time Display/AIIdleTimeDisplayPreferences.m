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

#import "AIIdleTimeDisplayPlugin.h"
#import "AIIdleTimeDisplayPreferences.h"

#define	IDLE_TIME_DISPLAY_PREF_NIB	@"IdleTimeDisplayPrefs"
#define IDLE_TIME_DISPLAY_PREF_TITLE	AILocalizedString(@"Idle Time Display",nil)

@interface AIIdleTimeDisplayPreferences (PRIVATE)
- (void)configureView;
- (void)configureControlDimming;
@end

@implementation AIIdleTimeDisplayPreferences

+ (AIIdleTimeDisplayPreferences *)idleTimeDisplayPreferences
{
    return([[[self alloc] init] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{
    if(sender == checkBox_displayIdle){
        [[adium preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_DISPLAY_IDLE_TIME
                                              group:PREF_GROUP_IDLE_TIME_DISPLAY];
		[self configureControlDimming];
		
    }else if(sender == checkBox_displayIdleOnLeft){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:YES]
											 forKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT
											  group:PREF_GROUP_IDLE_TIME_DISPLAY];
        [checkBox_displayIdleOnRight setState:NSOffState];
		
    }else if(sender == checkBox_displayIdleOnRight){
		[[adium preferenceController] setPreference:[NSNumber numberWithBool:NO]
											 forKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT
											  group:PREF_GROUP_IDLE_TIME_DISPLAY];
        [checkBox_displayIdleOnLeft setState:NSOffState];
		
    }else if(sender == colorWell_idleColor){
        [[adium preferenceController] setPreference:[[colorWell_idleColor color] stringRepresentation]
                                             forKey:KEY_IDLE_TIME_COLOR
                                              group:PREF_GROUP_IDLE_TIME_DISPLAY];
		
    }
	
}

//Private ---------------------------------------------------------------------------
//init
- (id)init
{
    //Init
    [super init];

    //Register our preference pane
    [[adium preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_ContactList_Contacts withDelegate:self label:IDLE_TIME_DISPLAY_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:IDLE_TIME_DISPLAY_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
	[colorWell_idleColor deactivate];
	
    [view_prefView release]; view_prefView = nil;
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[adium preferenceController] preferencesForGroup:PREF_GROUP_IDLE_TIME_DISPLAY];

    [checkBox_displayIdle setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME] boolValue]];
    [checkBox_displayIdleOnLeft setState:[[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT] boolValue]];
    [checkBox_displayIdleOnRight setState:![[preferenceDict objectForKey:KEY_DISPLAY_IDLE_TIME_ON_LEFT] boolValue]];
    [colorWell_idleColor setColor:[[preferenceDict objectForKey:KEY_IDLE_TIME_COLOR] representedColor]];

    [self configureControlDimming];
}
//Enable/disable controls that are available/unavailable
- (void)configureControlDimming
{
    [checkBox_displayIdleOnLeft setEnabled:[checkBox_displayIdle state]];
    [checkBox_displayIdleOnRight setEnabled:[checkBox_displayIdle state]];
    [colorWell_idleColor setEnabled:[checkBox_displayIdle state]];
}


@end

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

#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>
#import "Adium.h"
#import "AILoggerPreferences.h"
#import "AILoggerPlugin.h"

#define LOGGER_PREF_NIB		@"LoggerPrefs"
#define LOGGER_PREF_TITLE	@"Logging"

@interface AILoggerPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AILoggerPreferences

//
+ (AILoggerPreferences *)loggerPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Messages_Receiving withDelegate:self label:LOGGER_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:LOGGER_PREF_NIB owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_prefView);
}

//Configures our view for the current preferences
- (void)configureView
{
    NSDictionary	*preferenceDict = [[owner preferenceController] preferencesForGroup:PREF_GROUP_LOGGING];

    [checkBox_enableLogging setState:[[preferenceDict objectForKey:KEY_LOGGER_ENABLE] boolValue]];
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_prefView release]; view_prefView = nil;
}

//
- (IBAction)preferenceChanged:(id)sender
{
    if(sender == checkBox_enableLogging){
        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_LOGGER_ENABLE
                                              group:PREF_GROUP_LOGGING];
    }
}

@end

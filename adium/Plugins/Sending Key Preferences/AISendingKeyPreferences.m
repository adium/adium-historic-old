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
#import "AISendingKeyPreferences.h"

#define SENDING_KEY_PREF_NIB		@"SendingKeyPrefs"
#define SENDING_KEY_PREF_TITLE		@"Sending Keys"

@interface AISendingKeyPreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AISendingKeyPreferences

+ (AISendingKeyPreferences *)sendingKeyPreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//User changed a preference
- (IBAction)preferenceChanged:(id)sender
{
    if(sender == checkBox_sendOnEnter){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Enter"
                                              group:PREF_GROUP_GENERAL];
        
    }else if(sender == checkBox_sendOnReturn){
        [[owner preferenceController] setPreference:[NSNumber numberWithInt:[sender state]]
                                             forKey:@"Send On Return"
                                              group:PREF_GROUP_GENERAL];
        
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
    [NSBundle loadNibNamed:SENDING_KEY_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:SENDING_KEY_PREF_TITLE categoryName:PREFERENCE_CATEGORY_MESSAGES view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Load our preferences and configure the view
    preferenceDict = [[[owner preferenceController] preferencesForGroup:PREF_GROUP_GENERAL] retain];
    [self configureView];

    return(self);
}

//Configures our view for the current preferences
- (void)configureView
{
    [checkBox_sendOnEnter setState:[[preferenceDict objectForKey:@"Send On Enter"] intValue]];
    [checkBox_sendOnReturn setState:[[preferenceDict objectForKey:@"Send On Return"] intValue]];
}

@end


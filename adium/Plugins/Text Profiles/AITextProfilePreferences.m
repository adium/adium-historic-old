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

#import "AITextProfilePreferences.h"

#import <Adium/Adium.h>
#import <AIUtilities/AIUtilities.h>
#import "AIAdium.h"

#define TEXT_PROFILE_PREF_NIB		@"TextProfilePrefs"	//Name of preference nib
#define TEXT_PROFILE_PREF_TITLE		@"Profile"		//Title of the preference view

#define ADIUM_DEFAULT_PROFILE_STRING	@"Adium (www.adiumx.com)"	//Default user profile

@interface AITextProfilePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
@end

@implementation AITextProfilePreferences
//
+ (AITextProfilePreferences *)textProfilePreferencesWithOwner:(id)inOwner
{
    return([[[self alloc] initWithOwner:inOwner] autorelease]);
}

//Called in response to all preference controls, applies new settings
- (void)textDidEndEditing:(NSNotification *)notification;
{
    [[owner accountController] setStatusObject:[[textView_textProfile textStorage] dataRepresentation] forKey:@"TextProfile" account:nil];
}


//Private ---------------------------------------------------------------------------
//init
- (id)initWithOwner:(id)inOwner
{
    //Init
    [super init];
    owner = [inOwner retain];

    //Register our preference pane
    [[owner preferenceController] addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Accounts_Profile withDelegate:self label:TEXT_PROFILE_PREF_TITLE]];

    return(self);
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_prefView){
        [NSBundle loadNibNamed:TEXT_PROFILE_PREF_NIB owner:self];

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
    NSAttributedString	*profile = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"TextProfile" account:nil]];

    if(!profile){
        profile = [[NSAttributedString alloc] initWithString:ADIUM_DEFAULT_PROFILE_STRING];
    }
    
    [[textView_textProfile textStorage] setAttributedString:profile];
}

@end

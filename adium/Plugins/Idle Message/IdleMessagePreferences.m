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
#import "IdleMessagePreferences.h"
#import "IdleMessagePlugin.h"

#define IDLE_MESSAGE_PREF_NIB		@"IdleMessagePrefs"
#define IDLE_MESSAGE_PREF_TITLE		@"Idle Message"

@interface IdleMessagePreferences (PRIVATE)
- (id)initWithOwner:(id)inOwner;
- (void)configureView;
- (IBAction)changePreference:(id)sender;
@end

@implementation IdleMessagePreferences

+ (id)idleMessagePreferencesWithOwner:(id)inOwner
{
    return [[[self alloc] initWithOwner:inOwner] autorelease];
}


//init
- (id)initWithOwner:(id)inOwner
{
    AIPreferenceViewController	*preferenceViewController;

    [super init];
    owner = [inOwner retain];

    //Load the pref view nib
    [NSBundle loadNibNamed:IDLE_MESSAGE_PREF_NIB owner:self];

    //Install our preference view
    preferenceViewController = [AIPreferenceViewController controllerWithName:IDLE_MESSAGE_PREF_TITLE categoryName:PREFERENCE_CATEGORY_STATUS view:view_prefView];
    [[owner preferenceController] addPreferenceView:preferenceViewController];

    //Configure the view and load our preferences
    [self configureView];

    return self;
}

//configure our view
- (void)configureView
{
    NSAttributedString	*idleMessage = [NSAttributedString stringWithData:[[owner accountController] statusObjectForKey:@"IdleMessage" account:nil]];
    
    [checkBox_enableIdleMessage setState:[[[[owner preferenceController] preferencesForGroup:PREF_GROUP_IDLE_MESSAGE] objectForKey:KEY_IDLE_MESSAGE_ENABLED] boolValue]];
    
    [[textView_idleMessage textStorage] setAttributedString:idleMessage];
    
}

// Called in response to all preference controls, applies new settings
- (IBAction)changePreference:(id)sender
{

    // NSData	*newMessage;

    if(sender == checkBox_enableIdleMessage) {

        //Save the button's state
        // newMessage = [[textView_idleMessage textStorage] dataRepresentation];

        [[owner preferenceController] setPreference:[NSNumber numberWithBool:[sender state]]
                                             forKey:KEY_IDLE_MESSAGE_ENABLED
                                              group:PREF_GROUP_IDLE_MESSAGE];

    }
}

- (void)textDidEndEditing:(NSNotification *)notification;
{
    [[owner accountController] setStatusObject:[[textView_idleMessage textStorage] dataRepresentation] forKey:@"IdleMessage" account:nil];
    [[owner preferenceController] setPreference:[[textView_idleMessage textStorage] dataRepresentation]
                                         forKey:KEY_IDLE_MESSAGE
                                          group:PREF_GROUP_IDLE_MESSAGE];
}

@end

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
#import "AIMTOC2ServicePlugin.h"
#import "AIMTOC2Account.h"

@interface AIMTOC2ServicePlugin (PRIVATE)
- (void)configureView;
@end

@implementation AIMTOC2ServicePlugin

- (void)installPlugin
{
    AIPreferenceController	*preferenceController = [owner preferenceController];

    //Create our handle service type
    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
                          description:@"AIM, AOL, and .Mac"
                          image:[AIImageUtilities imageNamed:@"LilYellowDuck" forClass:[self class]]
                          caseSensitive:NO
                          allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789@."]] retain];
    
    //Register our default preferences
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:AIM_TOC2_DEFAULT_PREFS forClass:[self class]] forGroup:AIM_TOC2_PREFS];

    //Register our preference pane
    [preferenceController addPreferencePane:[AIPreferencePane preferencePaneInCategory:AIPref_Accounts_Hosts withDelegate:self label:AIM_TOC2_PREFERENCE_TITLE]];

    //Register this service
    [[owner accountController] registerService:self];
}

//Return the view for our preference pane
- (NSView *)viewForPreferencePane:(AIPreferencePane *)preferencePane
{
    //Load our preference view nib
    if(!view_preferences){
        [NSBundle loadNibNamed:AIM_TOC2_PREFERENCE_VIEW owner:self];

        //Configure our view
        [self configureView];
    }

    return(view_preferences);
}

//Clean up our preference pane
- (void)closeViewForPreferencePane:(AIPreferencePane *)preferencePane
{
    [view_preferences release]; view_preferences = nil;

}

//Configure our preference view
- (void)configureView
{
    NSDictionary	*preferencesDict = [[owner preferenceController] preferencesForGroup:AIM_TOC2_PREFS];

    //Fill in our host & port
    [textField_host setStringValue:[preferencesDict objectForKey:AIM_TOC2_KEY_HOST]];
    [textField_port setStringValue:[preferencesDict objectForKey:AIM_TOC2_KEY_PORT]];
}

- (void)uninstallPlugin
{
    //[[owner accountController] unregisterService:self];
    //unregister, remove, ...
}

//Return a new account with the specified properties
- (id)accountWithProperties:(NSDictionary *)inProperties owner:(id)inOwner
{
    return([[[AIMTOC2Account alloc] initWithProperties:inProperties service:self owner:inOwner] autorelease]);
}

// Return a Plugin-specific ID and description
- (NSString *)identifier
{
    return(@"AIM (TOC2)");
}
- (NSString *)description
{
    return(@"AOL Instant Messenger (TOC2)");
}

// Return an ID, description, and image for handles owned by accounts of this type
- (AIServiceType *)handleServiceType
{
    return(handleServiceType);
}

//Save changes made to a preference control
- (IBAction)preferenceChanged:(id)sender
{
    AIPreferenceController	*preferenceController = [owner preferenceController];

    if(sender == textField_host){
        [preferenceController setPreference:[textField_host stringValue] forKey:AIM_TOC2_KEY_HOST group:AIM_TOC2_PREFS];

    }else if(sender == textField_port){
        [preferenceController setPreference:[textField_port stringValue] forKey:AIM_TOC2_KEY_PORT group:AIM_TOC2_PREFS];

    }
}

@end

/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2002, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

@implementation AIMTOC2ServicePlugin

- (void)installPlugin
{
    AIPreferenceController	*preferenceController = [owner preferenceController];
    NSDictionary		*preferencesDict;


    handleServiceType = [[AIServiceType serviceTypeWithIdentifier:@"AIM"
                          description:@"AIM, AOL, and .Mac"
                          image:[AIImageUtilities imageNamed:@"LilYellowDuck" forClass:[self class]]
                          caseSensitive:NO
                          allowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz0123456789"]] retain];
    #warning the character sets are different because this code can't see @mac.com names... will there be any problem with doing this?

    //Load and retain our preferences
    [preferenceController registerDefaults:[NSDictionary dictionaryNamed:AIM_TOC2_DEFAULT_PREFS forClass:[self class]] forGroup:AIM_TOC2_PREFS];
    preferencesDict = [preferenceController preferencesForGroup:AIM_TOC2_PREFS];

    //Load, install, and configure our preference view
    [NSBundle loadNibNamed:AIM_TOC2_PREFERENCE_VIEW owner:self];
    [preferenceController addPreferenceView:[AIPreferenceViewController controllerWithName:AIM_TOC2_PREFERENCE_TITLE categoryName:PREFERENCE_CATEGORY_CONNECTIONS view:view_preferences]];
    
    [textField_host setStringValue:[preferencesDict objectForKey:AIM_TOC2_KEY_HOST]];
    [textField_port setStringValue:[preferencesDict objectForKey:AIM_TOC2_KEY_PORT]];
    [checkBox_ping setIntValue:[preferencesDict boolForKey:AIM_TOC2_KEY_PING]];

    //Register this service
    [[owner accountController] registerService:self];
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

    }else if(sender == checkBox_ping){
        [preferenceController setPreference:[NSNumber numberWithInt:[checkBox_ping intValue]] forKey:AIM_TOC2_KEY_PING group:AIM_TOC2_PREFS];

    }
}

//Is there any way to squelch the 'does not fully implement protocol' warnings besided this:?
- (id)retain{ return([super retain]); }
- (oneway void)release{ [super release]; }
- (id)autorelease { return([super autorelease]); }

@end

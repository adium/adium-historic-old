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
#import "AITextProfilesPlugin.h"
#import "AITextProfilePreferences.h"

#define CONTACT_PROFILE_NIB	@"ContactProfile"	//file name of the contact info profile nib

@interface AITextProfilesPlugin (PRIVATE)
- (void)displayProfile:(NSAttributedString *)profile;
@end

@implementation AITextProfilesPlugin

- (void)installPlugin
{
    //Register our defaults and install the preference view
    preferences = [[AITextProfilePreferences textProfilePreferencesWithOwner:owner] retain];

    //Register ourself as a handle observer
    [[owner contactController] registerContactObserver:self];

    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_PROFILE_NIB owner:self];
    contactProfileView = [[AIPreferenceViewController controllerWithName:@"Profile" categoryName:@"None" view:view_contactProfileInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactProfileView];

    //Configure the profile text view
    [textView_contactProfile setEditable:NO];
}

- (void)uninstallPlugin
{
    //unregister, remove, ...
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSAttributedString	*profile;

    //Hold onto the object
    [activeContactObject release]; activeContactObject = nil;
    if([inObject isKindOfClass:[AIListContact class]]){
        AIMutableOwnerArray	*ownerArray;
        
        activeContactObject = [inObject retain];

        //Let everyone know we want profile information
        [[owner notificationCenter] postNotificationName:Contact_UpdateStatus object:activeContactObject userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"TextProfile"] forKey:@"Keys"]];

        //Fill in the profile
        ownerArray = [activeContactObject statusArrayForKey:@"TextProfile"];
        if(ownerArray && [ownerArray count] != 0 && (profile = [ownerArray objectAtIndex:0])){
            [self displayProfile:profile];
        }else{
            [self displayProfile:nil];
        }
    }
}

//Called as profiles are set on a handle, update our display
- (NSArray *)updateContact:(AIListContact *)inContact keys:(NSArray *)inModifiedKeys
{
    //If we're currently displaying this handle, and it's profile changed...
    if(inContact == activeContactObject && [inModifiedKeys containsObject:@"TextProfile"]){
        AIMutableOwnerArray	*ownerArray;
        NSAttributedString	*profile;

        //Update our display with the new profile
        ownerArray = [activeContactObject statusArrayForKey:@"TextProfile"];
        if(ownerArray && [ownerArray count] != 0 && (profile = [ownerArray objectAtIndex:0])){
            [self displayProfile:profile];
        }else{
            [self displayProfile:nil];
        }
    }

    return(nil); //We've modified no display attributes, return nil
}

//Displays the attributed string in the profile window.  Pass nil for no profile
- (void)displayProfile:(NSAttributedString *)profile
{
    if(profile){
        NSColor	*backgroundColor;
        
        //Display the string
        [textView_contactProfile setString:@""];
        [[textView_contactProfile textStorage] setAttributedString:profile];

        //Set the background color
        backgroundColor = [profile attribute:AIBodyColorAttributeName atIndex:0 longestEffectiveRange:nil inRange:NSMakeRange(0,[profile length])];
        [textView_contactProfile setBackgroundColor:(backgroundColor ? backgroundColor : [NSColor whiteColor])];

    }else{
        //Remove any existing profile
        [textView_contactProfile setString:@""];

        //Set background back to white
        [textView_contactProfile setBackgroundColor:[NSColor whiteColor]];
        
    }

    [textView_contactProfile setNeedsDisplay:YES];
}

@end





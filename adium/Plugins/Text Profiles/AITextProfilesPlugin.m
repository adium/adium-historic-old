//
//  AITextProfilesPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Jan 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

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
- (NSArray *)updateContact:(AIListContact *)inContact handle:(AIHandle *)inHandle keys:(NSArray *)inModifiedKeys
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





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

@implementation AITextProfilesPlugin

- (void)installPlugin
{
    //Register our defaults and install the preference view
//    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:IDLE_TIME_DEFAULT_PREFERENCES forClass:[self class]] forGroup:PREF_GROUP_IDLE_TIME]; //Register our default preferences
    preferences = [[AITextProfilePreferences textProfilePreferencesWithOwner:owner] retain];

    //Observe preference changed notifications, and setup our initial values
//    [[[owner preferenceController] preferenceNotificationCenter] addObserver:self selector:@selector(preferencesChanged:) name:Preference_GroupChanged object:nil];
//    [self preferencesChanged:nil];

    //Register ourself as a handle observer
    [[owner contactController] registerHandleObserver:self];

    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_PROFILE_NIB owner:self];
    contactProfileView = [[AIPreferenceViewController controllerWithName:@"Profile" categoryName:@"None" view:view_contactProfileInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactProfileView];
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
    if([inObject isKindOfClass:[AIContactObject class]]){
        AIMutableOwnerArray	*ownerArray;
        
        activeContactObject = [inObject retain];

        //Let everyone know we want profile information
        [[owner notificationCenter] postNotificationName:Contact_UpdateStatus object:activeContactObject userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:@"TextProfile"] forKey:@"Keys"]];

        //Fill in the profile
        ownerArray = [activeContactObject statusArrayForKey:@"TextProfile"];
        if(ownerArray && [ownerArray count] != 0 && (profile = [ownerArray objectAtIndex:0])){
            [[textView_contactProfile textStorage] setAttributedString:profile];
        }else{
            [textView_contactProfile setString:@""];
        }
    }
}

//Called as profiles are set on a handle, update our display
- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys;
{
    //If we're currently displaying this handle, and it's profile changed...
    if(inHandle == activeContactObject && [inModifiedKeys containsObject:@"TextProfile"]){
        AIMutableOwnerArray	*ownerArray;
        NSAttributedString	*profile;

        //Update our display with the new profile
        ownerArray = [activeContactObject statusArrayForKey:@"TextProfile"];
        if(ownerArray && [ownerArray count] != 0 && (profile = [ownerArray objectAtIndex:0])){
            [[textView_contactProfile textStorage] setAttributedString:profile];
        }else{
            [textView_contactProfile setString:@""];
        }
    }

    return(nil); //We've modified no display attributes, return nil
}


@end





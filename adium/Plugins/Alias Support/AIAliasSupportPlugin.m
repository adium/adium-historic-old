//
//  AIAliasSupportPlugin.m
//  Adium
//
//  Created by Adam Iser on Tue Dec 31 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "AIAliasSupportPlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIUtilities.h>
#import <Adium/Adium.h>

#define	CONTACT_ALIAS_NIB		@"ContactAlias"		//Filename of the alias info view
#define	GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in
#define ALIASES_DEFAULT_PREFS		@"Alias Defaults"

@interface AIAliasSupportPlugin (PRIVATE)
- (void)applyAlias:(NSString *)inAlias toObject:(AIContactObject *)inObject;
@end

@implementation AIAliasSupportPlugin

- (void)installPlugin
{
    //Register our default preferences
    [[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ALIASES_DEFAULT_PREFS forClass:[self class]] forGroup:GROUP_ALIASES];

    //Register ourself as a handle observer
    [[owner contactController] registerHandleObserver:self];
    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" categoryName:@"None" view:view_contactAliasInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];

    activeContactObject = nil;
}

- (void)uninstallPlugin
{
    //[[owner contactController] unregisterHandleObserver:self];
}

- (IBAction)setAlias:(id)sender
{
    NSString	*alias = [textField_alias stringValue];
    
    //Apply
    [self applyAlias:alias toObject:activeContactObject];

    //Save the alias
    [[owner preferenceController] setPreference:alias forKey:@"Alias" group:GROUP_ALIASES object:activeContactObject];
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSString	*alias;
    
    //Hold onto the object
    [activeContactObject release]; activeContactObject = nil;
    if([inObject isKindOfClass:[AIContactObject class]]){
        activeContactObject = [inObject retain];

        //Fill in the current alias
        alias = [[owner preferenceController] preferenceForKey:@"Alias" group:GROUP_ALIASES object:inObject];
        if(alias){
            [textField_alias setStringValue:alias];
        }else{
            [textField_alias setStringValue:@""];
        }        
    }

}

//Called as handles are created, load their alias
- (NSArray *)updateHandle:(AIContactHandle *)inHandle keys:(NSArray *)inModifiedKeys;
{
    if(inModifiedKeys == nil){ //Only set an alias on handle creation
        NSString	*alias = [[owner preferenceController] preferenceForKey:@"Alias" group:GROUP_ALIASES object:inHandle];

        if(alias != nil && [alias length] != 0){
            [self applyAlias:alias toObject:inHandle];
        }
    }
    
    return(nil);
}

//Private ---------------------------------------------------------------------------------------
//Apply an alias to an object
- (void)applyAlias:(NSString *)inAlias toObject:(AIContactObject *)inObject
{
    AIMutableOwnerArray	*displayNameArray;
    
    displayNameArray = [inObject displayArrayForKey:@"Display Name"];
    [displayNameArray removeObjectsWithOwner:self];
    if(inAlias != nil && [inAlias length] != 0){
        [displayNameArray addObject:inAlias withOwner:self];
    }
    
    [[owner contactController] objectAttributesChanged:activeContactObject modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
}

@end





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

@implementation AIAliasSupportPlugin

- (void)installPlugin
{    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIPreferenceViewController controllerWithName:@"Alias" categoryName:@"None" view:view_contactAliasInfoView delegate:self] retain];
    [[owner contactController] addContactInfoView:contactView];

    activeContactObject = nil;
}

- (IBAction)setAlias:(id)sender
{
    AIMutableOwnerArray	*displayNameArray;
    
    NSString	*alias = [textField_alias stringValue];

    NSLog(@"Alias:%@",alias);

    displayNameArray = [activeContactObject displayArrayForKey:@"Display Name"];
    [displayNameArray removeObjectsWithOwner:self];
    [displayNameArray addObject:alias withOwner:self];
    
    [[owner contactController] objectAttributesChanged:activeContactObject modifiedKeys:[NSArray arrayWithObject:@"Display Name"]];
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    //Hold onto the object
    [activeContactObject release]; activeContactObject = nil;
    if([inObject isKindOfClass:[AIContactObject class]]){
        activeContactObject = [inObject retain];
    }
}


@end





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
}

- (IBAction)setAlias:(id)sender
{
    NSString	*alias = [textField_alias stringValue];

    NSLog(@"Alias:%@",alias);
}

- (void)configurePreferenceViewController:(AIPreferenceViewController *)inController forObject:(id)inObject
{
    NSLog(@"configure for %@",inObject);   
}


@end





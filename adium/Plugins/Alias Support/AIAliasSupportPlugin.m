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

#define	CONTACT_ALIAS_NIB		@"ContactAlias"		//Filename of the alias info view

@implementation AIAliasSupportPlugin

- (void)installPlugin
{    
    //Install the contact info view
    [NSBundle loadNibNamed:CONTACT_ALIAS_NIB owner:self];
    contactView = [[AIContactInfoViewController controllerWithName:@"Alias" categoryName:@"None" view:view_contactAliasInfoView] retain];
    [[owner contactController] addContactInfoView:contactView];    
}



@end

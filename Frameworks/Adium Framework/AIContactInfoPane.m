//
//  AIContactInfoPane.m
//  Adium
//
//  Created by Adam Iser on Sun May 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIContactInfoPane.h"


@implementation AIContactInfoPane

//Return a new contact info pane
+ (AIContactInfoPane *)contactInfoPane
{
    return([[[self alloc] init] autorelease]);
}

//Init
- (id)init
{
    [super init];
    [[adium contactController] addContactInfoPane:self];
    return(self);
}


//Resizable
- (BOOL)resizable
{
	return(YES);
}

- (CONTACT_INFO_CATEGORY)contactInfoCategory
{
	
}

//Configure the pane for a list object
- (void)configureForListObject:(AIListObject *)inListObject
{
	//Subclass
}


@end

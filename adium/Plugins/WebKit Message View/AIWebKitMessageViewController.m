//
//  AIWebKitMessageViewController.m
//  Adium XCode
//
//  Created by Adam Iser on Fri Feb 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AIWebKitMessageViewController.h"


@interface AIWebKitMessageViewController (PRIVATE)
- (id)initForChat:(AIChat *)inChat;
@end

@implementation AIWebKitMessageViewController

//Create a new message view
+ (AIWebKitMessageViewController *)messageViewControllerForChat:(AIChat *)inChat
{
    return([[[self alloc] initForChat:inChat] autorelease]);
}

//Init
- (id)initForChat:(AIChat *)inChat
{
    //init
    [super init];
    
	
    return(self);
}

- (NSView *)messageView
{
	return(nil);
}

//Dealloc
- (void)dealloc
{
    [super dealloc];
}

	
@end

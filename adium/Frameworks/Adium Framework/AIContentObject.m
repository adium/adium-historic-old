//
//  AIContentObject.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContentObject.h"
#import "AIChat.h"

@implementation AIContentObject

//
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest
{
    [super init];

    //Store source, dest, and chat
    source = [inSource retain];
    destination = [inDest retain];
    chat = [inChat retain];

    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];
    [chat release];

    [super dealloc];
}

//Message source (may return an AIListContact, or an AIAccount)
- (id)source
{
    return(source);
}

//Message destination (may return an AIListContact, or an AIAccount)
- (id)destination
{
    return(destination);
}

//Message chat
- (AIChat *)chat
{
    return(chat);
}

//Return the type ID of this content
- (NSString *)type
{
    return(@"");
}

//Is this content passed through content filters?
- (BOOL)filterContent
{
    return(YES);
}

//Is this content tracked with notifications
- (BOOL)trackContent
{
    return(YES);
}

//Is this content displayed?
- (BOOL)displayContent
{
    return(YES);
}



@end

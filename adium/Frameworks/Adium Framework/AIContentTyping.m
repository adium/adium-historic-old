//
//  AIContentTyping.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContentTyping.h"

@interface AIContentTyping (PRIVATE)
+ (id)initWithSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping;
@end

@implementation AIContentTyping

+ (id)typingContentWithSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping
{
    return([[[self alloc] initWithSource:inSource destination:inDest typing:inTyping] autorelease]);
}

//Return the type ID of this content
- (NSString *)type{
    return(CONTENT_TYPING_TYPE);
}

- (BOOL)filterObject
{
    return(NO); //There is no need to filter typing content
}

- (BOOL)trackObject
{
    return(NO); //Typing content should NOT be tracked by contacts
}

//Message source (may return a contact handle, or an account)
- (id)source{
    return(source);
}

//Message destination (may return a contact handle, or an account(
- (id)destination{
    return(destination);
}

//YES if typing, NO if not typing
- (BOOL)typing{
    return(typing);
}


// Private ------------------------------------------------------------------------------
//init
- (id)initWithSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping
{
    [super init];

    //Store source and dest
    source = [inSource retain];
    destination = [inDest retain];

    //Store typing
    typing = inTyping;
    
    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];

    [super dealloc];
}


@end

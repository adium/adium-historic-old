//
//  AIContentTyping.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "AIContentObject.h"
#import "AIContentTyping.h"

@interface AIContentTyping (PRIVATE)
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typing:(BOOL)inTyping;
@end

@implementation AIContentTyping

+ (id)typingContentInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping
{
    return([[[self alloc] initWithChat:inChat source:inSource destination:inDest typing:inTyping] autorelease]);
}

//Return the type ID of this content
- (NSString *)type{
    return(CONTENT_TYPING_TYPE);
}

- (BOOL)filterContent
{
    return(NO); //There is no need to filter typing content
}

- (BOOL)trackContent
{
    return(NO); //Typing content should NOT be tracked by contacts
}

- (BOOL)displayContent
{
    return(NO); //Typing content should NOT be displayed
}

//YES if typing, NO if not typing
- (BOOL)typing{
    return(typing);
}


// Private ------------------------------------------------------------------------------
//init
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typing:(BOOL)inTyping
{
    [super initWithChat:inChat source:inSource destination:inDest];

    //Store typing
    typing = inTyping;
    
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}


@end

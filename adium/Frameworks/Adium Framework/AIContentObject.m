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
    chat = inChat; //Not retained.  Chats hold onto, and store content.  Content need not hold onto chats.
    outgoing = ([source isKindOfClass:[AIAccount class]]);
    
    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];

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

//Is this content incoming or outgoing?
- (BOOL)isOutgoing
{
    return(outgoing);
}

//Message chat
- (AIChat *)chat
{
    return(chat);
}
- (void)setChat:(AIChat *)inChat
{
    chat = inChat;
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

//
//  AIContentObject.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import "AIContentObject.h"
#import "AIChat.h"

@implementation AIContentObject

//
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate*)inDate
{
    [super init];

	//
	filterContent = YES;
	trackContent = YES;
	displayContent = YES;
	
    //Store source, dest, and chat
    source = [inSource retain];
    destination = [inDest retain];

    chat = inChat; //Not retained.  Chats hold onto, and store content.  Content need not hold onto chats.
    outgoing = ([source isKindOfClass:[AIAccount class]]);
    
    //Store the date
    date = [inDate retain];	

    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];
	if(date) 
		[date release];

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

//Return the date and time this message was sent
- (NSDate *)date{
    return(date);
}

//Is this content incoming or outgoing?
- (BOOL)isOutgoing
{
    return(outgoing);
}
- (void)_setIsOutgoing:(BOOL)inOutgoing
{
	outgoing = inOutgoing;
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
- (BOOL)filterContent{
    return(filterContent);
}

//Is this content tracked with notifications
- (void)setTrackContent:(BOOL)inTrackContent{
	trackContent = inTrackContent;
}
- (BOOL)trackContent{
    return(trackContent);
}

//Is this content displayed?
- (void)setDisplayContent:(BOOL)inDisplayContent{
	displayContent = inDisplayContent;
}
- (BOOL)displayContent{
    return(displayContent);
}

@end

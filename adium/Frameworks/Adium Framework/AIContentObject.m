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
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate*)inDate{
	return([self initWithChat:inChat source:inSource destination:inDest date:inDate message:nil]);
}
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate*)inDate
		   message:(NSAttributedString *)inMessage
{
    [super init];
	
	//Default Behavior
	filterContent = YES;
	trackContent = YES;
	displayContent = YES;
	
    //Store source, dest, chat, ...
    source = [inSource retain];
    destination = [inDest retain];
	message = [inMessage retain];
	date = [(inDate ? inDate : [NSDate date]) retain];
	
    chat = inChat; //Not retained.  Chats hold onto content.  Content need not hold onto chats.
    outgoing = ([source isKindOfClass:[AIAccount class]]);
    
    return(self);
}

- (void)dealloc
{
    [source release];
    [destination release];
	[date release];
	[message release];

    [super dealloc];
}

//Content Identifier
- (NSString *)type
{
    return(@"");
}


//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
//Message Source and destination
- (AIListObject *)source{
    return(source);
}
- (AIListObject *)destination{
    return(destination);
}

//Date and time of this message
- (NSDate *)date{
    return(date);
}

//Is this content incoming or outgoing?
- (BOOL)isOutgoing{
    return(outgoing);
}
- (void)_setIsOutgoing:(BOOL)inOutgoing{ //Hack for message view preferences
	outgoing = inOutgoing;
}

//Chat containing this content
- (void)setChat:(AIChat *)inChat{
    chat = inChat;
}
- (AIChat *)chat{
    return(chat);
}

//Attributed Message
- (void)setMessage:(NSAttributedString *)inMessage{
	if(message != inMessage){
		[message release];
		message = [inMessage retain];
	}
}
- (NSAttributedString *)message{
	return(message);
}


//Behavior -------------------------------------------------------------------------------------------------------------
#pragma mark Behavior
//Is this content passed through content filters?
- (BOOL)setFilterContent:(BOOL)inFilterContent{
	filterContent = inFilterContent;
}
- (BOOL)filterContent{
    return(filterContent);
}

//Is this content tracked with notifications?
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

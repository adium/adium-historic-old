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
	sendContent = YES;
	postProcessContent = YES;

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

//Comparing ------------------------------------------------------------------------------------------------------------
#pragma mark Comparing
//Content is similar if it's from the same source, of the same time, and sent within 5 minutes.
- (BOOL)isSimilarToContent:(AIContentObject *)inContent
{
	if(source == [inContent source] && [[self type] compare:[inContent type]] == 0){
		NSTimeInterval	timeInterval = [date timeIntervalSinceDate:[inContent date]];
		
		return(timeInterval > -300 && timeInterval < 300);
	}
	
	return(NO);
}

//Content is from the same day
- (BOOL)isFromSameDayAsContent:(AIContentObject *)inContent
{
	NSCalendarDate *ourDate = [[self date] dateWithCalendarFormat:nil timeZone:nil];
	NSCalendarDate *inDate = [[inContent date] dateWithCalendarFormat:nil timeZone:nil];
	
	return([ourDate dayOfCommonEra] == [inDate dayOfCommonEra]);
}

//Content --------------------------------------------------------------------------------------------------------------
#pragma mark Content
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

//HTML string message
- (void)setMessageHTML:(NSString *)inMessageString{
	[message release];
	message = [[AIHTMLDecoder decodeHTML:inMessageString] retain];
}
- (NSString *)messageHTML{
	return [AIHTMLDecoder encodeHTML:message encodeFullString:YES];
}

//Plaintext string message
- (void)setMessageString:(NSString *)inMessageString{
	[message release];
	message = [[NSAttributedString alloc] initWithString:inMessageString
											  attributes:[[adium contentController] defaultFormattingAttributes]];
	
}
- (NSString *)messageString{
	return [message string];
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

- (void)setSendContent:(BOOL)inSendContent{
	sendContent = inSendContent;
}
- (BOOL)sendContent{
	return(sendContent);
}

- (void)setPostProcessContent:(BOOL)inPostProcessContent{
	postProcessContent = inPostProcessContent;
}
- (BOOL)postProcessContent{
	return(postProcessContent);
}

@end

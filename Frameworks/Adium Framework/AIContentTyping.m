//
//  AIContentTyping.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//

#import "AIContentObject.h"
#import "AIContentTyping.h"

@interface AIContentTyping (PRIVATE)
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typingState:(AITypingState)inTyping;
@end

@implementation AIContentTyping

+ (id)typingContentInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest typingState:(AITypingState)inTypingState
{
    return([[[self alloc] initWithChat:inChat source:inSource destination:inDest typingState:inTypingState] autorelease]);
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typingState:(AITypingState)inTypingState
{
    [super initWithChat:inChat source:inSource destination:inDest date:nil];
	
	//Typing content should NOT be filtered, tracked, or displayed
	filterContent = NO;
	trackContent = NO;
	displayContent = NO;
	
	//Store typing state
    typingState = inTypingState;
    
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

//Content Identifier
- (NSString *)type
{
    return(CONTENT_TYPING_TYPE);
}

//YES if typing, NO if not typing
- (void)setTypingState:(AITypingState)inTypingState{
	typingState = inTypingState;
}
- (AITypingState)typingState{
    return(typingState);
}

@end

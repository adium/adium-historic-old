//
//  AIContentTyping.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//

#import "AIContentObject.h"

#define CONTENT_TYPING_TYPE		@"Typing"		//Type ID for this content

typedef enum {
	AINotTyping = 0,
	AITyping,
	AIEnteredText
} AITypingState;

@interface AIContentTyping : AIContentObject {
    AITypingState			typingState;
}

+ (id)typingContentInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest typingState:(AITypingState)inTypingState;
- (AITypingState)typingState;

@end

//
//  AIContentTyping.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//

#import "AIContentObject.h"

#define CONTENT_TYPING_TYPE		@"Typing"		//Type ID for this content

@interface AIContentTyping : AIContentObject {
    BOOL			typing;
}

+ (id)typingContentInChat:(AIChat *)inChat withSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping;
- (BOOL)typing;

@end

//
//  AIContentTyping.m
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
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

//YES if typing, NO if not typing
- (BOOL)typing{
    return(typing);
}


// Private ------------------------------------------------------------------------------
//init
- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest typing:(BOOL)inTyping
{
    [super initWithChat:inChat source:inSource destination:inDest date:nil];

	//Typing content should NOT be filtered, tracked, or displayed
	filterContent = NO;
	trackContent = NO;
	displayContent = NO;

	//Store typing
    typing = inTyping;
    
    return(self);
}

- (void)dealloc
{
    [super dealloc];
}

@end

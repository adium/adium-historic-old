//
//  AIContentTyping.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

#define CONTENT_TYPING_TYPE		@"Typing"		//Type ID for this content

@interface AIContentTyping : NSObject <AIContentObject> {
    id 				source;
    id	 			destination;
    BOOL			typing;
}

+ (id)typingContentWithSource:(id)inSource destination:(id)inDest typing:(BOOL)inTyping;
- (NSString *)type;		//Return the unique type identifier for this object
- (id)source;
- (id)destination;
- (BOOL)typing;			//YES if typing, NO if not typing

@end

//
//  AIMessageText.h
//  Adium
//
//  Created by Adam Iser on Wed Sep 11 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AIAdium.h"

#define CONTENT_MESSAGE_TYPE		@"Message"		//Type ID for this content

@class AIContactHandle;

@interface AIContentMessage : NSObject <AIContentObject> {

    id 				source;
    id	 			destination;
    NSDate 			*date;
    NSAttributedString 		*message;
    
}

+ (id)messageWithSource:(id)inSource destination:(id)inDest date:(NSDate *)inDate message:(NSAttributedString *)inMessage;
- (NSString *)type;
- (NSAttributedString *)message;
- (id)source;
- (id)destination;
- (NSDate *)date;

@end

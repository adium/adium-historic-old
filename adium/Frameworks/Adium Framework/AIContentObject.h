//
//  AIContentObject.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIChat;

@interface AIContentObject : NSObject {
    AIChat	*chat;
    id		source;
    id		destination;
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest;
- (NSString *)type;
- (id)source;
- (id)destination;
- (AIChat *)chat;
- (void)setChat:(AIChat *)inChat;
- (BOOL)filterContent;
- (BOOL)trackContent;
- (BOOL)displayContent;

@end

//
//  AIContentObject.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import <Foundation/Foundation.h>

@class AIChat;

@interface AIContentObject : AIObject {
    AIChat	*chat;
    id		source;
    id		destination;
    BOOL	outgoing;

	BOOL	filterContent;
	BOOL	trackContent;
	BOOL	displayContent;	
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest;
- (NSString *)type;
- (id)source;
- (id)destination;
- (BOOL)isOutgoing;
- (AIChat *)chat;
- (void)setChat:(AIChat *)inChat;
- (BOOL)filterContent;
- (BOOL)trackContent;
- (BOOL)displayContent;
- (void)setTrackContent:(BOOL)inTrackContent;
- (void)setDisplayContent:(BOOL)inDisplayContent;

@end

//
//  AIContentObject.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//

#import <Foundation/Foundation.h>

@class AIChat;

@interface AIContentObject : AIObject {
    AIChat				*chat;
    id					source;
    id					destination;
    BOOL				outgoing;
    
	NSAttributedString	*message;
    NSDate  			*date;

	BOOL				filterContent;
	BOOL				trackContent;
	BOOL				displayContent;	
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate*)inDate;
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate*)inDate
		   message:(NSAttributedString *)inMessage;
- (NSString *)type;

- (id)source;
- (id)destination;
- (NSDate *)date;
- (BOOL)isOutgoing;
- (void)_setIsOutgoing:(BOOL)inOutgoing;
- (AIChat *)chat;
- (void)setChat:(AIChat *)inChat;
- (void)setMessage:(NSAttributedString *)inMessage;
- (NSAttributedString *)message;

- (BOOL)filterContent;
- (BOOL)trackContent;
- (BOOL)displayContent;
- (void)setTrackContent:(BOOL)inTrackContent;
- (void)setDisplayContent:(BOOL)inDisplayContent;
- (BOOL)setFilterContent:(BOOL)inFilterContent;

@end

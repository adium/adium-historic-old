//
//  AIContentObject.h
//  Adium
//
//  Created by Adam Iser on Sun Jun 15 2003.
//  Copyright (c) 2003-2005 The Adium Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIObject.h"

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
	BOOL				sendContent;
	BOOL				postProcessContent;
}

- (id)initWithChat:(AIChat *)inChat source:(id)inSource destination:(id)inDest date:(NSDate*)inDate;
- (id)initWithChat:(AIChat *)inChat
			source:(id)inSource
	   destination:(id)inDest
			  date:(NSDate*)inDate
		   message:(NSAttributedString *)inMessage;
- (NSString *)type;

//Comparing
- (BOOL)isSimilarToContent:(AIContentObject *)inContent;
- (BOOL)isFromSameDayAsContent:(AIContentObject *)inContent;

//Content
- (id)source;
- (id)destination;
- (NSDate *)date;
- (BOOL)isOutgoing;
- (void)_setIsOutgoing:(BOOL)inOutgoing;
- (AIChat *)chat;
- (void)setChat:(AIChat *)inChat;
- (void)setMessage:(NSAttributedString *)inMessage;
- (NSAttributedString *)message;

//Behavior
- (BOOL)filterContent;
- (BOOL)trackContent;
- (BOOL)displayContent;
- (void)setTrackContent:(BOOL)inTrackContent;
- (void)setDisplayContent:(BOOL)inDisplayContent;
- (BOOL)setFilterContent:(BOOL)inFilterContent;
- (void)setSendContent:(BOOL)inSendContent;
- (BOOL)sendContent;
- (void)setPostProcessContent:(BOOL)inPostProcessContent;
- (BOOL)postProcessContent;
@end

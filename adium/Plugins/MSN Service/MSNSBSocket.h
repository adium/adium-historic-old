//
//  MSNSBSocket.h
//  Adium
//
//  Created by Colin Barrett on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

@class AISocket, MSNAccount;

@interface MSNSBSocket : AIObject 
{
    AISocket 			*socket;		// The connection socket
    MSNAccount			*ourAccount;		// Us
    NSMutableDictionary	*participantsDict;	// everyone in this convo
    NSMutableDictionary	*unconfirmedMessagesDict;
    
    NSMutableArray		*packetsToSend;		// Packets we need to send out
    NSMutableDictionary	*tempInfoDict;		// Mostly to reduce class clutter
    BOOL				sendMessages;		// FALSE until we are clear to send messages
    BOOL				receivingPayload;
}

+ (MSNSBSocket *)socketWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account;

- (BOOL)isChat; //returns true if this is a "chat" or not
- (void)doEveryGoodThing;
- (void)sendPacket:(NSString *)packet;

- (AISocket *)socket;
- (NSDictionary *)participants;
@end

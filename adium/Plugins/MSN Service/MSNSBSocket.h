//
//  MSNSBSocket.h
//  Adium
//
//  Created by Colin Barrett on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Adium/Adium.h>

@class AISocket, MSNAccount;

@interface MSNSBSocket : NSObject 
{
    AISocket 		*socket;		// The connection socket
    MSNAccount		*ourAccount;		// Us
    NSMutableDictionary *participantsDict;	// everyone in this convo
    
    NSMutableArray	*packetsToSend;		// Packets we need to send out
}

+ (MSNSBSocket *)socketWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account;

- (BOOL)isChat; //returns true if this is a "chat" or not
- (void)checkForPackets;
- (void)sendPacket:(NSString *)packet;

- (AISocket *)socket;
- (NSDictionary *)participants;
@end

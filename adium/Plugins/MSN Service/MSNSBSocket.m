//
//  MSNSBSocket.m
//  Adium
//
//  Created by Colin Barrett on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "MSNSBSocket.h"
#import "MSNAccount.h"
#import <AIUtilities/AIUtilities.h>

@interface MSNSBSocket(PRIVATE)
- (MSNSBSocket *)initWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account;
@end

@implementation MSNSBSocket

/******************/
/* PUBLIC METHODS */
/******************/

+ (MSNSBSocket *)socketWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account
{
    return ([[[self alloc] initWithIP:ip andPort:port forAccount:account] autorelease]);
}

//returns true if this is a "chat" (and we should display a list of people)
- (BOOL)isChat
{
    return ([participantsDict count] >= 2);
}

- (void)checkForPackets
{

}

- (void)sendPacket:(NSString *)packet
{

}

- (AISocket *)socket
{
    return socket;
}

- (NSDictionary *)participants
{
    return(NSDictionary *)participantsDict;
}

/**********************/
/* SUBCLASSED METHODS */
/**********************/

- (void)dealloc
{
    [socket release];
    [ourAccount release];
    [participantsDict release];
    [packetsToSend release];
}

/*******************/
/* PRIVATE METHODS */
/*******************/

- (MSNSBSocket *)initWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account
{
    socket = [[AISocket socketWithHost:ip port:port] retain];
    ourAccount = [account retain];
    participantsDict = [[NSMutableDictionary alloc] init];
    packetsToSend = [[NSMutableArray alloc] init];
    
    return self;
}

@end
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
- (MSNSBSocket *)initWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account owner:(AIAdium *)setOwner;
- (void)_myLifeIsEnded;
- (void)_handleJoin:(NSString *)handle withFriendlyName:(NSString *)fName;
- (void)_handleLeave:(NSString *) handle;
@end

@implementation MSNSBSocket

/******************/
/* PUBLIC METHODS */
/******************/

+ (MSNSBSocket *)socketWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account owner:(AIAdium *)setOwner
{
    return ([[[self alloc] initWithIP:ip andPort:port forAccount:account owner:setOwner] autorelease]);
}

+ (MSNSBSocket *)socketWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account  owner:(AIAdium *)setOwner authenticationString:(NSString *)authStr sessionID:(NSString *)sesID
{
    MSNSBSocket	*sock = [MSNSBSocket socketWithIP:ip andPort:port forAccount:account owner:setOwner];
    [sock sendPacket:[NSString stringWithFormat:@"ANS 1 %@ %@ %@\r\n",
        [account UID], authStr, sesID]];
    return (sock);
}

//returns NO if this is a "chat" (and we should display a list of people)
- (BOOL)isChat
{
    return ([participantsDict count] >= 2);
}

- (void)doEveryGoodThing
{
    if ([socket isValid])
    {
        // Receive Packets	//
        NSData*		theData = nil;
        if (!receivingPayload) {
            // Receive normal commands
            if ([socket getDataToNewline:&theData remove:YES])
            {
                NSLog(@"sbSocket<<< %@", [NSString stringWithCString:[theData bytes] length:[theData length]-2]);
                NSArray *message = [[NSString stringWithCString:[theData bytes] length:[theData length]-2]
                    componentsSeparatedByString:@" "];

                NSString *command = [message objectAtIndex:0];

                if([command isEqualToString:@"MSG"]) //this needs to be outsourced to another part of the function, because we have to read in the payload length.
                {
                    receivingPayload = YESYES;
                    [tempInfoDict setObject:[NSNumber numberWithInt:[[message lastObject] intValue]] forKey:@"LoadLength"];
                    [tempInfoDict setObject:[NSString stringWithCString:[theData bytes] length:[theData length]-2] forKey:@"CmdString"];
                }
                else if([command isEqualToString:@"ANS"])
                {
                    NSLog (@"ANS OK command received (OK assumed)");
                    sendMessages = YES;
                }
                else if([command isEqualToString:@"JOI"])
                {
                    NSLog (@"JOI command received for user \"%@\" with address \"%@\"", [message objectAtIndex:2], [message objectAtIndex:1]);
                    
                    [self _handleJoin:[message objectAtIndex:1] withFriendlyName:[message objectAtIndex:2]];
                }
                else if([command isEqualToString:@"IRO"])
                {
                    NSLog (@"IRO %@ of %@ received: %@, known as %@", [message objectAtIndex:2], [message objectAtIndex:3], [message objectAtIndex:4], [message objectAtIndex:5]);
                    [self _handleJoin:[message objectAtIndex:4] withFriendlyName:[message objectAtIndex:5]];
                }
                else if([command isEqualToString:@"BYE"])
                {
                    NSLog (@"BYE command received for user w/ address \"%@\"", [message objectAtIndex:1]);

                    [self _handleLeave:[message objectAtIndex:1]];
                }
                else if([command isEqualToString:@"ACK"])
                {
                    [unconfirmedMessagesDict removeObjectForKey:[message objectAtIndex:1]];
                }
                else if([command isEqualToString:@"NAK"])
                {
                //Whine at the user
                    NSLog(@"Faiure to send message %@",
                            [unconfirmedMessagesDict objectForKey:[message objectAtIndex:1]]);

                    [ourAccount displayError:[NSString stringWithFormat:
                                              @"Failure to send message:\n%@",
                                              [unconfirmedMessagesDict objectForKey:[message objectAtIndex:1]]]];

                    [unconfirmedMessagesDict removeObjectForKey:[message objectAtIndex:1]];
                }
                else
                {
                    NSLog (@"Socket received unrecognized command:");
                    NSLog ([NSString stringWithCString:[theData bytes] length:[theData length]-2]);
                }
            }
        } else {
            // Receive payload
            
            unsigned short loadLength = [[tempInfoDict objectForKey:@"LoadLength"] intValue];

            if([socket getData:&theData ofLength:loadLength remove:YES])
            {	// AISocket will cache the data and return NO until it has retrieved the entire payload
                NSLog (@"Received payload of length %d. Payload:\n%@", loadLength, [NSString stringWithCString:[theData bytes] length:[theData length]]);
                NSArray *message = [[tempInfoDict objectForKey:@"CmdString"] componentsSeparatedByString:@" "];
                NSString *command = [message objectAtIndex:0];

                if ([command isEqualToString:@"MSG"])
                {
                    NSDictionary *messageLoad = [MSNAccount parseMessage:theData];
                    NSString	*contentType = [[[messageLoad objectForKey:@"Content-Type"] componentsSeparatedByString:@";"] objectAtIndex:0];

                    NSLog (@"***MSN Message received of type %@, content: %@", contentType, [messageLoad objectForKey:@"MSG Body"]);

                    if ([contentType isEqualToString:@"text/plain"])
                    {	// Received a message
                        AIContentMessage	*messageObject = nil;
                        AIHandle 			*handle = [[ourAccount availableHandles] objectForKey:[[participantsDict allKeys] objectAtIndex:0]];
                        AIListObject		*contact = [handle containingContact];
                        // (Do cool formatting stuff here)
                        NSLog (@"MSN Got message, sending to interface");
                        
                        // Not typing anymore, they sent!
                        [[handle statusDictionary]
                            setObject:[NSNumber numberWithInt:NO] forKey:@"Typing"];
                        [[owner contactController] handleStatusChanged:handle
                                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]
                                                               delayed:NO
                                                                silent:NO];
                        
                        //Add a content object for the message
                        messageObject = [AIContentMessage messageInChat:[[owner contentController] chatWithListObject:contact onAccount:ourAccount]
                                                             withSource:contact
                                                            destination:ourAccount
                                                                   date:nil
                                                                message:[[[NSAttributedString alloc] initWithString:[messageLoad objectForKey:@"MSG Body"]] autorelease]];
                        [[owner contentController] addIncomingContentObject:messageObject];
                    }
                    else if([messageLoad objectForKey:@"TypingUser"] != nil)
                    {
                        NSLog(@"typing");
                        //w00t. typing. ph33r.
                        AIHandle 			*handle = [[ourAccount availableHandles] objectForKey:[[participantsDict allKeys] objectAtIndex:0]];

                        [[handle statusDictionary]
                            setObject:[NSNumber numberWithInt:YES] forKey:@"Typing"];
                        [[owner contactController] handleStatusChanged:handle
                                                    modifiedStatusKeys:[NSArray arrayWithObject:@"Typing"]
                                                               delayed:NO
                                                                silent:NO];
                    }
                }
                else
                {
                    NSLog (@"MSN received received payload after command \"%@\", will not interpret.", [tempInfoDict objectForKey:@"CmdString"]);
                }
                
                //go back to reading
                [tempInfoDict removeObjectForKey:@"CmdString"];
                [tempInfoDict removeObjectForKey:@"LoadLength"];
                receivingPayload = NO;
            }
        }


        // Sending Commands	//
        long	curCommand = 0;

        while (curCommand < [packetsToSend count]){
            NSString	*sendMe = [packetsToSend objectAtIndex:curCommand];
            NSString	*commandBeingSent = nil;
            BOOL		sendIt = YES;

            // Check to see if we should send this
            if ([sendMe length] >= 3) {
                commandBeingSent = [sendMe substringToIndex:3];

                if (sendMessages == NO) {
                    if ([commandBeingSent isEqualToString:@"MSG"])
                        sendIt = NO;
                    /*else if ([commandBeingSent isEqualToString:@"ANS"]))
                        sendMessages = YES;*/	// Should wait for OK
                }
            }

            if ([sendMe isEqualToString:@"OUT"] &&
                (curCommand + 1) < [packetsToSend count] &&  sendIt) {
                // Move "OUT" to the end of the list of commands, since others are waiting to be
                // sent.  Keep the current one, too, so that no commands get skipped, or sent
                // improperly.
                //[packetsToSend removeObjectAtIndex:curCommand]
                [packetsToSend addObject:@"OUT"];
                sendIt = NO;
                NSLog (@"Move 'OUT' to end of queue. (should only happen once)");
            }

            // Send command
            if (sendIt)
                sendIt = [socket sendData:[sendMe dataUsingEncoding:NSUTF8StringEncoding]];
                // Now, sendIt refers to whether send happened.

            // React to whether the command was sent
            if (sendIt) {
                // Command was successfully sent to the server
                [packetsToSend removeObjectAtIndex:curCommand];
            } else {
                // Command failed to send.
                curCommand++;
                    // Move on to the next command, leaving this one for the next time around.
            }
        }
    }
    else
    {
        NSLog (@"Socket for %@ went invalid", @"some handle");
        [self _myLifeIsEnded];
    }
}

- (void)sendPacket:(NSString *)packet
{
    if (packet)
        [packetsToSend addObject:packet];
    else
        NSLog (@"Attempted to send NULL packet to %@.", @"someone");
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
    [tempInfoDict release];
}

/*******************/
/* PRIVATE METHODS */
/*******************/

- (MSNSBSocket *)initWithIP:(NSString *)ip andPort:(int)port forAccount:(MSNAccount *)account owner:setOwner
{
    owner = setOwner;
    socket = [[AISocket socketWithHost:ip port:port] retain];
    ourAccount = [account retain];
    participantsDict = [[NSMutableDictionary alloc] init];
    packetsToSend = [[NSMutableArray alloc] init];
    tempInfoDict = [[NSMutableDictionary alloc] init];
    sendMessages = NO;
    receivingPayload = NO;
    
    return self;
}

- (void)_myLifeIsEnded
{
    
}

- (void)_handleJoin:(NSString *)handle withFriendlyName:(NSString *)fName
{
    if ([participantsDict	objectForKey:handle] == nil) {
        if (fName == nil)
            fName = @"";
        [participantsDict	setObject:fName forKey:handle];
            // We might attach info later, but right now, I can't think of any.
        sendMessages = YES;
    }
}

- (void)_handleLeave:(NSString *) handle
{
    if ([participantsDict	objectForKey:handle] != nil) {
        [participantsDict	removeObjectForKey:handle];
            // We might attach info later, but right now, I can't think of any.
        if ([participantsDict count] == 0) {
            sendMessages = NO;
            [self sendPacket:@"OUT"];
        }
    }
}


@end
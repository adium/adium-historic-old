/*
 * Project:     Libezv
 * File:        AWEzvContactPrivate.m
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvContactPrivate.m,v 1.1 2004/05/15 18:47:09 evands Exp $
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004 Andrew Wellington.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AWEzvContactPrivate.h"
#import "AWEzvPrivate.h"
#import "AWEzvXMLStream.h"
#import "AWEzvXMLNode.h"
#import "AWEzvContactManager.h"
#import "AWEzvRendezvousData.h"
#import "AWEzvSupportRoutines.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation AWEzvContact (Private)
#pragma mark Various Handling Stuff

- (void) setStream:(AWEzvXMLStream *)stream {
    if (stream != _stream)
	[_stream release];
    _stream = [stream retain];

}

- (void) setStatus:(AWEzvStatus) status {
    _status = status;
}

- (void) setName:(NSString *)name {
     if (name != _name)
	[_name release];
    _name = [name retain];
}

- (void) setRendezvous:(AWEzvRendezvousData *)rendezvous {
    _rendezvous = rendezvous;
}

- (AWEzvRendezvousData *) rendezvous {
    return _rendezvous;
}

- (NSString *)ipaddr {
    return _ipAddr;
}

- (void) setIpaddr:(NSString *)myipaddr {
    if (_ipAddr != nil)
        [_ipAddr autorelease];
    _ipAddr = [myipaddr retain];
}

- (u_int16_t) port {
    return _port;
}

- (void) setPort:(u_int16_t)port {
    _port = port;
}

- (int) serial {
    return [_rendezvous serial];
}

- (void) setManager:(AWEzvContactManager *)manager {
    if (_manager != nil)
        [_manager autorelease];
    _manager = [manager retain];
}

- (AWEzvContactManager *) manager {
    return _manager;
}

#pragma mark Connection Handling
/* connect to contact if required */
- (void)createConnection {
    int			fd;
    struct sockaddr_in	socketAddress;	/* socket address structure */
    NSFileHandle	*connection;

    if (_stream != nil)
        return;

    if((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1) {
	AWEzvLog(@"Could not create socket to connect to contact for iChat Rendezvous");
	return;
    }

    /* setup socket address structure */
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sin_family = AF_INET;
    socketAddress.sin_addr.s_addr = inet_addr([_ipAddr UTF8String]);
    socketAddress.sin_port = htons([[_rendezvous getField:@"port.p2pj"] intValue]);
    
    /* connect to client */
    if (connect(fd, (const struct sockaddr *)&socketAddress, sizeof(socketAddress)) < 0) {
	AWEzvLog(@"Could not connect socket to contact");
	return;
    }
    
    /* make NSFileHandle */
    connection = [[NSFileHandle alloc] initWithFileDescriptor:fd];
    
    /* now to create stream */
    _stream = [[AWEzvXMLStream alloc] initWithFileHandle:connection initiator:1];
    [_stream setDelegate:self];
    [_stream readAndParse];
    
    [connection release];
}


#pragma mark XML Handling
- (void) XMLReceivedMessage:(AWEzvXMLNode *)root {
    /* XXX This routine is rather ugly! */
    AWEzvXMLNode    *node;
    NSString	    *plaintext = nil;
    NSString	    *html = nil;

    /* parse incoming message */
    if (([root type] == XMLElement) && ([[root name] compare:@"message"] == NSOrderedSame)) {
        if (([[root attributes] objectForKey:@"type"] != nil) && ([(NSString *)[[root attributes] objectForKey:@"type"] compare:@"chat"] == NSOrderedSame)) {
            NSEnumerator	*objs = [[root children] objectEnumerator];
            
            while ((node = [objs nextObject])) {
                if (([node type] == XMLElement) && ([[node name] compare:@"body"] == NSOrderedSame)) {
                    NSEnumerator	*childs = [[node children] objectEnumerator];
                        
                    while ((node = [childs nextObject])) {
                        if ([node type] == XMLText) {
                            plaintext = [node name];
                        }
                    }
                }
                
                if (([node type] == XMLElement) && ([[node name] compare:@"html"] == NSOrderedSame)) {
                    html = [node xmlString];
                }
		
		if (([node type] == XMLElement) && ([[node name] compare:@"x"] == NSOrderedSame)) {
		    [self XMLCheckForEvent:node];
		}
            }
            
        } else {
            NSEnumerator	*objs = [[root children] objectEnumerator];
            
            while ((node = [objs nextObject])) {
                if (([node type] == XMLElement) && ([[node name] compare:@"x"] == NSOrderedSame)) {
                    [self XMLCheckForEvent:node];
		}
            }
        }

	/* if we've got a message then we can send it to the client to display */
	if ([plaintext length] > 0)
	    [[[[self manager] client] client] user:self sentMessage:plaintext withHtml:html];
    }
}

- (void) XMLCheckForEvent:(AWEzvXMLNode *)node {
    NSEnumerator	*objs = [[node attributes] keyEnumerator];
    NSString		*key;
    AWEzvXMLNode	*obj;
    int			eventFlag = 0;

    /* check for events in jabber stream */
    while ((key = [objs nextObject])) {
        if (([key compare:@"xmlns"] == NSOrderedSame) && 
            ([(NSString *)[[node attributes] objectForKey:key] compare:@"jabber:x:event"] == NSOrderedSame)) {
            eventFlag = 1;
        }
    }
    
    if (!eventFlag)
        return;

    /* if we've got an event, check for typing action. this is all we support
       for now */
    objs = [[node children] objectEnumerator];
    while ((obj = [objs nextObject])) {
        if ([[obj name] compare:@"composing"] == NSOrderedSame) {
            [[[[self manager] client] client] user:self typingNotification:AWEzvIsTyping];
	    return;
        }
	[[[[self manager] client] client] user:self typingNotification:AWEzvNotTyping];
    }
}

- (void) XMLConnectionClosed {
    [_stream autorelease];
    _stream = nil;
}

@end

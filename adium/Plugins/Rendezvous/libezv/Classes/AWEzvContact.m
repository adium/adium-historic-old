/*
 * Project:     Libezv
 * File:        AWEzvContact.m
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvContact.m,v 1.3 2004/05/16 15:06:52 proton Exp $
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


#import "AWEzvContact.h"
#import "AWEzvContactPrivate.h"
#import "AWEzvXMLNode.h"
#import "AWEzvXMLStream.h"
#import "AWEzvRendezvousData.h"

@implementation AWEzvContact
- (NSString *)uniqueID {
    return _uniqueID;
}

- (NSString *) name {
    return _name;
}

- (AWEzvStatus) status {
    return _status;
}

- (NSString *) statusMessage {
    return [_rendezvous getField:@"msg"];
}

- (NSDate *) idleSinceDate {
    return _idleSinceDate;
}

- (void) setUniqueID:(NSString *)uniqueID {
    if (_uniqueID != nil)
        [_uniqueID autorelease];
    _uniqueID = [uniqueID retain];
}

- (void) setContactImage:(NSImage *)contactImage {
    if (_contactImage != nil)
	[_contactImage autorelease];
    _contactImage = [contactImage retain];
}

- (NSImage *) contactImage {
    return _contactImage;
}


#pragma mark Sending Messages
- (void) sendMessage:(NSString *)message withHtml:(NSString *)html {
    AWEzvXMLNode *messageNode, *bodyNode, *textNode, *htmlNode, *htmlBodyNode, *htmlMessageNode;
    
    if (_stream == nil) {
	[self createConnection];
    }
    
    /* setup XML tree */
    messageNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"message"];
    [messageNode addAttribute:@"to" withValue:_ipAddr];
    [messageNode addAttribute:@"type" withValue:@"chat"];
    
    bodyNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"body"];
    [messageNode addChild:bodyNode];
    
    textNode = [[AWEzvXMLNode alloc] initWithType:XMLText name:message];
    [bodyNode addChild:textNode];
    
    htmlNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"html"];
    [htmlNode addAttribute:@"xmlns" withValue:@"http://www.w3.org/1999/xhtml"];
    [messageNode addChild:htmlNode];
    
    htmlBodyNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"body"];
    [htmlBodyNode addAttribute:@"ichattextcolor" withValue:@"#000000"];
    [htmlNode addChild:htmlBodyNode];
    
    htmlMessageNode = [[AWEzvXMLNode alloc] initWithType:XMLRaw name:html];
    [htmlBodyNode addChild:htmlMessageNode];
    
    /* send the data */
    [_stream sendString:[messageNode xmlString]];
    
    /* release messages */
    [htmlMessageNode release];
    [htmlBodyNode release];
    [htmlNode release];
    [textNode release];
    [bodyNode release];
    [messageNode release];
}

- (void) sendTypingNotification:(AWEzvTyping)typingStatus {
    AWEzvXMLNode *messageNode, *bodyNode, *htmlNode, *htmlBodyNode, *xNode, *composingNode, *idNode = nil;
    
    messageNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"message"];
    [messageNode addAttribute:@"to" withValue:_ipAddr];
    
    bodyNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"body"];
    [messageNode addChild:bodyNode];

    htmlNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"html"];
    [htmlNode addAttribute:@"xmlns" withValue:@"http://www.w3.org/1999/xhtml"];
    [messageNode addChild:htmlNode];
    
    htmlBodyNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"body"];
    [htmlBodyNode addAttribute:@"ichattextcolor" withValue:@"#000000"];
    [htmlNode addChild:htmlBodyNode];
    
    xNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"x"];
    [xNode addAttribute:@"xmlns" withValue:@"jabber:x:event"];
    [messageNode addChild:xNode];
    
    if (typingStatus == AWEzvIsTyping) {
	composingNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"composing"];
	[xNode addChild:composingNode];
    }
    
    idNode = [[AWEzvXMLNode alloc] initWithType:XMLElement name:@"id"];
    [xNode addChild:idNode];
    
    /* send the data */
    [_stream sendString:[messageNode xmlString]];
    
    /* release messages */
    [idNode release];
    if (typingStatus == AWEzvIsTyping)
	[composingNode release];
    [xNode release];
    [htmlBodyNode release];
    [htmlNode release];
    [bodyNode release];
    [messageNode release];
    
}

@end

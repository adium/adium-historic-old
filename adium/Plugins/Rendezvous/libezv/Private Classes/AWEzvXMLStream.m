/*
 * Project:     Libezv
 * File:        AWEzvXMLStream.m
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvXMLStream.m,v 1.1 2004/05/15 18:47:09 evands Exp $
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


#import "AWEzvXMLStream.h"
#import "AWEzvXMLNode.h"
#import "AWEzvStack.h"

#import "AWEzvSupportRoutines.h"

#define XMLCALL
#include <expat.h> 

/* XML Function prototypes */
void xml_start_element	(void *userData,
                         const XML_Char *name,
                         const XML_Char **atts);
void xml_end_element	(void *userData,
                         const XML_Char *name);
void xml_char_data	(void *userData,
                         const XML_Char *s,
                         int len);


@implementation AWEzvXMLStream

- (id) initWithFileHandle:(NSFileHandle *)myConnection initiator:(int)myInitiator {
    self = [super init];
    
    connection = [myConnection retain];
    delegate = nil;
    nodeStack = [[AWEzvStack alloc] init];
    initiator = myInitiator;
    negotiated = 0;
    
    return self;
}

- (void)dealloc
{
	if (connection != nil) {
            [connection closeFile];
	    [connection release];
	}
	[super dealloc];
}

- (NSFileHandle *)fileHandle {
    return connection;
}

- (void) readAndParse {
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(dataReceived:)
					  name:NSFileHandleReadCompletionNotification
					  object:connection];
    [[NSNotificationCenter defaultCenter] addObserver:self
					  selector:@selector(dataAvailable:)
					  name:NSFileHandleDataAvailableNotification
					  object:connection];
    
    parser = XML_ParserCreate(NULL);
    XML_SetUserData(parser, self);
    XML_SetElementHandler(parser, &xml_start_element, &xml_end_element);
    XML_SetCharacterDataHandler(parser, &xml_char_data);
    XML_SetParamEntityParsing(parser, XML_PARAM_ENTITY_PARSING_NEVER);
    
    if (!negotiated && initiator) {
        [self sendNegotiationInitiator:initiator];
    }
    
    [connection waitForDataInBackgroundAndNotify];
    
}

- (void) sendData:(NSData *)data {
    [connection writeData:data];
}

- (void) sendString:(NSString *)string {
    [connection writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void) dataReceived:(NSNotification *)aNotification {
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    int	status;
    
    if ([data length] == 0) {
        [[aNotification object] autorelease];
        connection = nil;
        [delegate XMLConnectionClosed];
    }
    
    status = XML_Parse(parser, [data bytes], [data length], [data length] == 0 ? 1 : 0);
    
    [[aNotification object] waitForDataInBackgroundAndNotify];
}

- (void)dataAvailable:(NSNotification *)aNotification {
    [[aNotification object] readInBackgroundAndNotify];
}

- (void) closeFileHandle {
    [connection closeFile];
    connection = nil;
}

- (void) setDelegate:(id)myDelegate {
    delegate = myDelegate;
}
- (id) delegate {
    return delegate;
}

- (void) xmlStartElement:(const XML_Char *)name attributes:(const XML_Char **)attributes {
    AWEzvXMLNode    *node;
    NSString	    *attribute, *value, *nodeName;
    
    nodeName = [NSString stringWithUTF8String:name];
    
    node = [[[AWEzvXMLNode alloc] initWithType:XMLElement name:nodeName] autorelease];
    
    while (*attributes != NULL) {
        attribute = [NSString stringWithUTF8String:*attributes++];
        value = [NSString stringWithUTF8String:*attributes++];
        [node addAttribute:attribute withValue:value];
    }
    
    if ([nodeStack size] > 0 && [(AWEzvXMLNode *)[nodeStack top] type] == XMLText)
        [nodeStack pop];
    
    if ([nodeStack size] > 0) {
        [[nodeStack top] addChild:node];
    }
    
    [nodeStack push:node];
    
    if (([nodeName compare:@"stream:stream"] == NSOrderedSame) && !negotiated) {
        if (initiator) {
            negotiated = 1;
        } else {
            [self sendNegotiationInitiator:0];
        }
        node = [nodeStack pop];
    }
    

}

- (void) xmlEndElement:(const XML_Char *)name {
    NSString	    *nodeName;
    AWEzvXMLNode    *node;
    
    nodeName = [NSString stringWithUTF8String:name];

    if (([nodeStack size] > 0) && ([(AWEzvXMLNode *)[nodeStack top] type] == XMLText)) {
        node = [nodeStack pop];
    }
    
    node = [nodeStack top];
    
    if (node != nil && [[node name] compare:nodeName] == NSOrderedSame) {
        [nodeStack pop];
    } else if ([[node name] compare:@"stream:stream"] == NSOrderedSame) {
	// Wow, end of connection!
	[self sendString:@"</stream:stream>"];
	[connection closeFile];
	[delegate XMLConnectionClosed];
    } else {
        AWEzvLog(@"Ending node that is not at top of stack");
    }
    
    if ([nodeStack size] == 0 && node != nil) {
        if (delegate != nil)
            [delegate XMLReceivedMessage:node];
        else
            AWEzvLog(@"Received message but no delegate to send it to");
    }
    
}

- (void) xmlCharData:(const XML_Char *)data length:(int)len {
    AWEzvXMLNode    *node;
    NSString	    *newData;
    
    if ((len == 1) && (*data == '\n'))
        return;
    
    newData = [[[NSString alloc] initWithData:[NSData dataWithBytes:data length:len] encoding:NSUTF8StringEncoding] autorelease];
    
    if ([nodeStack size] > 0 && [(AWEzvXMLNode *)[nodeStack top] type] == XMLText) {
        node = [nodeStack top];
        if ([node name] != nil)
            [node setName:([[node name] stringByAppendingString:newData])];
        else
            [node setName:newData];
    } else {
        node = [[[AWEzvXMLNode alloc] initWithType:XMLText name:newData] autorelease];
        if ([nodeStack top] != nil)
            [[nodeStack top] addChild:node];
        [nodeStack push:node];
    }
}

- (void) sendNegotiationInitiator:(int)myInitiator {
    NSString		*string;
    NSMutableString	*mutableString;
    NSMutableDictionary	*dict;
    NSMutableArray	*array;
    
    CFXMLNodeRef	xmlNode;
    CFXMLElementInfo	xmlElementInfo;
    CFXMLTreeRef	xmlTree;
    NSData		*data;

    /* spit out an XML header */
    string = @"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>";
    [connection writeData:[NSData dataWithBytes:[string UTF8String] length:[string length]]];
    
    /* now make the handshake initialisation output */
    string = @"stream:stream";
    
    /* create elements for handshake */
    dict = [NSMutableDictionary dictionary];
    if (myInitiator)
	[dict setObject:@"127.0.0.1" forKey:@"to"];
    [dict setObject:@"jabber:client" forKey:@"xmlns"];
    [dict setObject:@"http://etherx.jabber.org/streams" forKey:@"xmlns:stream"];
    array = [NSMutableArray array];
    [array insertObject:@"xmlns:stream" atIndex:0];
    [array insertObject:@"xmlns" atIndex:0];
    if (myInitiator)
	[array insertObject:@"to" atIndex:0];
    
    /* and make an element info structure */
    xmlElementInfo.attributes = (CFDictionaryRef)[[dict copy] autorelease];
    xmlElementInfo.attributeOrder = (CFArrayRef)[[array copy] autorelease];
    xmlElementInfo.isEmpty = YES;
    
    /* create node and tree, then convert to XML text */
    xmlNode = CFXMLNodeCreate(NULL, kCFXMLNodeTypeElement, (CFStringRef)string, &xmlElementInfo, kCFXMLNodeCurrentVersion);
    xmlTree = CFXMLTreeCreateWithNode(NULL, xmlNode);
    (CFDataRef)data = CFXMLTreeCreateXMLData(NULL, xmlTree);
    
    /* now we create an NSString with our data */
    mutableString = [[[NSMutableString alloc] initWithCString:[data bytes] length:[data length]] autorelease];
    [mutableString deleteCharactersInRange:NSMakeRange([mutableString length] - 2, 1)];
    
    /* and we send it to the connection */
    [connection writeData:[NSData dataWithBytes:[mutableString UTF8String] length:[mutableString length]]];

    /* and set negoiated if we didn't initiate */
    if (!myInitiator)
        negotiated = 1;
}

@end

/* XML function handlers */
void xml_start_element	 (void *userData,
                          const XML_Char *name,
                          const XML_Char **atts) {
    AWEzvXMLStream  *self = userData;    
    [self xmlStartElement:name attributes:atts];
}

void xml_end_element	(void *userData,
                         const XML_Char *name) {
    AWEzvXMLStream  *self = userData;
    [self xmlEndElement:name];
}

void xml_char_data	(void *userData,
                         const XML_Char *s,
                         int len) {
    AWEzvXMLStream  *self = userData;
    [self xmlCharData:s length:len];
}

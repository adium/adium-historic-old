/*
 * Project:     Libezv
 * File:        AWEzvXMLNode.m
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvXMLNode.m,v 1.1 2004/05/15 18:47:09 evands Exp $
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

#import "AWEzvXMLNode.h"

#define DEFAULT_CAPACITY	10

@implementation AWEzvXMLNode


- (id) initWithType:(int)theType name:(NSString *)theName {
    self = [super init];
    
    type = theType;
    name = [theName copy];
    children = [[NSMutableArray alloc] initWithCapacity:DEFAULT_CAPACITY];
    attributes = [[NSMutableDictionary alloc] initWithCapacity:DEFAULT_CAPACITY];
    
    return self;
}

- (int) type {
    return type;
}
- (NSArray *)children {
    return [[children copy] autorelease];
}
- (void) addChild:(AWEzvXMLNode *)node {
    [children addObject:node];
}

- (NSDictionary *)attributes {
    return [[attributes copy] autorelease];
}

- (void) addAttribute:(NSString *)property withValue:(NSString *)value {
    [attributes setObject:value forKey:property];
}

- (NSString *)name {
    return name;
}

- (void) setName:(NSString *)theName {
    if (name != nil)
        [name autorelease];
    name = [theName retain];
}

- (NSString *)xmlString {
    NSMutableString	*string;
    NSEnumerator	*enumerator = [attributes keyEnumerator];
    NSString		*key;
    AWEzvXMLNode	*node;
    
    if (type == XMLText) {
        string = [[name mutableCopy] autorelease];
        [string replaceOccurrencesOfString:@"&" withString:@"&amp;" 
    options:0 range:NSMakeRange(0, [string length])];
        [string replaceOccurrencesOfString:@"<" withString:@"&lt;" 
    options:0 range:NSMakeRange(0, [string length])];
        [string replaceOccurrencesOfString:@">" withString:@"&gt;" 
    options:0 range:NSMakeRange(0, [string length])];
        return [[string copy] autorelease];
    }
    
    string = [NSMutableString stringWithString:@"<"];
    [string appendString:name];
    
    while ((key = [enumerator nextObject])) {
        [string appendFormat:@" %@=\"%@\"", key, [attributes objectForKey:key]];
    }
    
    [string appendString:@">"];
    
    enumerator = [children objectEnumerator];
    while ((node = [enumerator nextObject])) {
        [string appendString:[node xmlString]];
    }
    
    [string appendFormat:@"</%@>", name];
    
    return [[string copy] autorelease];
}
@end

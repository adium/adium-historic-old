/*
 * Project:     Libezv
 * File:        AWEzvContactManager.m
 *
 * Version:     1.0
 * Author:      Andrew Wellington <proton[at]wiretapped.net>
 *
 * License:
 * Copyright (C) 2004-2005 Andrew Wellington.
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

#import "AWEzvContactManager.h"
#import "AWEzvContactPrivate.h"

@implementation AWEzvContactManager

- (id)initWithClient:(AWEzv *)newClient 
{
    if ((self = [super init])) {
		contacts = [[NSMutableDictionary alloc] init];
		client = newClient;
		isConnected = NO;
	}

    return self;
}

- (AWEzvContact *)contactForIdentifier:(NSString *)uniqueID {
    AWEzvContact *contact;
    contact = [contacts objectForKey:uniqueID];
    /* try a case insensitive search if not found */
    if (contact == nil) {
	NSEnumerator *enumerator = [contacts objectEnumerator];

	while ((contact = [enumerator nextObject])) {
	    if ([[contact uniqueID] caseInsensitiveCompare:uniqueID] == NSOrderedSame)
		break;
	}
    }
    return contact;
}
- (void)closeConnections{
	NSEnumerator *enumerator = [contacts objectEnumerator];
    AWEzvContact *contact;

	while ((contact = [enumerator nextObject])) {
		if ([contact stream] != NULL)
			[[contact stream] endConnection];
	}
}

- (AWEzv *)client {
    return client;
}

- (void)dealloc {
	/* AWEzvContactManagerListener adds an observer; remove it */
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[userAnnounceData release];

	[super dealloc];
}

@end

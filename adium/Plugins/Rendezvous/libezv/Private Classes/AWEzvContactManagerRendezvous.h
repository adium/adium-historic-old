/*
 * Project:     Libezv
 * File:        AWEzvContactManagerRendezvous.h
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvContactManagerRendezvous.h,v 1.1 2004/05/15 18:47:09 evands Exp $
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

/* IMPORTANT NOTE:
 * The rendezvous part of this library is implemented using the low-level Mach
 * port messaging to the mDNSResponser due to bugs in NSNetService. These bugs
 * include the inability to modify the TXT record of an advertised service, when
 * a service is no longer being published TXT records associated with the
 * service are not released and the inability to observe changes in the TXT
 * records of others.Until these bugs are fixed, we will continue to use the
 * Mach messaging interface to mDNSResponder (or another interface with similar
 * capabilities) instead of NSNetService/NSNetServiceBrowser
 */


#import <Foundation/Foundation.h>
#import "AWEzvContactManager.h"
#import "AWEzvDefines.h"

@interface AWEzvContactManager (Rendezvous)
- (void) login;
- (void) logout;
- (void) disconnect;
- (void) setConnected:(BOOL)connected;

- (void) setStatus:(AWEzvStatus)status withMessage:(NSString *)message;
- (void) updateAnnounceInfo;
- (void) updatedName;
- (void) updatedStatus;
- (void)setImageData:(NSData *)JPEGData;

- (void) startBrowsing;
- (void)browseResult:(DNSServiceBrowserReplyResultType)resultType
	name:(const char *)replyName
	type:(const char *)replyType
	domain:(const char *)replyDomain
	flags:(DNSServiceDiscoveryReplyFlags)flags;
- (void)updateContact:(AWEzvContact *)iccontact
	withData:(AWEzvRendezvousData *)rendezvousData
	withAddress:(struct sockaddr *) address;
	
- (NSString *)myname;

@end

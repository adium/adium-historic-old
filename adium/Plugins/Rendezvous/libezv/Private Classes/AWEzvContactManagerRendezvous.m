/*
 * Project:     Libezv
 * File:        AWEzvContactManagerRendezvous.m
 *
 * Version:     1.0
 * CVS tag:     $Id: AWEzvContactManagerRendezvous.m,v 1.1 2004/05/15 18:47:09 evands Exp $
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

#import "AWEzvContactManager.h"
#import "AWEzvContactManagerRendezvous.h"
#import "AWEzv.h"
#import "AWEzvPrivate.h"
#import "AWEzvContact.h"
#import "AWEzvContactPrivate.h"
#import "AWEzvRendezvousData.h"

#import "AWEzvSupportRoutines.h"

#include <DNSServiceDiscovery/DNSServiceDiscovery.h>

#include "sha1.h"

/* One of the stupidest things I've ever met. Doing DNS lookups using the standard
 * functions does not for mDNS records work unless you're in BIND 8 compatibility
 * mode. And of course how do you get data from say a NULL record for iChat stuff?
 * With the standard DNS functions. So we have to use BIND 8 mode. Which means we
 * have to implement our own DNS packet parser. What were people thinking here?
 */
#define BIND_8_COMPAT 1
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/nameser.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <resolv.h>
#include <errno.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

/* DNS parser will want this */
typedef struct
{
    u_int16_t 	type;
    u_int16_t 	class;
    u_int32_t 	ttl;
    u_int16_t 	length;

} rr_header;

/* C-helper function prototypes */
void handleMachMessage (CFMachPortRef port, void *msg, CFIndex size, void *info);
void reg_reply     (int errorCode, void *context);
void browse_reply  (DNSServiceBrowserReplyResultType resultType,
		    const char *replyName,
		    const char *replyType,
		    const char *replyDomain,
		    DNSServiceDiscoveryReplyFlags flags,
		    void *context);
void resolve_reply (struct sockaddr	*interface,
		    struct sockaddr	*address,
		    const char		*txtRecord,
		    DNSServiceDiscoveryReplyFlags flags,
		    void		*context);

@implementation AWEzvContactManager (Rendezvous)
#pragma mark Announcing Functions
- (void) login {
    /* used for Mach messaging version */
    CFRunLoopSourceRef	rls;
    CFMachPortRef	cfMachPort;
    CFMachPortContext	context;
    Boolean		shouldFreeInfo;
    dns_service_discovery_ref	dns_client;
    mach_port_t		mach_port;
    
    /* used for any version */
    NSHost		*currentHost;
    NSMutableString	*instanceName;
    NSEnumerator        *enumerator;
    NSRange             range;
    
    /* create data structure we'll advertise with */
    userAnnounceData = [[AWEzvRendezvousData alloc] init];
    
    /* set field contents of the data */
    [userAnnounceData setField:@"1st" content:[client name]];
    [userAnnounceData setField:@"last" content:@""];
    [userAnnounceData setField:@"AIM" content:@""];
    [userAnnounceData setField:@"email" content:@""];
    [userAnnounceData setField:@"port.p2pj" content:[NSString stringWithFormat:@"%u", port]];
    [self setStatus:[client status] withMessage:nil];
    
    /* calculate instance name */
    currentHost = [NSHost currentHost];
    enumerator = [[currentHost addresses] objectEnumerator];
    while ((instanceName = [enumerator nextObject])) {
	/* skip 127.0.0.1 */
        if ([instanceName compare:@"127.0.0.1"] == NSOrderedSame)
            continue;
	/* and skip IPv6 */
        range = [instanceName rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
        if (range.location != NSNotFound)
            continue;
        break;
    }
    
    if (instanceName == nil) {
	[[client client] reportError:@"No available IPv4 interfaces" ofLevel:AWEzvError];
	return;
    }
    /* replace . with _ for rendezvous name, this is for iChat 1.0 */
    instanceName = [[instanceName mutableCopy] autorelease];
    [instanceName replaceOccurrencesOfString:@"."
		  withString:@"_"
		  options:0
		  range:NSMakeRange(0, [instanceName length])];
    myname = [instanceName retain];
    
    /* initialise context */
    context.version	= 1;
    context.info	= 0;
    context.retain	= NULL;
    context.release	= NULL;
    context.copyDescription = NULL;
    
    /* register service with mDNSResponder */
    dns_client = DNSServiceRegistrationCreate (
	    [instanceName UTF8String],
	    "_ichat._tcp",
	    "",
	    port,
	    [[userAnnounceData dataAsDNSTXT] UTF8String],
	    reg_reply,
	    self
	    );

    /* get mach port and configure for run loop */
    mach_port = DNSServiceDiscoveryMachPort(dns_client);
    if (mach_port) {
	cfMachPort = CFMachPortCreateWithPort (kCFAllocatorDefault, mach_port,
			    (CFMachPortCallBack) handleMachMessage, &context,
			    &shouldFreeInfo);
	
	/* setup run loop */
	rls = CFMachPortCreateRunLoopSource (NULL, cfMachPort, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
	CFRelease(rls);
	
	/* save data for later release */
	dnsRef = dns_client;
    } else {
	AWEzvLog(@"Could not obtain client port for Mach messaging (advertise)");
	[[client client] reportError:@"Could not obtain client port for Mach messaging (advertise)"
		ofLevel:AWEzvError];
	[self disconnect];
    }


}

/* this is used for a clean logout */
- (void) logout {
    [self disconnect];
    
    [[client client] reportLoggedOut];
}

/* this causes an actual disconnect */
- (void) disconnect {
    if (dnsRef != NULL) {
	DNSServiceDiscoveryDeallocate(dnsRef);
	dnsRef = NULL;
	isConnected = NO;
	if (myname != nil) {
	    [myname release];
	    myname = nil;
	}
    }
}

- (void) setConnected:(BOOL)connected {
    isConnected = connected;
    if (connected)
	[[client client] reportLoggedIn];
    else
	[[client client] reportLoggedOut];
}   

- (void)setStatus:(AWEzvStatus)status withMessage:(NSString *)message {
    NSString	*statusString;		/* string for use in Rendezous field */
    
    /* work out the string for rendezvous */
    switch (status) {
    	case AWEzvIdle:
	    statusString = @"away";
	    break;
	case AWEzvAway:
	    statusString = @"dnd";
	    break;
	case AWEzvOnline:
	    statusString = @"avail";
	    break;
	default:
	    /* if something weird, default to available */
	    statusString = @"avail";
    }
    
    /* add it to our data */
    [userAnnounceData setField:@"status" content:statusString];

    /* now set the message */
    if ([message length]) {
        [userAnnounceData setField:@"msg" content:message];
    } else {
        [userAnnounceData deleteField:@"msg"];
    }
    
    /* announce to network */
    if (isConnected == YES)
	[self updateAnnounceInfo];
}

/* udpates information announced over network for user */
- (void) updateAnnounceInfo {
    NSData *mydata;
    DNSServiceRegistrationReplyErrorType errorCode;

    if (!isConnected)
	return;

    /* get data to be announced */
    mydata = [userAnnounceData dataAsPackedPString];
    
    /* register it */
    errorCode = DNSServiceRegistrationUpdateRecord(dnsRef, NULL, [mydata length], [mydata bytes], 3600);
    if (errorCode < 0) {
	AWEzvLog(@"Received Rendezvous error %d when updating TXT record", errorCode);
	[[client client] reportError:@"Received Rendezvous errorwhen updating TXT record"
		ofLevel:AWEzvError];
	[self disconnect];
    }
}

- (void) updatedName {
    [userAnnounceData setField:@"1st" content:[client name]];
    [self updateAnnounceInfo];
}

- (void) updatedStatus {
    [self setStatus:[client status] withMessage:nil];
}

- (void)setImageData:(NSData *)JPEGData {
    NSData *plist;
    NSString *error;
    SHA1_CTX ctx;
    unsigned char digest[20];

    plist = [NSPropertyListSerialization dataFromPropertyList:JPEGData
    				    format:NSPropertyListXMLFormat_v1_0
    				    errorDescription:&error];
    SHA1Init(&ctx);
    SHA1Update(&ctx, (unsigned char*)[JPEGData bytes], [JPEGData length]);
    SHA1Final(digest, &ctx);
    /* This is for coverting to text, not needed for original iChat style records
    for (i = 0; i < 20; i++) {
	sprintf(textdigest + (i*2), "%.2x", digest[i]);
	printf("%s\n", textdigest);
    }
    */
    
    if (plist != nil) {
	if (imageRef == NULL) {
	    imageRef = DNSServiceRegistrationAddRecord(dnsRef, T_NULL, [plist length], [plist bytes], 10);
	} else {
	    DNSServiceRegistrationUpdateRecord(dnsRef, imageRef, [plist length], [plist bytes], 10);
	}
	[userAnnounceData setField:@"phsh" content:[NSData dataWithBytes:digest length:20]];
	/* announce to network */
	[self updateAnnounceInfo];
    }
}

#pragma mark DNS Decoders
/* DNS Decoding based on Apple Sample Code 
   This is modified code, not original Apple Sample Code */
static int decode_name(char** location, char* buffer, int len)
{
    char name[64];
    char* name_loc = *location;
    char* last_loc = name_loc;
    u_int8_t name_len;

    name_len = *(u_int8_t*)name_loc;

    while (name_len != 0)
    {
        if ((name_len & INDIR_MASK) == INDIR_MASK)
        {
            // compressed name
            if (name_loc >= *location)
                *location = name_loc + 2;

            name_loc = ((*(u_int16_t*)name_loc) & (~(INDIR_MASK << 8))) + buffer;

            if (name_loc >= *location)
            {
                AWEzvLog(@"DNS Name decode error, compression offset invalid!");
                return -2;
            }

            if (name_loc == last_loc)
                AWEzvLog(@"DNS Name decode error, compression offset yields loop!");
	      
            last_loc = name_loc;
        }
        else
        {
            int i = 0;

            if (name_loc + name_len > buffer + len)
            {
                AWEzvLog(@"DNS Name decode error, name extends past end of packet");
                return -3;
            }

            for (i = 0; i < name_len; i++)
                name[i] = name_loc[i + 1];
            name[i] = 0;

            name_loc += name_len + 1;
            if (name_loc > *location)
                *location = name_loc + 1;
        }

        name_len = *name_loc;
    }
    
    return 0;
}

NSData *decode_rr(char** location, char* buffer, int len)
{
    NSData *nullrr;
    rr_header* header;
    
    if (*location >= buffer + len || *location < buffer)
    {
        AWEzvLog(@"DNS Answer decode error, ran off the buffer");
        return nil;
    }

    if (decode_name(location, buffer, len) != 0)
        return nil;

    header = (rr_header*)*location;

    if (*location + sizeof(rr_header) >= buffer + len)
    {
        AWEzvLog(@"DNS Answer decode error, packet too short for type, class, ttl, and length");
        return nil;
    }
    
    *location += sizeof(rr_header) - 2;

    if (*location + ntohs(header->length) > buffer + len)
    {
        AWEzvLog(@"DNS Answer decode error, packet too short (%u) for reported rr length (%u)", (buffer + len), *location + ntohs(header->length));
	return nil;
    }

    switch(ntohs(header->type))
    {
	case T_NULL:
	    nullrr = [NSData dataWithBytes:*location length:header->length];
	    return nullrr;
        default:
	  break;
    }
    *location += ntohs(header->length);

    return 0;
}



NSData *decode_dns(char* buffer, int len )
{
    HEADER * hdr = (HEADER*)buffer;
    char* loc = buffer + sizeof(HEADER);
    
    int	i = 0;

    if (len < sizeof(HEADER))
    {
        AWEzvLog(@"DNS NULL response too short");
        return nil;
    }

    for (i = 0; i < hdr->qdcount; i++)
    {
	if (loc >= buffer + len || loc < buffer)
	{
	    AWEzvLog(@"DNS Question decode error, ran off the buffer");
	    return nil;
	}
	
	if (decode_name(&loc, buffer, len) != 0)
	{
	    AWEzvLog(@"DNS Question decode error, bad name");
	    return nil;
	}
	
	loc += sizeof(u_int16_t);
	loc += sizeof(u_int16_t);
    }

    for (i = 0; i < hdr->ancount; i++)
    {
        return (decode_rr(&loc, buffer, len));
	    
    }
    
    return nil;
}


#pragma mark Browsing Functions
/* start browsing the network for new rendezvous clients */
- (void) startBrowsing {
    CFMachPortRef	cfMachPort;
    CFMachPortContext	context;
    Boolean		shouldFreeInfo;
    mach_port_t		mach_port;
    CFRunLoopSourceRef	rls;
    
    /* destroy old browser if one exists */
    if (browseRef) {
	DNSServiceDiscoveryDeallocate(browseRef);
	browseRef = nil;
    }
    
    /* destroy old contact dictionary if one exists */
    if (contacts)
	[contacts release];
	
    /* allocate new contact dictionary */
    contacts = [[NSMutableDictionary alloc] init];
	
    /* initialise context */
    context.version	= 1;
    context.info	= 0;
    context.retain	= NULL;
    context.release	= NULL;
    context.copyDescription = NULL;
    
    /* create browser */
    browseRef = DNSServiceBrowserCreate (
	    "_ichat._tcp",
	    "",
	    browse_reply,
	    self
	    );
    
    /* get mach port */
    mach_port = DNSServiceDiscoveryMachPort(browseRef);
    
    /* if port was successfully created */
    if (mach_port) {
	/* Core foundation port */
	cfMachPort = CFMachPortCreateWithPort (kCFAllocatorDefault, mach_port, (CFMachPortCallBack) handleMachMessage, &context, &shouldFreeInfo);
	
	/* setup run loop */
	rls = CFMachPortCreateRunLoopSource (NULL, cfMachPort, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
	CFRelease(rls);
    } else {
	AWEzvLog(@"Could not obtain client port for Mach messaging (browse)");
	[[client client] reportError:@"Could not obtain client port for Mach messaging (browse)"
		ofLevel:AWEzvError];
	[self disconnect];
    }
}

/* handle a message from our browser */
- (void)browseResult:(DNSServiceBrowserReplyResultType)resultType
	name:(const char *)replyName
	type:(const char *)replyType
	domain:(const char *)replyDomain
	flags:(DNSServiceDiscoveryReplyFlags)flags {
	
    /* mach port variables */
    CFMachPortRef	cfMachPort;
    CFMachPortContext	context;
    Boolean		shouldFreeInfo;
    dns_service_discovery_ref	dns_client;
    mach_port_t		mach_port;
    CFRunLoopSourceRef	rls;
    
    AWEzvContact	*contact;
    
    if (resultType == DNSServiceBrowserReplyRemoveInstance) {
	/* delete the contact */
        contact = [contacts objectForKey:[NSString stringWithCString:replyName]];

	[[client client] userLoggedOut:contact];
    
	/* remove the contact from our data structures */
	[contacts removeObjectForKey:[NSString stringWithCString:replyName]];
	return;
    } else if (resultType != DNSServiceBrowserReplyAddInstance) {
	AWEzvLog(@"Unknown rendezvous browser return type");
	return;
    }
    
    /* at this stage we must be handling adding an instance */
    
    /* initialise contact */
    contact = [[AWEzvContact alloc] init];
    [contact setUniqueID:[NSString stringWithCString:replyName]];
    [contact setManager:self];
    /* save contact in dictionary */
    [contacts setObject:contact forKey:[NSString stringWithCString:replyName]];
    
    /* and resolve contact */
    /* initialise context */
    context.version	= 1;
    context.info	= 0;
    context.retain	= NULL;
    context.release	= NULL;
    context.copyDescription = NULL;
    
    /* start the resolver */
    dns_client = DNSServiceResolverResolve (
	    replyName,
	    replyType,
	    replyDomain,
	    resolve_reply,
	    contact
	    );
	    
    /* get the mach port */
    mach_port = DNSServiceDiscoveryMachPort(dns_client);
    
    /* if we got a port */
    if (mach_port) {
	/* Core foundation port */
	cfMachPort = CFMachPortCreateWithPort (kCFAllocatorDefault, mach_port, (CFMachPortCallBack) handleMachMessage, &context, &shouldFreeInfo);
	
	/* setup run loop */
	rls = CFMachPortCreateRunLoopSource (NULL, cfMachPort, 0);
	CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
	CFRelease(rls);
    } else {
	AWEzvLog(@"Could not obtain client port for Mach messaging (resolve)");
	[[client client] reportError:@"Could not obtain client port for Mach messaging (resolve)"
		ofLevel:AWEzvError];
	[self disconnect];
    }
}

- (void)updateContact:(AWEzvContact *)contact
	withData:(AWEzvRendezvousData *)rendezvousData
	withAddress:(struct sockaddr *) address {
    NSString		*nick = nil;			/* nickname for contact */
    NSMutableString	*mutableNick = nil;		/* nickname we can modify */
    NSString		*ipAddr;			/* ip address of contact */
    AWEzvRendezvousData	*oldrendezvous;			/* old rendezvous data for user */
    char		hbuf[NI_MAXHOST], sbuf[NI_MAXSERV]; /* buffers for hostname/service name */
    NSRange		range;				/* just a range... */
    NSString		*dnsname;			/* DNS name to lookup NULL */
    int			len;				/* record length */
    u_char		buf[PACKETSZ*10];		/* NULL record return */
    
    
    /* check that contact exists in dictionary */
    if ([contacts objectForKey:[contact uniqueID]] == nil) {
	AWEzvLog(@"Contact to update not in dictionary");
        return;
    }
    
    if ([contact rendezvous] != nil) {
	oldrendezvous = [contact rendezvous];
	/* check serials */
	if ([contact serial] > [contact serial]) {
	    AWEzvLog(@"Rendezvous update for %@ with lower serial, updating anyway", [contact uniqueID]);
            /* we'll update anyway, and hopefully we'll be back in sync with the network */
	}
    }
    [contact setRendezvous:rendezvousData];
	
    /* now we can update the contact */
    
    /* get the nickname */
    if ([rendezvousData getField:@"1st"] != nil)
	nick = [rendezvousData getField:@"1st"];
    if ([rendezvousData getField:@"last"] != nil)
	if (nick == nil) {
	    nick = [rendezvousData getField:@"last"];
	} else {
	    mutableNick = [[nick mutableCopy] autorelease];
	    [mutableNick appendString:@" "];
	    [mutableNick appendString:[rendezvousData getField:@"last"]];
	    nick = [[mutableNick copy] autorelease];
	}
    else
	if (nick == nil)
	    nick = @"Unnamed contact";
	
    [contact setName:nick];
    
    /* now get the status */
    if ([rendezvousData getField:@"status"] == nil) {
	[contact setStatus: AWEzvOnline];
    } else {
	if ([[rendezvousData getField:@"status"] compare:@"avail"] == 0)
	    [contact setStatus: AWEzvOnline];
	else if ([[rendezvousData getField:@"status"] compare:@"dnd"] == 0)
	    [contact setStatus: AWEzvAway];
	else if ([[rendezvousData getField:@"status"] compare:@"away"] == 0)
	    [contact setStatus: AWEzvIdle];
	else
	    [contact setStatus: AWEzvOnline];
    }
    
    /* Don't do this in Adium -- blocking call will freeze UI */
    #if 0
    dnsname = [NSString stringWithFormat:@"%@%s", [contact uniqueID], "._ichat._tcp.local."];
    len = res_query([dnsname UTF8String], C_IN, T_NULL, buf, PACKETSZ*10);
    if (len > 0) {
	NSPropertyListFormat    format;     /* plist format */
	NSString		*error;     /* error from conversion of plist */
	id			extracted;  /* extracted data from plist */
	NSData			*data;      /* DNS packet data */
	
	data = decode_dns(buf, len);
	if (data != nil) {	
	    format = NSPropertyListXMLFormat_v1_0;
	    extracted = [NSPropertyListSerialization
			    propertyListFromData: data
			    mutabilityOption:NSPropertyListImmutable
			    format:&format
			    errorDescription:&error];

	    /* check if there was an error in extraction */
	    if (extracted == nil) {
		AWEzvLog(@"Buddy icon: Unable to extract XML into plist");
	    } else {
	    
		/* make sure it's an NSData, or reponds to getBytes:range: */
		if (![extracted respondsToSelector:@selector(getBytes:range:)]) {
		    AWEzvLog(@"Buddy icon: Extracted object from XML is not an NSData");
		} else {
		    [contact setContactImage:[[[NSImage alloc] initWithData:extracted] autorelease]];
		}
	    }
	}
    }
    #endif
    
    /* now set the port */
    if ([rendezvousData getField:@"port.p2pj"] == nil) {
	AWEzvLog(@"Invalid rendezvous announcement for %@: no port specified", [contact uniqueID]);
	return;
    }
    [contact setPort:[[rendezvousData getField:@"port.p2pj"] intValue]];
    
    /* now set the ip address */
    if (getnameinfo(address, address->sa_len, hbuf, sizeof(hbuf), sbuf, sizeof(sbuf), NI_NUMERICHOST|NI_NUMERICSERV) != 0)
	AWEzvLog(@"Invalid sockaddr for Contact");
    
    ipAddr = [NSString stringWithCString:hbuf];
    range = [ipAddr rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    if (range.location == NSNotFound)
	[contact setIpaddr:ipAddr];
    
    /* and notify of new user */
    [[client client] userChangedState:contact];
}

#pragma mark Really Private Stuff
/* Don't touch stuff here unless you're the mach port callbacks below... */
- (NSString *)myname {
    return myname;
}


@end

#pragma mark Mach port callbacks
/* Mach port routines */
void handleMachMessage (CFMachPortRef port, void *msg, CFIndex size, void *info) {
    DNSServiceDiscovery_handleReply(msg);
}

void reg_reply (int errorCode, void *context) {
    AWEzvContactManager *self = context;

    if (errorCode != 0) {
	switch (errorCode) {
	    case kDNSServiceDiscoveryUnknownErr:
		[[[self client] client] reportError:@"Unknown error in Rendezvous Registration"
				        ofLevel:AWEzvError];
		break;
	    case kDNSServiceDiscoveryNameConflict:
		[[[self client] client] reportError:@"A user with your Rendezvous data is already online"
				        ofLevel:AWEzvError];
		break;
	    default:
		[[[self client] client] reportError:@"An internal error occurred"
				        ofLevel:AWEzvError];
		AWEzvLog(@"Internal error: rendezvous code %d", errorCode);
		break;
	}
	/* kill connections */
	[self disconnect];
    } else {
	/* notify that we're online */
	[self setConnected:YES];
    }
}

/* when we receive a reply to a browse request */
void browse_reply  (DNSServiceBrowserReplyResultType resultType,
		    const char *replyName,
		    const char *replyType,
		    const char *replyDomain,
		    DNSServiceDiscoveryReplyFlags flags,
		    void *context) {
    
    AWEzvContactManager *self = context;
    if ([[self myname] compare:[NSString stringWithCString:replyName]] != NSOrderedSame)
	[self browseResult:resultType name:replyName type:replyType domain:replyDomain flags:flags];
}

/* when we receive a reply to a resolve request */
void resolve_reply (struct sockaddr	*interface,
		    struct sockaddr	*address,
		    const char		*txtRecord,
		    DNSServiceDiscoveryReplyFlags flags,
		    void		*context) {
		    
    AWEzvContact	*contact = context;
    AWEzvContactManager *self = [contact manager];
    [self updateContact:contact withData:[[AWEzvRendezvousData alloc] initWithPlist:[NSString stringWithCString:txtRecord]] withAddress:address];
}
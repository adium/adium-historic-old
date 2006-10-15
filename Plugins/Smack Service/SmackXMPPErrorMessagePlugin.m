//
//  SmackXMPPErrorMessagePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPErrorMessagePlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"

#import "AIAdium.h"
#import "AIInterfaceController.h"
#import <AIUtilities/AIStringUtilities.h>

static struct
{
    int code;
    NSString *description;
} mapping[] =
{
    { 302, @"Redirect" },
    { 400, @"Bad Request" },
    { 401, @"Unauthorized" },
    { 402, @"Payment Required" },
    { 403, @"Forbidden" },
    { 404, @"Not Found" },
    { 405, @"Not Allowed" },
    { 406, @"Not Acceptable" },
    { 407, @"Registration Required" },
    { 408, @"Request Timeout " },
    { 409, @"Conflict" },
    { 500, @"Internal Server Error" },
    { 501, @"Not Implemented" },
    { 502, @"Remote Server Error" },
    { 503, @"Service Unavailable" },
    { 504, @"Remote Server Timeout" },
    { 000, nil }
};

@implementation SmackXMPPErrorMessagePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if ((self = [super init]))
    {
        account = a;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:account];
/*        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];*/
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

+ (NSString *)errorMessageForCode:(int)code
{
    NSString *errordesc = nil;
    unsigned i;
    
    for(i=0;mapping[i].code;i++)
    {
        if (mapping[i].code == code)
        {
            errordesc = mapping[i].description;
            break;
        }
    }
    if (!errordesc)
        errordesc = [[NSNumber numberWithInt:code] stringValue];
    
    return errordesc;
}

+ (void)handleXMPPErrorPacket:(SmackPacket *)packet service:(NSString *)service
{
    SmackXMPPError *error = [packet getError];
    NSString *from = [packet getFrom];
    if (!from)
        from = service;

    if (!error)
    {
        // pytransports seem to send error packets without an error tag
        
        if ([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.Message"])
            [[[AIObject sharedAdiumInstance] interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error From %@","XMPP Error From %@"), from] withDescription:[(SmackMessage *)packet getBody]];
        else
            [[[AIObject sharedAdiumInstance] interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error From %@","XMPP Error From %@"), from] withDescription:AILocalizedString(@"(no reason provided)","(no reason provided)")];
        
        return;
    }
    NSString *message = [error getMessage];
    int code = [error getCode];
    
    [[[AIObject sharedAdiumInstance] interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error %d \"%@\" From %@","XMPP Error %d \"%@\" From %@"), code, [self errorMessageForCode:code], from] withDescription:message?message:AILocalizedString(@"(no message provided)","(no message provided)")];
}

- (void)receivedPacket:(NSNotification*)n
{
    SmackPacket *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if ([[[(id)packet getType] toString] isEqualToString:@"error"])
        [self performSelectorOnMainThread:@selector(handleXMPPErrorPacketMainThread:) withObject:packet waitUntilDone:YES];
}

- (void)handleXMPPErrorPacketMainThread:(SmackPacket *)packet
{
    [[self class] handleXMPPErrorPacket:packet service:[[account connection] getServiceName]];
}

@end

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

- (id)initWithAccount:(SmackXMPPAccount*)account
{
    if((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)receivedPacket:(NSNotification*)n
{
    SmackPacket *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if([[[(id)packet getType] toString] isEqualToString:@"error"])
    {
        SmackXMPPError *error = [packet getError];
//        if(!error)
//            return; // invalid error packet, the error-info is required
        if(!error)
        {
            // pytransports seem to send error packets without an error tag
            
            if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.Message"])
                [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error From %@","XMPP Error From %@"), [packet getFrom]] withDescription:[(SmackMessage*)packet getBody]];
            else
                [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error From %@","XMPP Error From %@"), [packet getFrom]] withDescription:AILocalizedString(@"(no reason provided)","(no reason provided)")];

            return;
        }
        NSString *message = [error getMessage];
        int code = [error getCode];
        int i;
        NSString *errordesc = nil;
        
        if(code == 501 && [SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.IQ"]) // ignore "not implemented" iq errors, since they should be handled by the plugin that sent this request
            return;
        
        for(i=0;mapping[i].code;i++)
        {
            if(mapping[i].code == code)
            {
                errordesc = mapping[i].description;
                break;
            }
        }
        if(!errordesc)
            errordesc = [[NSNumber numberWithInt:code] stringValue];
        
        [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"XMPP Error %d \"%@\" From %@","XMPP Error %d \"%@\" From %@"), code, errordesc, [packet getFrom]] withDescription:message?message:AILocalizedString(@"(no message provided)","(no message provided)")];
    }
}

@end

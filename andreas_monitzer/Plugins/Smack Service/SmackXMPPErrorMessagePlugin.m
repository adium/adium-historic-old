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
                                                 selector:@selector(receivedMessagePacket:)
                                                     name:SmackXMPPMessagePacketReceivedNotification
                                                   object:account];
    }
    return self;
}

- (void)receivedMessagePacket:(NSNotification*)n
{
    SmackMessage *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if([[[packet getType] toString] isEqualToString:@"error"])
    {
        SmackXMPPError *error = [packet getError];
        if(!error)
            return; // invalid error packet, the error-info is required
        NSString *message = [error getMessage];
        int code = [error getCode];
        int i;
        NSString *errordesc = nil;
        
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

        [[NSAlert alertWithMessageText:[NSString stringWithFormat:AILocalizedString(@"XMPP Error %d \"%@\" From %@","XMPP Error %d \"%@\" From %@"), code, errordesc, [packet getFrom]]
                         defaultButton:AILocalizedString(@"OK","OK")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@",message?message:AILocalizedString(@"(no message provided)","(no message provided)")] runModal];
    }
}

@end

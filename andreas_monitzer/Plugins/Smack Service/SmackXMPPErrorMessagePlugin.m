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
        [[NSAlert alertWithMessageText:[NSString stringWithFormat:AILocalizedString(@"XMPP Error From %@","XMPP Error From %@"),[packet getFrom]]
                         defaultButton:AILocalizedString(@"OK","OK")
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@"%@",[packet getBody]] runModal];
}

@end

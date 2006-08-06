//
//  SmackXMPPHeadlineMessagePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-23.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPHeadlineMessagePlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"

#import <AIUtilities/AIStringUtilities.h>

@implementation SmackXMPPHeadlineMessagePlugin

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
    
    if([[[packet getType] toString] isEqualToString:@"headline"])
        NSLog(@"HEADLINE from %@: %@", [packet getFrom], [packet getBody]);
}
    
@end

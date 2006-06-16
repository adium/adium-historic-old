//
//  SmackXMPPRosterPlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-06-16.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPRosterPlugin.h"
#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"
#import "SmackListContact.h"

#import "AIAccount.h"

@implementation SmackXMPPRosterPlugin

- (id)initWithAccount:(SmackXMPPAccount*)account
{
    if((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPresencePacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

// presence handling
- (void)receivedPresencePacket:(NSNotification*)n {
    SmackXMPPAccount *account = [n object];
    SmackPresence *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    NSString *jidWithResource = [packet getFrom];
    NSString *type = [[packet getType] toString];
    NSString *status = [packet getStatus];
    NSString *mode = [[packet getMode] toString];
    int priority = [packet getPriority];
    
    AIListContact *listContact = [account contactWithJID:jidWithResource];
    
    SmackListContact *listEntry = (SmackListContact*)[account contactWithJID:[jidWithResource jidUserHost]];
    
    if(![listEntry containsObject:listContact])
        [listEntry addObject:listContact];
    
    AIStatusType statustype = AIOfflineStatusType;
    
    if([type isEqualToString:@"available"]) {
        if(!mode || [mode isEqualToString:@"available"] || [mode isEqualToString:@"chat"])
            statustype = AIAvailableStatusType;
        else if([mode isEqualToString:@"invisible"])
            statustype = AIInvisibleStatusType;
        else
            statustype = AIAwayStatusType;
    } else if([type isEqualToString:@"unavailable"])
        statustype = AIOfflineStatusType;
    else if([type isEqualToString:@"subscribe"]) {
        // ###
        return;
    } else if([type isEqualToString:@"subscribed"]) {
        // ###
        return;
    } else if([type isEqualToString:@"unsubscribe"]) {
        // ###
        return;
    } else if([type isEqualToString:@"unsubscribed"]) {
        // ###
        return;
    }
    
    //    NSLog(@"jid = \"%@\", mode = \"%@\", statustype = \"%d\"", jid, mode, statustype);
	[listContact setOnline:statustype != AIOfflineStatusType
                    notify:NotifyLater
                  silently:NO];
    
    [listContact setStatusObject:[NSNumber numberWithInt:priority] forKey:@"XMPPPriority" notify:NotifyLater];
    
    [listContact setStatusWithName:mode statusType:statustype notify:NotifyLater];
    if(status) {
        NSAttributedString *statusMessage = [[NSAttributedString alloc] initWithString:status attributes:nil];
        [listContact setStatusMessage:statusMessage notify:NotifyLater];
        [statusMessage release];
    } else
        [listContact setStatusMessage:nil notify:NotifyLater];
    
    //Apply the change
	[listContact notifyOfChangedStatusSilently:[account silentAndDelayed]];
    [listEntry notifyOfChangedStatusSilently:NO];
}

// roster handling
- (void)receivedIQPacket:(NSNotification*)n {
    SmackXMPPAccount *account = [n object];
    SmackIQ *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smack.packet.RosterPacket"]) {
        SmackRosterPacket *srp =(SmackRosterPacket*)packet;
        JavaIterator *iter = [srp getRosterItems];
        while([iter hasNext]) {
            SmackRosterPacketItem *srpi = [iter next];
            NSString *name = [srpi getName];
            NSString *jid = [srpi getUser];
            
            //            AIListContact *listContact = [self contactWithJID:jid];
            SmackListContact *listContact = [[SmackListContact alloc] initWithUID:jid account:account service:[account service]];
            NSLog(@"creating account for jid %@", jid);
            
            if(![[listContact formattedUID] isEqualToString:jid])
                [listContact setFormattedUID:jid notify:NotifyLater];
            
            // XMPP supports contacts that are in multiple groups, Adium does not.
            // First I'm checking if the group it's in here locally is one of the groups
            // the contact is in on the server. If this is not the case, I set the contact
            // to be in the first group on the list. XXX -> Adium folks, add this feature!
            JavaIterator *iter2 = [srpi getGroupNames];
            NSString *storedgroupname = [listContact remoteGroupName];
            if(storedgroupname) {
                while([iter2 hasNext]) {
                    NSString *groupname = [iter2 next];
                    if([storedgroupname isEqualToString:groupname])
                        break;
                }
                if(![iter2 hasNext])
                    storedgroupname = nil;
            }
            if(!storedgroupname) {
                iter2 = [srpi getGroupNames];
                if([iter2 hasNext])
                    [listContact setRemoteGroupName:[iter2 next]];
                else
                    [listContact setRemoteGroupName:@"nobody knows the trouble I've seen"];
            }
            [account setListContact:listContact toAlias:name];
            
            [account addListContact:listContact];
            
            [listContact release];
        }
    }
}


@end

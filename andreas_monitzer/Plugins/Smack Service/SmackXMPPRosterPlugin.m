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
#import "AIAdium.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"

#import <AIUtilities/AIStringUtilities.h>

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
    NSString *jid = [jidWithResource jidUserHost];
    NSString *type = [[packet getType] toString];
    NSString *status = [packet getStatus];
    NSString *mode = [[packet getMode] toString];
    int priority = [packet getPriority];
    
    AIListContact *listContact = [account contactWithJID:jidWithResource];
    
    SmackListContact *listEntry = (SmackListContact*)[account contactWithJID:[jidWithResource jidUserHost] create:NO];
    
    if(!listEntry)
        return; // ignore presence information for people not on our contact list
    
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
        [[adium contactController] showAuthorizationRequestWithDict:[NSDictionary dictionaryWithObjectsAndKeys:
            jid, @"Remote Name",
            nil] forAccount:account];
    
        return;
    } else if([type isEqualToString:@"subscribed"]) {
        [[adium interfaceController] displayQuestion:AILocalizedString(@"You Were Authorized!","You Were Authorized!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has authorized you to see his/her current status.","%@ has authorized you to see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice") defaultButton:AILocalizedString(@"OK","OK") alternateButton:nil otherButton:nil target:nil selector:NULL userInfo:nil];
        return;
    } else if([type isEqualToString:@"unsubscribe"]) {
        [[adium interfaceController] displayQuestion:AILocalizedString(@"Subscription Removed!","Subscription Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed you from his/her contact list. He/She will no longer see your current status.","%@ has removed you from his/her contact list. He/She will no longer see your current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice") defaultButton:AILocalizedString(@"OK","OK") alternateButton:nil otherButton:nil target:nil selector:NULL userInfo:nil];
        return;
    } else if([type isEqualToString:@"unsubscribed"]) {
        [[adium interfaceController] displayQuestion:AILocalizedString(@"Authorization Removed!","Authorization Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed your authorization. You will no longer see his/her current status.","%@ has removed your authorization. You will no longer see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice") defaultButton:AILocalizedString(@"OK","OK") alternateButton:nil otherButton:nil target:nil selector:NULL userInfo:nil];
        return;
    }
    
	[listContact setOnline:statustype != AIOfflineStatusType
                    notify:NotifyNow
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
            NSString *type = [[srpi getItemType] toString];
            
            NSLog(@"roster item subscription type = %@",type);
            
            if([type isEqualToString:@"remove"])
            {
                AIListContact *listContact = [account contactWithJID:jid];
                [account removeListContact:listContact];
                [listContact setContainingObject:nil];
            } else {
                //            AIListContact *listContact = [self contactWithJID:jid];
                SmackListContact *listContact = [[SmackListContact alloc] initWithUID:jid account:account service:[account service]];
                NSLog(@"creating account for jid %@", jid);
                
                if(![[listContact formattedUID] isEqualToString:jid])
                    [listContact setFormattedUID:jid notify:NotifyLater];
                
                [listContact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
                
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
}


@end

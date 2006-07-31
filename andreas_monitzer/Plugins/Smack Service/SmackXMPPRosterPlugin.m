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

#import <JavaVM/NSJavaVirtualMachine.h>

#import "AIAccount.h"
#import "AIAdium.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"

#import <AIUtilities/AIStringUtilities.h>

@interface SmackXMPPRosterPluginListener : NSObject {
}

@end

@interface SmackCocoaAdapter (rosterAdditions)

+ (SmackXMPPRosterPluginListener*)rosterPluginListenerWithDelegate:(id)delegate;

@end

@implementation SmackCocoaAdapter (rosterAdditions)

+ (SmackXMPPRosterPluginListener*)rosterPluginListenerWithDelegate:(id)delegate {
    return [[NSClassFromString(@"net.adium.smackBridge.SmackXMPPRosterPluginListener") newWithSignature:@"(Lcom/apple/cocoa/foundation/NSObject;)",delegate] autorelease];
}

@end

@implementation SmackXMPPRosterPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPresencePacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark Connection Setup

- (void)connected:(SmackXMPPConnection*)conn {
    listener = [[SmackCocoaAdapter rosterPluginListenerWithDelegate:self] retain];
    [[conn initializeRoster] addRosterListener:listener];

    // we're a tooltip plugin for displaying resources
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

- (void)disconnected:(SmackXMPPConnection*)conn {
    [[adium interfaceController] unregisterContactListTooltipEntry:self secondaryEntry:YES];
    [listener release];
}

#pragma mark Tooltip Handling

- (NSString *)labelForObject:(AIListObject *)inObject
{
    NSLog(@"label for object %@",inObject);
	if ([inObject isKindOfClass:[SmackListContact class]]) {
        if([(SmackListContact*)inObject preferredContact])
            return AILocalizedString(@"Resources",nil);
	}
	
    NSLog(@"nil return");
	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[SmackListContact class]])
        return [(SmackListContact*)inObject resourceInfo];
    return nil;
}

#pragma mark Callbacks from Java

- (void)setXMPPRosterEntriesAdded:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesAddedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesAddedMainThread:(JavaCollection*)addresses {
    SmackRoster *roster = [[account connection] getRoster];
    if(!roster)
        return;

    JavaIterator *iter = [addresses iterator];

    while([iter hasNext]) {
        NSString *jid = [iter next];
        SmackRosterEntry *entry = [roster getEntry:jid];
        NSString *type = [[entry getType] toString];
        
        NSLog(@"add entry %@",jid);
        
        SmackListContact *listContact = (SmackListContact*)[[adium contactController] contactWithService:[account service] account:account UID:jid class:[SmackListContact class]];
        
        if(![[listContact formattedUID] isEqualToString:jid])
            [listContact setFormattedUID:jid notify:NotifyLater];
        
        [listContact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
        
        // XMPP supports contacts that are in multiple groups, Adium does not.
        // First I'm checking if the group it's in here locally is one of the groups
        // the contact is in on the server. If this is not the case, I set the contact
        // to be in the first group on the list. XXX -> Adium folks, add this feature!
        JavaIterator *iter2 = [entry getGroups];
        NSString *storedgroupname = [listContact remoteGroupName];
        if(storedgroupname) {
            while([iter2 hasNext]) {
                SmackRosterGroup *group = [iter2 next];
                if([storedgroupname isEqualToString:[group getName]])
                    break;
            }
            if(![iter2 hasNext])
                storedgroupname = nil;
        }
        if(!storedgroupname) {
            iter2 = [entry getGroups];
            if([iter2 hasNext])
                [listContact setRemoteGroupName:[[iter2 next] getName]];
            else
                [listContact setRemoteGroupName:AILocalizedString(@"Unfiled Entries","group for entries without a group")];
        }
        [account setListContact:listContact toAlias:[entry getName]];
    }
}

- (void)setXMPPRosterEntriesUpdated:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesUpdatedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesUpdatedMainThread:(JavaCollection*)addresses {
    SmackRoster *roster = [[account connection] getRoster];
    if(!roster)
        return;
    
    JavaIterator *iter = [addresses iterator];
    
    while([iter hasNext]) {
        NSString *jid = [iter next];
        SmackRosterEntry *entry = [roster getEntry:jid];
        NSString *type = [[entry getType] toString];

        NSLog(@"update entry %@",jid);

        AIListContact *listContact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid];
        
        [listContact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
        
        // XMPP supports contacts that are in multiple groups, Adium does not.
        // First I'm checking if the group it's in here locally is one of the groups
        // the contact is in on the server. If this is not the case, I set the contact
        // to be in the first group on the list. XXX -> Adium folks, add this feature!
        JavaIterator *iter2 = [entry getGroups];
        NSString *storedgroupname = [listContact remoteGroupName];
        if(storedgroupname) {
            while([iter2 hasNext]) {
                SmackRosterGroup *group = [iter2 next];
                if([storedgroupname isEqualToString:[group getName]])
                    break;
            }
            if(![iter2 hasNext])
                storedgroupname = nil;
        }
        if(!storedgroupname) {
            iter2 = [entry getGroups];
            AIListGroup *group = [[adium contactController] groupWithUID:[iter2 hasNext]?[[iter2 next] getName]:AILocalizedString(@"Unfiled Entries","group for entries without a group")];
            [[adium contactController] addContacts:[NSArray arrayWithObject:listContact] toGroup:group];
        }
    }
}

- (void)setXMPPRosterEntriesDeleted:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesDeletedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesDeletedMainThread:(JavaCollection*)addresses {
    SmackRoster *roster = [[account connection] getRoster];
    if(!roster)
        return;
    
    JavaIterator *iter = [addresses iterator];
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    // convert list from jid-string array to AIListContact array
    while([iter hasNext]) {
        NSString *jid = [iter next];

        NSLog(@"delete entry %@",jid);

        AIListContact *listContact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid class:[SmackListContact class]];
        NSLog(@"%@,%d",listContact,[listContact retainCount]);
        if(listContact)
        {
            [contacts addObject:listContact];
//            [listContact setRemoteGroupName:nil];
        }
    }
    [[adium contactController] removeListObjects:contacts];
    [contacts release];
}

- (void)setXMPPRosterPresenceChanged:(NSString*)XMPPAddress {
    SmackRoster *roster = [[account connection] getRoster];
    SmackPresence *presence = [roster getPresenceResource:XMPPAddress]; // might be nil, but that's handled correctly by NSArray
    
    [self performSelectorOnMainThread:@selector(XMPPRosterPresenceChangedMainThread:) withObject:[NSArray arrayWithObjects:XMPPAddress,roster,presence,nil] waitUntilDone:YES];
}

- (void)XMPPRosterPresenceChangedMainThread:(NSArray*)params {
    NSString *XMPPAddress = [params objectAtIndex:0];
    
    SmackPresence *presence = nil;
    if([params count] > 2)
        presence = [params objectAtIndex:2];
    // otherwise the resource has gone offline
    // XXX to Smack: I want that offline-message! There's no way to retrieve that right now.
    
    NSString *jid = [XMPPAddress jidUserHost];
    NSString *type = [[presence getType] toString];
    NSString *status = [presence getStatus];
    NSString *mode = [[presence getMode] toString];
    int priority = [presence getPriority];

    SmackListContact *rosterContact = (SmackListContact*)[[adium contactController] existingContactWithService:[account service] account:account UID:jid];
    
    if(!rosterContact)
        return; // ignore presence information for people not on our contact list (might want to add that later for chats to people not on the contact list)

    AIListContact *resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:XMPPAddress];

    AIStatusType statustype = AIOfflineStatusType;
    
    if(!presence)
        statustype = AIOfflineStatusType;
    else if([type isEqualToString:@"available"]) {
        if(!mode || [mode isEqualToString:@"available"] || [mode isEqualToString:@"chat"])
            statustype = AIAvailableStatusType;
        else
            statustype = AIAwayStatusType;
    }
    
	if (statustype != AIOfflineStatusType) {
		if(![rosterContact containsObject:resourceObject])
			[rosterContact addObject:resourceObject];
	} else if([rosterContact containsObject:resourceObject])
			[rosterContact removeObject:resourceObject];
	
	[resourceObject setOnline:statustype != AIOfflineStatusType
                    notify:NotifyNow
                  silently:NO];
    [resourceObject setStatusObject:[NSNumber numberWithInt:priority] forKey:@"XMPPPriority" notify:NotifyNow];
    
    [resourceObject setStatusWithName:mode statusType:statustype notify:NotifyNow];
    if(status) {
        NSAttributedString *statusMessage = [[NSAttributedString alloc] initWithString:status attributes:nil];
        [resourceObject setStatusMessage:statusMessage notify:NotifyNow];
        [statusMessage release];
    } else
        [resourceObject setStatusMessage:nil notify:NotifyNow];
    
    //Apply the change
	[resourceObject notifyOfChangedStatusSilently:[account silentAndDelayed]];
    [rosterContact notifyOfChangedStatusSilently:NO];
}

// direct presence handling for authorization and offline status
- (void)receivedPresencePacket:(NSNotification*)n {
    [self performSelectorOnMainThread:@selector(receivedPresencePacketMainThread:) withObject:[[n userInfo] objectForKey:SmackXMPPPacket] waitUntilDone:YES];
}

- (void)receivedPresencePacketMainThread:(SmackPresence*)presence {
    NSString *jidWithResource = [presence getFrom];
    NSString *jid = [jidWithResource jidUserHost];
    NSString *type = [[presence getType] toString];
    NSString *status = [presence getStatus];
    
    if([type isEqualToString:@"unavailable"]) {
        // being unavailable is handled by -XMPPRosterPresenceChangedMainThread:, so we only set the status string here
        AIListContact *resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:jidWithResource];
        if(resourceObject) {
            if(status) {
                NSAttributedString *statusMessage = [[NSAttributedString alloc] initWithString:status attributes:nil];
                [resourceObject setStatusMessage:statusMessage notify:NotifyNow];
                [statusMessage release];
            } else
                [resourceObject setStatusMessage:nil notify:NotifyNow];
            
            //Apply the change
            [resourceObject notifyOfChangedStatusSilently:[account silentAndDelayed]];
        }
    } else if([type isEqualToString:@"subscribe"]) {
        [[adium contactController] showAuthorizationRequestWithDict:[NSDictionary dictionaryWithObjectsAndKeys:
            jid, @"Remote Name",
            nil] forAccount:account];
    } else if([type isEqualToString:@"subscribed"]) {
        [[adium interfaceController] handleMessage:AILocalizedString(@"You Were Authorized!","You Were Authorized!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has authorized you to see his/her current status.","%@ has authorized you to see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
    } else if([type isEqualToString:@"unsubscribe"]) {
        [[adium interfaceController] handleMessage:AILocalizedString(@"Subscription Removed!","Subscription Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed you from his/her contact list. He/She will no longer see your current status.","%@ has removed you from his/her contact list. He/She will no longer see your current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
    } else if([type isEqualToString:@"unsubscribed"]) {
        [[adium interfaceController] handleMessage:AILocalizedString(@"Authorization Removed!","Authorization Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed your authorization. You will no longer see his/her current status.","%@ has removed your authorization. You will no longer see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
    }
}

#pragma mark User-Initiated Roster Changes

- (void)requestAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"SUBSCRIBE"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

- (void)sendAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"SUBSCRIBED"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

- (void)removeAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"UNSUBSCRIBED"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

#pragma mark Context Menu for Entries

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    if(![inContact statusObjectForKey:@"XMPPSubscriptionType"])
        return nil; // not a contact from our contact list (might be groupchat)
    
    NSMutableArray *menuItems = [NSMutableArray array];

    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Request Authorization from","Request Authorization from") action:@selector(requestAuthorization:) keyEquivalent:@""];
    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Send Authorization to","Send Authorization to") action:@selector(sendAuthorization:) keyEquivalent:@""];
    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Remove Authorization from","Remove Authorization from") action:@selector(removeAuthorization:) keyEquivalent:@""];
    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

@end

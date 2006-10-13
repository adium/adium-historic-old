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

#import <Adium/AIAccount.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIInterfaceControllerProtocol.h>
#import <Adium/ESTextAndButtonsWindowController.h>

#import "SmackXMPPErrorMessagePlugin.h"

#import <AIUtilities/AIStringUtilities.h>

@interface SmackXMPPRosterPluginListener : NSObject {
}

@end

@interface SmackCocoaAdapter (rosterAdditions)
+ (SmackXMPPRosterPluginListener *)rosterPluginListenerWithDelegate:(id)delegate;
+ (SmackXDiscoverInfo*)discoverInfo;
+ (SmackRosterSubscriptionMode*)rosterSubscriptionModeWithName:(NSString *)mode;
@end

@implementation SmackCocoaAdapter (rosterAdditions)

+ (SmackXMPPRosterPluginListener*)rosterPluginListenerWithDelegate:(id)delegate {
    return [[[[self classLoader] loadClass:@"net.adium.smackBridge.SmackXMPPRosterPluginListener"] newWithSignature:@"(Lcom/apple/cocoa/foundation/NSObject;)",delegate] autorelease];
}

+ (SmackXDiscoverInfo*)discoverInfo
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"] alloc] init] autorelease];
}

+ (SmackRosterSubscriptionMode *)rosterSubscriptionModeWithName:(NSString *)mode
{
    return [(Class <SmackRosterSubscriptionMode>)[[self classLoader] loadClass:@"org.jivesoftware.smack.Roster$SubscriptionMode"] valueOf:mode];
}

@end

@interface SmackXMPPSubscriptionTypeTooltipPlugin : AIObject <AIContactListTooltipEntry> {
}
@end

@implementation SmackXMPPSubscriptionTypeTooltipPlugin

- (id)init
{
    if ((self = [super init])) {
        [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
    }

    return self;
}

- (void)dealloc
{
    [[adium interfaceController] unregisterContactListTooltipEntry:self secondaryEntry:YES];
	
    [super dealloc];
}

- (NSString *)labelForObject:(AIListObject *)inObject
{
    return AILocalizedString(@"Subscription Type","tooltip entry title");
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
    NSString *type = [inObject statusObjectForKey:@"XMPPSubscriptionType"];
    if (type)
    {
        // this may seem weird, but it's required for localization
        if ([type isEqualToString:@"none"])
            type = AILocalizedString(@"None","subscription type");
        else if ([type isEqualToString:@"both"])
            type = AILocalizedString(@"Both","subscription type");
        else if ([type isEqualToString:@"from"])
            type = AILocalizedString(@"From","subscription type");
        else if ([type isEqualToString:@"to"])
            type = AILocalizedString(@"To","subscription type");

        return [[[NSAttributedString alloc] initWithString:type] autorelease];
    }
    return nil;
}

@end

static SmackXMPPSubscriptionTypeTooltipPlugin *subscriptiontypeplugin = nil;

@interface SmackXMPPRosterPlugin (PRIVATE)
- (void)updateToSubscriptionMode:(int)subscriptionMode;
@end

@implementation SmackXMPPRosterPlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if ((self = [super init]))
    {
        account = a;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedPresencePacket:)
                                                     name:SmackXMPPPresencePacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateSubscriptionMode:)
                                                     name:@"SmackXMPPAccountSubscriptionModeUpdated"
                                                   object:account];
        services = [[NSMutableArray alloc] init];
        if (!subscriptiontypeplugin)
            subscriptiontypeplugin = [[SmackXMPPSubscriptionTypeTooltipPlugin alloc] init];
        else
            [subscriptiontypeplugin retain];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [services release];
    [subscriptiontypeplugin release];
    [super dealloc];
}

#pragma mark Connection Setup

- (void)connected:(SmackXMPPConnection*)conn {
    listener = [[SmackCocoaAdapter rosterPluginListenerWithDelegate:self] retain];
    roster = [[conn initializeRoster] retain];
    [roster addRosterListener:listener];

    //XXX should register a default instead of falling through like this
	NSNumber *subscriptionMode = [account preferenceForKey:@"subscriptions" group:GROUP_ACCOUNT_STATUS];
	[self updateToSubscriptionMode:(subscriptionMode ? [subscriptionMode intValue] : 0)];
	
    //We're a tooltip plugin for displaying resources
    [[adium interfaceController] registerContactListTooltipEntry:self secondaryEntry:YES];
}

- (void)disconnected:(SmackXMPPConnection*)conn {
    [[adium interfaceController] unregisterContactListTooltipEntry:self secondaryEntry:YES];
    [listener release];
    [roster release]; roster = nil;
}

- (void)updateToSubscriptionMode:(int)subscriptionMode
{
	NSString *mode;

	switch (subscriptionMode) {
        case 1:
            mode = @"accept_all";
            break;
        case 2:
            mode = @"reject_all";
            break;
        case 0:
        default:
            mode = @"manual";
    }
    
    [roster setSubscriptionMode:[SmackCocoaAdapter rosterSubscriptionModeWithName:mode]];	
}

- (void)updateSubscriptionMode:(NSNotification*)notification
{
	[self updateToSubscriptionMode:[[[notification userInfo] objectForKey:@"mode"] intValue]];
}

#pragma mark Tooltip Handling

- (NSString *)labelForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[SmackListContact class]] && [(SmackListContact*)inObject account] == account) {
        AIListContact *contact = [(SmackListContact*)inObject preferredContact];
        if (contact && [[[contact UID] jidResource] length] > 0)
            return AILocalizedString(@"Resources",nil);
	}
	return nil;
}

- (NSAttributedString *)entryForObject:(AIListObject *)inObject
{
	if ([inObject isKindOfClass:[SmackListContact class]] && [(SmackListContact*)inObject account] == account)
        return [(SmackListContact*)inObject resourceInfo];
    return nil;
}

#pragma mark Callbacks from Java

- (void)setXMPPRosterEntriesAdded:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesAddedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesAddedMainThread:(JavaCollection*)addresses {
    JavaIterator *iter = [addresses iterator];
    BOOL servicechange = NO;

    while([iter hasNext]) {
        NSString *jid = [iter next];
        SmackRosterEntry *entry = [roster getEntry:jid];
        NSString *type = [[entry getType] toString];
        
        // we assume that everything that doesn't contain an '@' is a service (gateway)
        // this is not really a valid assumption, but stpeter confirmed that there's no
        // "proper" way to handle that for services that are offline (and thus don't
        // respond to disco#info).
        if ([jid rangeOfString:@"@"].location == NSNotFound)
        {
            AIListContact *contact = [[adium contactController] contactWithService:[account service] account:account UID:jid];
            [contact setDisplayName:[entry getName]];
            
            [contact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
            
            [services addObject:contact];
            servicechange = YES;
        } else {
            SmackListContact *listContact = (SmackListContact*)[[adium contactController] contactWithService:[account service] account:account UID:jid usingClass:[SmackListContact class]];
            
            if (![[listContact formattedUID] isEqualToString:jid])
                [listContact setFormattedUID:jid notify:NotifyLater];
            
            [listContact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
            
            // XMPP supports contacts that are in multiple groups, Adium does not.
            // First I'm checking if the group it's in here locally is one of the groups
            // the contact is in on the server. If this is not the case, I set the contact
            // to be in the first group on the list. XXX -> Adium folks, add this feature!
            JavaIterator *iter2;
            NSString *storedgroupname = [listContact remoteGroupName];
            if (storedgroupname) {
                iter2 = [[entry getGroups] iterator];
                while([iter2 hasNext]) {
                    SmackRosterGroup *group = [iter2 next];
                    if ([storedgroupname isEqualToString:[group getName]])
                        break;
                }
                if (![iter2 hasNext])
                    storedgroupname = nil;
            }
            if (!storedgroupname) {
                iter2 = [[entry getGroups] iterator];
                if ([iter2 hasNext])
                    [listContact setRemoteGroupName:[[iter2 next] getName]];
                else
                    [listContact setRemoteGroupName:AILocalizedString(@"Unfiled Entries","group for entries without a group")];
            }
            [account setListContact:listContact toAlias:[entry getName]];
        }
    }
    if (servicechange)
        // reload accounts menu
        [[adium notificationCenter] postNotificationName:Account_ListChanged
                                                  object:nil
                                                userInfo:nil];
}

- (void)setXMPPRosterEntriesUpdated:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesUpdatedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesUpdatedMainThread:(JavaCollection*)addresses {
    JavaIterator *iter = [addresses iterator];
    BOOL servicechange = NO;
    
    while([iter hasNext]) {
        NSString *jid = [iter next];
        SmackRosterEntry *entry = [roster getEntry:jid];
        NSString *type = [[entry getType] toString];
        
        if ([jid rangeOfString:@"@"].location == NSNotFound)
        {
            // it's a service!
            AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid];
            
            // we ignore the group, so only the name or the subscription type could have changed
            [contact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];

            [contact setDisplayName:[entry getName]];
            servicechange = YES;
        } else {
            AIListContact *listContact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid];
            
            [listContact setStatusObject:type forKey:@"XMPPSubscriptionType" notify:NotifyLater];
            
            // XMPP supports contacts that are in multiple groups, Adium does not.
            // First I'm checking if the group it's in here locally is one of the groups
            // the contact is in on the server. If this is not the case, I set the contact
            // to be in the first group on the list. XXX -> Adium folks, add this feature!
            JavaIterator *iter2 = [[entry getGroups] iterator];
            NSString *storedgroupname = [listContact remoteGroupName];
            if (storedgroupname) {
                while([iter2 hasNext]) {
                    SmackRosterGroup *group = [iter2 next];
                    if ([storedgroupname isEqualToString:[group getName]])
                        break;
                }
                if (![iter2 hasNext])
                    storedgroupname = nil;
            }
            if (!storedgroupname) {
                iter2 = [[entry getGroups] iterator];
                AIListGroup *group = [[adium contactController] groupWithUID:[iter2 hasNext]?[[iter2 next] getName]:AILocalizedString(@"Unfiled Entries","group for entries without a group")];
                [[adium contactController] addContacts:[NSArray arrayWithObject:listContact] toGroup:group];
            }
        }
    }
    if (servicechange)
        // reload accounts menu
        [[adium notificationCenter] postNotificationName:Account_ListChanged
                                                  object:nil
                                                userInfo:nil];
}

- (void)setXMPPRosterEntriesDeleted:(JavaCollection*)addresses {
    [self performSelectorOnMainThread:@selector(XMPPRosterEntriesDeletedMainThread:) withObject:addresses waitUntilDone:YES];
}

- (void)XMPPRosterEntriesDeletedMainThread:(JavaCollection*)addresses {
    JavaIterator *iter = [addresses iterator];
    BOOL servicechange = NO;
    
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    
    // convert list from jid-string array to AIListContact array
    while([iter hasNext]) {
        NSString *jid = [iter next];
        
        if ([jid rangeOfString:@"@"].location == NSNotFound) {
            //It's a service!
            AIListContact *contact;
            
            if ((contact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid])) {
                [services removeObject:contact];
			}

            servicechange = YES;

        } else {
            AIListContact *listContact = [[adium contactController] existingContactWithService:[account service]
																					   account:account
																						   UID:jid
																					usingClass:[SmackListContact class]];
            if (listContact) {
                [contacts addObject:listContact];
                //[listContact setRemoteGroupName:nil];
            }
        }
    }

#warning Does this not lead to some sort of recursivity? removeListObjects: is normally triggerred by user action and calls back on the account to remove them serverside...
    [[adium contactController] removeListObjects:contacts];
    [contacts release];

    if (servicechange) {
        //Reload accounts menu
		//XXX Why? -evands
        [[adium notificationCenter] postNotificationName:Account_ListChanged
                                                  object:nil
                                                userInfo:nil];
	}
}

- (void)setXMPPRosterPresenceChanged:(NSString *)XMPPAddress {
    SmackPresence *presence = [roster getPresenceResource:XMPPAddress]; // might be nil, but that's handled correctly by NSArray
    
    [self performSelectorOnMainThread:@selector(XMPPRosterPresenceChangedMainThread:) withObject:[NSArray arrayWithObjects:XMPPAddress,roster,presence,nil] waitUntilDone:YES];
}

- (void)XMPPRosterPresenceChangedMainThread:(NSArray*)params {
    NSString *XMPPAddress = [params objectAtIndex:0];
    
    SmackPresence *presence = nil;
    if ([params count] > 2)
        presence = [params objectAtIndex:2];
    // otherwise the resource has gone offline
    // XXX to Smack: I want that offline-message! There's no way to retrieve that right now.
    
    NSString *jid = [XMPPAddress jidUserHost];
    NSString *type = [[presence getType] toString];
    NSString *status = [presence getStatus];
    NSString *mode = [[presence getMode] toString];
    int priority = [presence getPriority];

    SmackListContact *rosterContact = (SmackListContact*)[[adium contactController] existingContactWithService:[account service] account:account UID:jid];
    
    NSMenuItem *mitem = [rosterContact statusObjectForKey:@"XMPPMenuItem"];
    if (mitem)
    {
        // this contact is in some menu and not the contact list
        // this means that we only need the online/offline status
        // plus we have to update the menu item's image
        
        if (presence == NULL)
            [rosterContact setOnline:NO
                              notify:NotifyNow
                            silently:NO];
        else {
            [rosterContact setStatusWithName:mode statusType:([mode isEqualToString:@"available"] || [mode isEqualToString:@"chat"])?AIAvailableStatusType:AIAwayStatusType
                                      notify:NotifyNow];

            [rosterContact setOnline:YES
                              notify:NotifyNow
                            silently:NO];
        }
        
        [mitem setImage:[rosterContact displayArrayObjectForKey:@"Tab Status Icon"]];
        [[adium notificationCenter] postNotificationName:Account_ListChanged
                                                  object:nil
                                                userInfo:nil];
        return;
    }
    
    if (!rosterContact || ![rosterContact isKindOfClass:[SmackListContact class]])
        return; // ignore presence information for people not on our contact list (might want to add that later for chats to people not on the contact list)

    AIListContact *resourceObject;
    
    if ([jid isEqualToString:XMPPAddress])
        resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:[XMPPAddress stringByAppendingString:@"/"]];
    else
        resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:XMPPAddress];

    AIStatusType statustype = AIOfflineStatusType;
    
    if (!presence)
        statustype = AIOfflineStatusType;
    else if ([type isEqualToString:@"available"]) {
        if (!mode || [mode isEqualToString:@"available"] || [mode isEqualToString:@"chat"])
            statustype = AIAvailableStatusType;
        else
            statustype = AIAwayStatusType;
    }
    
	if (statustype != AIOfflineStatusType) {
		if (![rosterContact containsObject:resourceObject])
			[rosterContact addObject:resourceObject];
        
        if (![[resourceObject statusObjectForKey:@"Online"] boolValue])
        {
            // this resource has gone online right now, let's ask it for disco#info
            SmackXDiscoverInfo *dinfo = [SmackCocoaAdapter discoverInfo];
            [dinfo setTo:XMPPAddress];
            [[account connection] sendPacket:dinfo];
        }
	} else if ([rosterContact containsObject:resourceObject])
			[rosterContact removeObject:resourceObject];
	
    
	[resourceObject setOnline:statustype != AIOfflineStatusType
                    notify:NotifyNow
                  silently:NO];
    [resourceObject setStatusObject:[NSNumber numberWithInt:priority] forKey:@"XMPPPriority" notify:NotifyNow];
    
    [resourceObject setStatusWithName:mode statusType:statustype notify:NotifyNow];
    if (status) {
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

- (void)receivedPresencePacketMainThread:(SmackPresence *)presence {
    NSString *jidWithResource = [presence getFrom];
    NSString *jid = [jidWithResource jidUserHost];
    NSString *type = [[presence getType] toString];
    NSString *status = [presence getStatus];
    
    if ([type isEqualToString:@"unavailable"]) {
        // being unavailable is handled by -XMPPRosterPresenceChangedMainThread:, so we only set the status string here
        AIListContact *resourceObject;
        if ([jidWithResource isEqualToString:jid])
            resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:[jidWithResource stringByAppendingString:@"/"]];
        else
            resourceObject = [[adium contactController] contactWithService:[account service] account:account UID:jidWithResource];
        if (resourceObject) {
            if (status) {
                NSAttributedString *statusMessage = [[NSAttributedString alloc] initWithString:status attributes:nil];
                [resourceObject setStatusMessage:statusMessage notify:NotifyNow];
                [statusMessage release];
            } else
                [resourceObject setStatusMessage:nil notify:NotifyNow];
            
            //Apply the change
            [resourceObject notifyOfChangedStatusSilently:[account silentAndDelayed]];
        }
    } else if ([type isEqualToString:@"error"]) {
        AIListContact *contact = [[adium contactController] existingContactWithService:[account service] account:account UID:jid];
        if (contact) // only handle contacts we actually know
        {
            SmackXMPPError *error = [presence getError];
            if (error)
            {
                int code = [error getCode];
                [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Error for contact %@","presence type error"),jid]
                                             withDescription:[NSString stringWithFormat:AILocalizedString(@"Received the error %d (%@). Do you want to remove this contact from your contact list?",""),code,[SmackXMPPErrorMessagePlugin errorMessageForCode:code]]
                                                                        withWindowTitle:AILocalizedString(@"Error","Alert pane title")
                                                                          defaultButton:AILocalizedString(@"Remove","Remove")
                                                                        alternateButton:AILocalizedString(@"Ignore","Ignore this alert")
                                                                            otherButton:nil
                                                                                 target:self
                                                                               selector:@selector(removeContactAfterError:contact:)
                                                                               userInfo:contact];
            }
        }
    } else if ([[account preferenceForKey:@"subscriptions" group:GROUP_ACCOUNT_STATUS] intValue] == 0)
    {
        // we only care about the packets if the subscription is set to ask user
        if ([type isEqualToString:@"subscribe"]) {
            [[adium contactController] showAuthorizationRequestWithDict:[NSDictionary dictionaryWithObjectsAndKeys:
                jid, @"Remote Name",
                nil] forAccount:account];
        } else if ([type isEqualToString:@"subscribed"]) {
            [[adium interfaceController] handleMessage:AILocalizedString(@"You Were Authorized!","You Were Authorized!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has authorized you to see his/her current status.","%@ has authorized you to see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
        } else if ([type isEqualToString:@"unsubscribe"]) {
            [[adium interfaceController] handleMessage:AILocalizedString(@"Subscription Removed!","Subscription Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed you from his/her contact list. He/She will no longer see your current status.","%@ has removed you from his/her contact list. He/She will no longer see your current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
        } else if ([type isEqualToString:@"unsubscribed"]) {
            [[adium interfaceController] handleMessage:AILocalizedString(@"Authorization Removed!","Authorization Removed!") withDescription:[NSString stringWithFormat:AILocalizedString(@"%@ has removed your authorization. You will no longer see his/her current status.","%@ has removed your authorization. You will no longer see his/her current status."),jid] withWindowTitle:AILocalizedString(@"Notice","Notice")];
        }
    }
}

- (void)removeContactAfterError:(NSNumber*)resultCode contact:(AIListContact*)contact
{
    if ([resultCode intValue] == AITextAndButtonsDefaultReturn)
    {
        [[adium contactController] removeListObjects:[NSArray arrayWithObject:contact]];
//        [account removeContacts:[NSArray arrayWithObject:contact]];
    }
}

- (void)receivedIQPacket:(NSNotification*)n {
    SmackIQ *packet = [[n userInfo] objectForKey:SmackXMPPPacket];
    
    if ([SmackCocoaAdapter object:packet isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"])
        [self performSelectorOnMainThread:@selector(receivedIQPacketMainThread:) withObject:packet waitUntilDone:YES];
}

- (void)receivedIQPacketMainThread:(SmackXDiscoverInfo*)dinfo {
    JavaIterator *iter = [dinfo getIdentities];
    
    AIListContact *resourceObject = [[adium contactController] existingContactWithService:[account service] account:account UID:[dinfo getFrom]];
    
    if (!resourceObject)
        return; // unknown object, ignore
    
    while([iter hasNext])
    {
        SmackXDiscoverInfoIdentity *identity = [iter next];
        if ([[identity getCategory] isEqualToString:@"client"] && ([[identity getType] isEqualToString:@"handheld"] || [[identity getType] isEqualToString:@"phone"]))
        {
            [resourceObject setIsMobile:YES notify:NotifyLater];
            break;
        }
    }
    [resourceObject setStatusObject:dinfo forKey:@"XMPP:disco#info" notify:NotifyLater];
    [resourceObject notifyOfChangedStatusSilently:NO];
}

#pragma mark User-Initiated Roster Changes

- (void)requestAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"subscribe"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

- (void)sendAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"subscribed"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

- (void)removeAuthorization:(NSMenuItem*)sender {
    SmackPresence *packet = [SmackCocoaAdapter presenceWithTypeString:@"unsubscribed"];
    [packet setTo:[[sender representedObject] UID]];
    
    [[account connection] sendPacket:packet];
}

#pragma mark Menu entries for services

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    NSEnumerator *e = [services objectEnumerator];
    AIListContact *service;
    
    while((service = [e nextObject]))
    {
        // cache in list contact
        NSMenuItem *mitem = [service statusObjectForKey:@"XMPPMenuItem"];
        if (!mitem)
        {
            mitem = [[NSMenuItem alloc] initWithTitle:[service displayName] action:nil keyEquivalent:@""];
            NSMenu *submenu = [[NSMenu alloc] initWithTitle:[service displayName]];
            
            NSEnumerator *e2 = [[account menuItemsForContact:service] objectEnumerator];
            NSMenuItem *subitem;
            
            while((subitem = [e2 nextObject]))
                [submenu addItem:subitem];
            
            [mitem setSubmenu:submenu];
            [submenu release];
            [mitem setImage:[service displayArrayObjectForKey:@"Tab Status Icon"]];

            [service setStatusObject:mitem forKey:@"XMPPMenuItem" notify:NotifyLater];
            [mitem autorelease];
        }
        
        [menuItems addObject:mitem];
    }
    
    return menuItems;
}

#pragma mark Context Menu for Entries

- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    if (![inContact statusObjectForKey:@"XMPPSubscriptionType"])
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

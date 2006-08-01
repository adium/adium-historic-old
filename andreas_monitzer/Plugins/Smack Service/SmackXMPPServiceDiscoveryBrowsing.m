//
//  SmackXMPPServiceDiscoveryBrowsing.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPServiceDiscoveryBrowsing.h"
#import "SmackXMPPMultiUserChatPlugin.h"

#import "AIAccount.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIInterfaceController.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import <Adium/DCJoinChatWindowController.h>

#import "SmackXMPPRegistration.h"

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"

@interface SmackCocoaAdapter (serviceDiscoveryBrowsingAdditions)

+ (SmackXDiscoverItems*)discoverItems;
+ (SmackXDiscoverInfo*)discoverInfo;

@end

@implementation SmackCocoaAdapter (serviceDiscoveryBrowsingAdditions)

+ (SmackXDiscoverItems*)discoverItems
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.DiscoverItems"] alloc] init] autorelease];
}

+ (SmackXDiscoverInfo*)discoverInfo
{
    return [[[[[self classLoader] loadClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"] alloc] init] autorelease];
}

@end

// one instance for every discovery browser window
@interface SmackXMPPServiceDiscoveryBrowserController : AIObject
{
    SmackXMPPAccount *account;

    IBOutlet NSWindow *window;
    IBOutlet NSTextField *servicename;
    IBOutlet NSTextField *nodename;
    IBOutlet NSOutlineView *outlineview;
    IBOutlet NSProgressIndicator *progressindicator;
    
    NSString *service;
    NSString *node;
    
    NSMutableDictionary *discoveredItems;    // key = NSValue of unretained SmackXDiscoverItem (or [NSNull null] for root), value = NSArray of DiscoverItem
    NSMutableDictionary *discoveredItemInfo; // key = NSValue of unretained SmackXDiscoverItem (or [NSNull null] for root), value = DiscoverItemInfo

    NSMutableDictionary *packetRequest;
}

- (id)initWithAccount:(SmackXMPPAccount*)a serviceName:(NSString*)s;

- (IBAction)changeServiceName:(id)sender;
- (IBAction)openService:(id)sender;

- (void)queryItemInfo:(SmackXDiscoverItem*)item;
- (void)queryItemsForItem:(SmackXDiscoverItem*)item;

@end

@implementation SmackXMPPServiceDiscoveryBrowserController

- (id)initWithAccount:(SmackXMPPAccount*)a serviceName:(NSString*)s
{
    if((self = [super init]))
    {
        account = a;
        [NSBundle loadNibNamed:@"SmackXMPPServiceDiscoveryBrowser" owner:self];
        if(!window) {
            NSLog(@"error loading SmackXMPPServiceDiscoveryBrowser.nib!");
            [self release];
            return nil;
        }
        [progressindicator setUsesThreadedAnimation:YES];
        
        [servicename setStringValue:service = [s copy]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        
        discoveredItems = [[NSMutableDictionary alloc] init];
        discoveredItemInfo = [[NSMutableDictionary alloc] init];
        packetRequest = [[NSMutableDictionary alloc] init];
        
        [self queryItemsForItem:(SmackXDiscoverItem*)[NSNull null]];
        [window makeKeyAndOrderFront:nil];

        [self retain];
        [outlineview setTarget:self];
        [outlineview setDoubleAction:@selector(openService:)];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [service release];
    [discoveredItems release];
    [discoveredItemInfo release];
    [packetRequest release];
    [super dealloc];
}

- (IBAction)openService:(id)sender
{
    int row = [outlineview clickedRow];
    if(row != -1)
    {
        SmackXDiscoverItem *item = [outlineview itemAtRow:row];
        
        SmackXDiscoverInfo *info = [discoveredItemInfo objectForKey:[NSValue valueWithNonretainedObject:item]];
        if(!info)
        {
            // this shouldn't happen, as we don't allow double-clicking items without info
            NSBeep();
            return;
        }
        
        // now we have to guess what to do on double-click
        // this is good place for adding features!
        
        JavaIterator *iter = [info getIdentities];
        
        while([iter hasNext])
        {
            SmackXDiscoverInfoIdentity *ident = [iter next];
            NSString *category = [ident getCategory];
            // NSString *type = [ident getType];
            
            if([category isEqualToString:@"conference"])
            {
                DCJoinChatWindowController *jcwc = [DCJoinChatWindowController joinChatWindow];
                [jcwc configureForAccount:account];
                
                [(SmackXMPPJoinChatViewController*)[jcwc joinChatViewController] setJID:[info getFrom]];
            } else if([category isEqualToString:@"gateway"])
            {
                [[[SmackXMPPRegistration alloc] initWithAccount:account registerWith:[info getFrom]] autorelease];
            } else if([category isEqualToString:@"pubsub"])
            {
            } else {
                // just open a chat with that service, it might actually do something useful :)
                // better than doing nothing at least
                
                AIChat *chat = [[adium chatController] chatWithContact:[[adium contactController] contactWithService:[account service] account:account UID:[info getFrom]]];
                [chat setDisplayName:[ident getName]];
                
                [[adium interfaceController] openChat:chat];
            }
        }
    }
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self release];
}

- (IBAction)changeServiceName:(id)sender
{
    id old = service;
    service = [[servicename stringValue] copy];
    [old release];
    old = node;
    if([[nodename stringValue] length] > 0)
        node = [[nodename stringValue] copy];
    else
        node = nil;
    [old release];
    
    [discoveredItems removeAllObjects];
    [discoveredItemInfo removeAllObjects];
    [packetRequest removeAllObjects];
    
    [self queryItemsForItem:(id)[NSNull null]];
}

- (void)queryItemInfo:(SmackXDiscoverItem*)item
{
    SmackXDiscoverInfo *packet = [SmackCocoaAdapter discoverInfo];
    [packet setTo:((id)item!=(id)[NSNull null])?[item getEntityID]:service];
    NSString *querynode = ((id)item!=(id)[NSNull null])?[item getNode]:node;
    if(querynode)
        [packet setNode:querynode];
    
    [packetRequest setObject:item forKey:[packet getPacketID]];
    
    [[account connection] sendPacket:packet];
    
    [progressindicator startAnimation:nil];
}

- (void)queryItemsForItem:(SmackXDiscoverItem*)item
{
    SmackXDiscoverItems *packet = [SmackCocoaAdapter discoverItems];
    [packet setTo:((id)item!=(id)[NSNull null])?[item getEntityID]:service];
    NSString *querynode = ((id)item!=(id)[NSNull null])?[item getNode]:node;
    if(querynode)
        [packet setNode:querynode];
    
    [packetRequest setObject:item forKey:[packet getPacketID]];
    
    [[account connection] sendPacket:packet];

    [progressindicator startAnimation:nil];
}

- (void)receivedIQPacket:(NSNotification*)n
{
    SmackIQ *iq = [[n userInfo] objectForKey:SmackXMPPPacket];
    if([SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverItems"])
    {
        SmackXDiscoverItem *baseitem = [packetRequest objectForKey:[iq getPacketID]];
        if(!baseitem)
            return; // we didn't request that node

        SmackXDiscoverItems *items = (SmackXDiscoverItems *)iq;
        NSMutableArray *itemarray = [[NSMutableArray alloc] init];
        JavaIterator *iter = [items getItems];
        
        while([iter hasNext])
        {
            SmackXDiscoverItem *item = [iter next];
            [itemarray addObject:item];

            [self queryItemInfo:item];
        }
        
        [discoveredItems setObject:itemarray forKey:((id)baseitem!=(id)[NSNull null])?(id)[NSValue valueWithNonretainedObject:baseitem]:(id)[NSNull null]];
        [itemarray release];
        
        [packetRequest removeObjectForKey:[iq getPacketID]];
    } else if([SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverInfo"])
    {
        SmackXDiscoverItem *baseitem = [packetRequest objectForKey:[iq getPacketID]];
        if(!baseitem)
            return; // we didn't request that node
        
        SmackXDiscoverInfo *info = (SmackXDiscoverInfo*)iq;
        
        [discoveredItemInfo setObject:info forKey:((id)baseitem!=(id)[NSNull null])?(id)[NSValue valueWithNonretainedObject:baseitem]:(id)[NSNull null]];
        
        [packetRequest removeObjectForKey:[iq getPacketID]];
    } else
        return; // nothing we should care about
    
    [outlineview reloadData];
    
    if([packetRequest count] == 0)
        [progressindicator performSelectorOnMainThread:@selector(stopAnimation:) withObject:nil waitUntilDone:YES];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    return [[discoveredItems objectForKey:item?(id)[NSValue valueWithNonretainedObject:item]:(id)[NSNull null]] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    SmackXDiscoverInfo *info = [discoveredItemInfo objectForKey:[NSValue valueWithNonretainedObject:item]];
    if(!info)
        return NO;
    return [info containsFeature:@"http://jabber.org/protocol/disco#items"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    // we only allow selecting items where we have the item info
    SmackXDiscoverInfo *info = [discoveredItemInfo objectForKey:[NSValue valueWithNonretainedObject:item]];
    return info != nil;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    NSArray *items = [discoveredItems objectForKey:item?(id)[NSValue valueWithNonretainedObject:item]:(id)[NSNull null]];
    return [items count];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    SmackXDiscoverItem *item = [[notification userInfo] objectForKey:@"NSObject"];
    [self queryItemsForItem:item];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    SmackXDiscoverInfo *info = [discoveredItemInfo objectForKey:[NSValue valueWithNonretainedObject:item]];
    
    NSDictionary *style = [NSDictionary dictionaryWithObject:info?[NSColor blackColor]:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
    
    NSString *identifier = [tableColumn identifier];
    if([identifier isEqualToString:@"name"])
    {
        // there are two names: the one we got while getting the items list, and the one we got from
        // the info discovery. We try to pick the latter if it exists, otherwise the former.
        // It should be the same for all identities, so we just pick the first one.
        if(!info)
            return [[[NSAttributedString alloc] initWithString:[item getName] attributes:style] autorelease];
        JavaIterator *iter = [info getIdentities];
        if([iter hasNext])
            return [[[NSAttributedString alloc] initWithString:[[iter next] getName] attributes:style] autorelease];
        return [item getName];
    } else if([identifier isEqualToString:@"jid"])
        return [[[NSAttributedString alloc] initWithString:[item getEntityID] attributes:style] autorelease];
    else if([identifier isEqualToString:@"node"])
        return [[[NSAttributedString alloc] initWithString:[item getNode]?[item getNode]:@"" attributes:style] autorelease];
    else if([identifier isEqualToString:@"category"])
    {
        if(!info)
            return [[[NSAttributedString alloc] initWithString:@"N/A" attributes:style] autorelease];
        else
        {
            JavaIterator *iter = [info getIdentities];
            NSMutableArray *identities = [[NSMutableArray alloc] init];
            
            while([iter hasNext])
            {
                SmackXDiscoverInfoIdentity *ident = [iter next];
                [identities addObject:[NSString stringWithFormat:@"%@ (%@)",[ident getCategory],[ident getType]]];
            }
            
            NSString *result = [identities componentsJoinedByString:@", "];
            
            [identities release];
            return [[[NSAttributedString alloc] initWithString:result attributes:style] autorelease];
        }
    } else
        return @"???";
}

@end

@implementation SmackXMPPServiceDiscoveryBrowsing

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
    }
    return self;
}

- (NSArray *)accountActionMenuItems
{
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Service Discovery Browser","Service Discovery Browser") action:@selector(browse:) keyEquivalent:@""];
    [mitem setTarget:self];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (void)browse:(NSMenuItem*)sender
{
    [[[SmackXMPPServiceDiscoveryBrowserController alloc] initWithAccount:account serviceName:[[account connection] getServiceName]] autorelease];
}

@end

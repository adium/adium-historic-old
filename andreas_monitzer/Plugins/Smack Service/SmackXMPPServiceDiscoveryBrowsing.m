//
//  SmackXMPPServiceDiscoveryBrowsing.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPServiceDiscoveryBrowsing.h"

#import "AIAccount.h"
#import "SmackXMPPAccount.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>

#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"

@interface SmackCocoaAdapter (serviceDiscoveryBrowsingAdditions)

+ (SmackXDiscoverItems*)discoverItems;

@end

@implementation SmackCocoaAdapter (serviceDiscoveryBrowsingAdditions)

+ (SmackXDiscoverItems*)discoverItems
{
    return [[[NSClassFromString(@"org.jivesoftware.smackx.packet.DiscoverItems") alloc] init] autorelease];
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
    IBOutlet NSProgressIndicator *progressIndicator;
    
    NSString *service;
    NSString *node;
    
    NSMutableDictionary *discoveredItems; // key = NSArray of jid + node (second is optional), value = NSArray of DiscoverItem
}

- (IBAction)changeServiceName:(id)sender;

@end

@implementation SmackXMPPServiceDiscoveryBrowserController

- (id)initWithAccount:(SmackXMPPAccount*)a
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
        
        [servicename setStringValue:service = [[[account connection] getServiceName] copy]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedIQPacket:)
                                                     name:SmackXMPPIQPacketReceivedNotification
                                                   object:account];
        
        discoveredItems = [[NSMutableDictionary alloc] init];
        
        [self queryJID:service node:nil];
        [window makeKeyAndOrderFront:nil];

        [self retain];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [service release];
    [discoveredItems release];
    [super dealloc];
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
}

- (void)queryJID:(NSString*)jid node:(NSString*)querynode
{
    SmackXDiscoverItems *packet = [SmackCocoaAdapter discoverItems];
    [packet setTo:jid];
    if(querynode)
        [packet setNode:querynode];
    [[account connection] sendPacket:packet];
}

- (void)receivedIQPacket:(NSNotification*)n
{
    SmackIQ *iq = [[n userInfo] objectForKey:SmackXMPPPacket];
    if(![SmackCocoaAdapter object:iq isInstanceOfJavaClass:@"org.jivesoftware.smackx.packet.DiscoverItems"])
        return;
    
    SmackXDiscoverItems *items = (SmackXDiscoverItems *)iq;
    if(items)
    {
        NSString *fromjid = [iq getFrom];
        NSString *fromnode = [items getNode]; // might be nil!
        NSMutableArray *itemarray = [[NSMutableArray alloc] init];
        JavaIterator *iter = [items getItems];
        
        while([iter hasNext])
        {
            SmackXDiscoverItem *item = [iter next];
            [itemarray addObject:item];
        }
        
        NSMutableDictionary *jiditems = [discoveredItems objectForKey:fromjid];
        if(!jiditems)
            [discoveredItems setObject:jiditems = [NSMutableDictionary dictionary] forKey:fromjid];
        
        [jiditems setObject:itemarray forKey:fromnode?(id)fromnode:(id)[NSNull null]];
        [itemarray release];
        
        [outlineview reloadData];
        NSLog(@"discoveredItems = %@",discoveredItems);
    }
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
    if(!item)
        return [[[discoveredItems objectForKey:service] objectForKey:node?(id)node:(id)[NSNull null]] objectAtIndex:index];
    return [[[discoveredItems objectForKey:[item getEntityID]] objectForKey:[item getNode]?(id)[item getNode]:(id)[NSNull null]] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if(!item)
    {
        NSArray *items = [[discoveredItems objectForKey:service] objectForKey:node?(id)node:(id)[NSNull null]];
        if(!items)
            return YES;
        return [items count] > 0;
    }
    NSArray *items = [[discoveredItems objectForKey:[item getEntityID]] objectForKey:[item getNode]?(id)[item getNode]:(id)[NSNull null]];
    if(!items)
        return YES;
    return [items count] > 0;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if(!item)
    {
        NSArray *items = [[discoveredItems objectForKey:service] objectForKey:node?(id)node:(id)[NSNull null]];
        return [items count];
    }
    NSArray *items = [[discoveredItems objectForKey:[item getEntityID]] objectForKey:[item getNode]?(id)[item getNode]:(id)[NSNull null]];
    return [items count];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    SmackXDiscoverItem *item = [[notification userInfo] objectForKey:@"NSObject"];
    [self queryJID:[item getEntityID] node:[item getNode]];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSString *identifier = [tableColumn identifier];
    if([identifier isEqualToString:@"name"])
        return [item getName];
    else if([identifier isEqualToString:@"jid"])
        return [item getEntityID];
    else if([identifier isEqualToString:@"node"])
        return [item getNode]?[item getNode]:@"";
    else if([identifier isEqualToString:@"category"])
        return @"N/A";
    else
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
    [[[SmackXMPPServiceDiscoveryBrowserController alloc] initWithAccount:account] autorelease];
}

@end

//
//  SmackXMPPServiceDiscoveryBrowsing.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-18.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "AMPurpleJabberServiceDiscoveryBrowsing.h"

#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import <Adium/AIAccount.h>
#import <Adium/DCJoinChatWindowController.h>
#import "DCPurpleJabberJoinChatViewController.h"
#include "xmlnode.h"
#include <Libpurple/jabber.h>

void jabber_adhoc_execute(JabberStream *js, JabberAdHocCommands *cmd);

static unsigned iqCounter = 0;
static NSImage *downloadprogress = nil;
static NSImage *det_triangle_opened = nil;
static NSImage *det_triangle_closed = nil;

@interface NSObject (AMPurpleJabberNodeDelegate)

- (void)jabberNodeGotItems:(AMPurpleJabberNode*)node;
- (void)jabberNodeGotInfo:(AMPurpleJabberNode*)node;

@end

@interface AMPurpleJabberNode : NSObject <NSCopying> {
    PurpleConnection *gc;
	
	NSString *jid;
	NSString *node;
	NSString *name;
	
	NSArray *items;
	NSSet *features;
	NSArray *identities;
	
	AMPurpleJabberNode *commands;
	
	NSMutableArray *delegates;
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc;

- (void)fetchItems;
- (void)fetchInfo;

- (NSString*)name;
- (NSString*)jid;
- (NSString*)node;
- (NSArray*)items;
- (NSSet*)features;
- (NSArray*)identities;
- (NSArray*)commands;

- (void)addDelegate:(id)delegate;
- (void)removeDelegate:(id)delegate;

@end

@implementation AMPurpleJabberNode

static void AMPurpleJabberNode_received_data_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	AMPurpleJabberNode *self = (AMPurpleJabberNode*)this;
	
	// we're receiving *all* packets, so let's filter out those that don't concern us
	const char *from = xmlnode_get_attrib(*packet, "from");
	if(!from)
		return;
	if(!(*packet)->name)
		return;
	const char *type = xmlnode_get_attrib(*packet, "type");
	if(!type || (strcmp(type, "result") && strcmp(type, "error")))
		return;
	if(strcmp((*packet)->name, "iq"))
		return;
	if(![[NSString stringWithUTF8String:from] isEqualToString:self->jid])
		return;
	xmlnode *query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#info");
	if(query) {
		if(self->features || self->identities)
			return; // we already have that information
		
		const char *node = xmlnode_get_attrib(query,"node");
		if((self->node && !node) || (!self->node && node))
			return;
		if(node && ![[NSString stringWithUTF8String:node] isEqualToString:self->node])
			return;

		// it's us, fill in features and identities
		NSMutableArray *identities = [[NSMutableArray alloc] init];
		NSMutableSet *features = [[NSMutableSet alloc] init];
		
		for(xmlnode *item = query->child; item; item = item->next) {
			if(item->type == XMLNODE_TYPE_TAG) {
				if(!strcmp(item->name, "identity")) {
					const char *category = xmlnode_get_attrib(item,"category");
					const char *type = xmlnode_get_attrib(item, "type");
					const char *name = xmlnode_get_attrib(item, "name");
					[identities addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						category?[NSString stringWithUTF8String:category]:[NSNull null], @"category",
						type?[NSString stringWithUTF8String:type]:[NSNull null], @"type",
						name?[NSString stringWithUTF8String:name]:[NSNull null], @"name",
						nil]];
				} else if(!strcmp(item->name, "feature")) {
					const char *var = xmlnode_get_attrib(item, "var");
					if(var)
						[features addObject:[NSString stringWithUTF8String:var]];
				}
			}
		}
		
		self->identities = identities;
		self->features = features;
		
		NSEnumerator *e = [self->delegates objectEnumerator];
		id delegate;
		while((delegate = [e nextObject]))
			if([delegate respondsToSelector:@selector(jabberNodeGotInfo:)])
				[delegate jabberNodeGotInfo:self];
		if([features containsObject:@"http://jabber.org/protocol/commands"]) {
			// in order to avoid endless loops, check if the current node isn't a command by itself (which can't contain other commands)
			BOOL isCommand = NO;
			e = [identities objectEnumerator];
			NSDictionary *identity;
			while((identity = [e nextObject])) {
				if([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
					isCommand = YES;
					break;
				}
			}
			
			if(!isCommand) {
				// commands have to be prefetched to be available when the user tries to access the context menu
				if(self->commands)
					[self->commands release];
				self->commands = [[AMPurpleJabberNode alloc] initWithJID:self->jid
																	node:@"http://jabber.org/protocol/commands"
																	name:nil
															  connection:self->gc];
				[self->commands fetchItems];
			}
		}
		return;
	}
	
	query = xmlnode_get_child_with_namespace(*packet,"query","http://jabber.org/protocol/disco#items");
	if(query) {
		if(self->items)
			return; // we already have that info
		
		const char *node = xmlnode_get_attrib(query,"node");
		if((self->node && !node) || (!self->node && node))
			return;
		if(node && ![[NSString stringWithUTF8String:node] isEqualToString:self->node])
			return;
		
		// it's us, create the subnodes
		NSMutableArray *items = [[NSMutableArray alloc] init];
		for(xmlnode *item = query->child; item; item = item->next) {
			if(item->type == XMLNODE_TYPE_TAG) {
				if(!strcmp(item->name, "item")) {
					const char *jid = xmlnode_get_attrib(item,"jid");
					const char *node = xmlnode_get_attrib(item,"node");
					const char *name = xmlnode_get_attrib(item,"name");
					
					if(jid) {
						AMPurpleJabberNode *newnode = [[AMPurpleJabberNode alloc] initWithJID:[NSString stringWithUTF8String:jid]
																						 node:node?[NSString stringWithUTF8String:node]:nil
																						 name:name?[NSString stringWithUTF8String:name]:nil
																				   connection:self->gc];
						// propagate delegates
						[newnode->delegates release];
						newnode->delegates = [self->delegates retain];
						[items addObject:newnode];
						// check if we're a conference service
						if([[self jid] rangeOfString:@"@"].location == NSNotFound) { // we can't be one when we have an @
							NSEnumerator *e = [[self identities] objectEnumerator];
							NSDictionary *identity;
							while((identity = [e nextObject])) {
								if([[identity objectForKey:@"category"] isEqualToString:@"conference"]) {
									// since we're a conference service, assume that our children are conferences
									newnode->identities = [[NSArray arrayWithObject:identity] retain];
									break;
								}
							}
							if(!identity)
								[newnode fetchInfo];
						} else
							[newnode fetchInfo];
						[newnode release];
					}
				}
			}
		}
		self->items = items;
		
		NSEnumerator *e = [self->delegates objectEnumerator];
		id delegate;
		while((delegate = [e nextObject]))
			if([delegate respondsToSelector:@selector(jabberNodeGotItems:)])
				[delegate jabberNodeGotItems:self];
	}
}

- (id)initWithJID:(NSString*)_jid node:(NSString*)_node name:(NSString*)_name connection:(PurpleConnection*)_gc {
	if((self = [super init])) {
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            [self release];
            return nil;
        }
		jid = [_jid copy];
		node = [_node copy];
		name = [_name copy];
		gc = _gc;
		delegates = [[NSMutableArray alloc] init];
		
		purple_signal_connect(jabber, "jabber-receiving-xmlnode", self,
                              PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), self);
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
	PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
	if (!jabber) {
		AILog(@"Unable to locate jabber prpl");
		[self release];
		return nil;
	}
	AMPurpleJabberNode *copy = [[AMPurpleJabberNode alloc] init];
	
	// share the items, identities and features between copies
	// copy the rest, keep delegates separate
	copy->jid = [jid copy];
	copy->node = [node copy];
	copy->name = [name copy];
	copy->gc = gc;
	copy->delegates = [[NSMutableArray alloc] init];
	copy->items = [items retain];
	copy->features = [features retain];
	copy->identities = [identities retain];
	
	purple_signal_connect(jabber, "jabber-receiving-xmlnode", copy,
						  PURPLE_CALLBACK(AMPurpleJabberNode_received_data_cb), copy);
	
	return copy;
}

- (void)dealloc {
	purple_signals_disconnect_by_handle(self);
	[jid release];
	[node release];
	[features release];
	[identities release];
	[items release];
	[name release];
	[commands release];
	[delegates release];
	[super dealloc];
}

- (void)fetchItems {
	if(items) {
		[items release];
		items = nil;
	}
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if(jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%u,",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#items"]];
	if(node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	jabber_prpl_send_raw(gc, [xmlData bytes], [xmlData length]);
}

- (void)fetchInfo {
	if(features) {
		[features release];
		features = nil;
	}
	if(identities) {
		[identities release];
		identities = nil;
	}
	
	NSXMLElement *iq = [NSXMLNode elementWithName:@"iq"];
	[iq addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"get"]];
	if(jid)
		[iq addAttribute:[NSXMLNode attributeWithName:@"to" stringValue:jid]];
	[iq addAttribute:[NSXMLNode attributeWithName:@"id" stringValue:[NSString stringWithFormat:@"%@%u",[self className], iqCounter++]]];
	
	NSXMLElement *query = [NSXMLNode elementWithName:@"query"];
	[query addNamespace:[NSXMLNode namespaceWithName:@"" stringValue:@"http://jabber.org/protocol/disco#info"]];
	if(node)
		[query addAttribute:[NSXMLNode attributeWithName:@"node" stringValue:node]];
	[iq addChild:query];
	
	NSData *xmlData = [[iq XMLString] dataUsingEncoding:NSUTF8StringEncoding];
	
	jabber_prpl_send_raw(gc, [xmlData bytes], [xmlData length]);
}

- (NSString*)name {
	return name;
}
- (NSString*)jid {
	return jid;
}
- (NSString*)node {
	return node;
}
- (NSArray*)items {
	if(!items) {
		BOOL isCommand = NO;
		NSEnumerator *e = [identities objectEnumerator];
		NSDictionary *identity;
		while((identity = [e nextObject])) {
			if([[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
				isCommand = YES;
				break;
			}
		}
		// commands don't contain any other nodes
		if(isCommand) {
			items = [[NSArray alloc] init];
			return items;
		}
	}
	
	return items;
}
- (NSSet*)features {
	return features;
}
- (NSArray*)identities {
	return identities;
}
- (NSArray*)commands {
	return [commands items];
}

- (void)addDelegate:(id)delegate {
	[delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
	[delegate removeObjectIdenticalTo:delegate];
}

@end

@interface NSObject (AMPurpleJabberServiceDiscoveryOutlineViewDelegate)

- (NSMenu*)outlineView:(NSOutlineView*)outlineView contextMenuForItem:(id)item;

@end

@interface AMPurpleJabberServiceDiscoveryOutlineView : NSOutlineView {
}

@end

@implementation AMPurpleJabberServiceDiscoveryOutlineView

- (void)rightMouseDown:(NSEvent *)theEvent {
	if([[self delegate] respondsToSelector:@selector(outlineView:contextMenuForItem:)]) {
		NSPoint loc = [theEvent locationInWindow];
		int row = [self rowAtPoint:[self convertPoint:loc fromView:[[self window] contentView]]];
		if(row != -1) {
			id item = [self itemAtRow:row];
			NSMenu *menu = [[self delegate] outlineView:self contextMenuForItem:item];
			[NSMenu popUpContextMenu:menu withEvent:theEvent forView:self];
		}
	}
}

@end

// one instance for every discovery browser window
@interface AMPurpleJabberServiceDiscoveryBrowserController : AIObject
{
	AIAccount *account;
    PurpleConnection *gc;

    IBOutlet NSWindow *window;
    IBOutlet NSTextField *servicename;
    IBOutlet NSTextField *nodename;
    IBOutlet NSOutlineView *outlineview;
    
	AMPurpleJabberNode *node;
}

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection *)_gc node:(AMPurpleJabberNode *)_node;

- (IBAction)changeServiceName:(id)sender;
- (IBAction)openService:(id)sender;
- (void)close;

@end

@implementation AMPurpleJabberServiceDiscoveryBrowserController

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection *)_gc node:(AMPurpleJabberNode *)_node
{
    if ((self = [super init]))
    {
		account = _account;
        gc = _gc;
        [NSBundle loadNibNamed:@"AMPurpleJabberDiscoveryBrowser" owner:self];
        if (!window) {
            NSLog(@"error loading AMPurpleJabberDiscoveryBrowser.nib!");
            [self release];
            return nil;
        }
		
		node = [_node retain];
		[node addDelegate:self];
		if(![node items])
			[node fetchItems];
		if(![node identities])
			[node fetchInfo];
        
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
	[window release];
	[node release];
    [super dealloc];
}

- (IBAction)openService:(id)sender
{
    int row = [outlineview clickedRow];
    if (row != -1)
    {
		AMPurpleJabberNode *item = [outlineview itemAtRow:row];
		NSArray *identities = [item identities];
		if(!identities)
			return;
		NSEnumerator *e = [identities objectEnumerator];
		NSDictionary *identity;
		
		while((identity = [e nextObject])) {
			if([[identity objectForKey:@"category"] isEqualToString:@"gateway"])
				jabber_register_gateway((JabberStream*)gc->proto_data, [[item jid] UTF8String]);
			else if([[identity objectForKey:@"category"] isEqualToString:@"conference"]) {
                DCJoinChatWindowController *jcwc = [DCJoinChatWindowController joinChatWindow];
                [jcwc configureForAccount:account];
                
				NSRange atsign = [[item jid] rangeOfString:@"@"];
				if(atsign.location == NSNotFound)
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setServer:[item jid]];
				else {
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setServer:[[item jid] substringFromIndex:atsign.location+1]];
					[(DCPurpleJabberJoinChatViewController*)[jcwc joinChatViewController] setRoomName:[[item jid] substringToIndex:atsign.location]];
				}
			} else if([[identity objectForKey:@"category"] isEqualToString:@"directory"]) {
				jabber_user_search((JabberStream*)gc->proto_data, [[item jid] UTF8String]);
			} else if([[identity objectForKey:@"category"] isEqualToString:@"automation"] &&
					  [[identity objectForKey:@"type"] isEqualToString:@"command-node"]) {
				JabberAdHocCommands cmd;
				
				cmd.jid = (char*)[[item jid] UTF8String];
				cmd.node = (char*)[[item node] UTF8String];
				cmd.name = (char*)[[item name] UTF8String];
				
				jabber_adhoc_execute(gc->proto_data, &cmd);
			}
		}
    }
}

- (IBAction)performCommand:(id)sender {
	AMPurpleJabberNode *commandnode = [sender representedObject];
	
	JabberAdHocCommands cmd;
	
	cmd.jid = (char*)[[commandnode jid] UTF8String];
	cmd.node = (char*)[[commandnode node] UTF8String];
	cmd.name = (char*)[[commandnode name] UTF8String];
	
	jabber_adhoc_execute(gc->proto_data, &cmd);
}

- (NSMenu*)outlineView:(NSOutlineView*)outlineView contextMenuForItem:(id)item {
	NSArray *commands = [(AMPurpleJabberNode*)item commands];
	if(!commands)
		return nil;
	
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	NSEnumerator *e = [commands objectEnumerator];
	AMPurpleJabberNode *command;
	
	while((command = [e nextObject])) {
		NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:[command name]
													   action:@selector(performCommand:)
												keyEquivalent:@""];
		[mitem setTarget:self];
		[mitem setRepresentedObject:command];
		[menu addItem:mitem];
		[mitem release];
	}
	
	return menu;
}

- (IBAction)changeServiceName:(id)sender {
	[node release];
	node = [[AMPurpleJabberNode alloc] initWithJID:[servicename stringValue] node:([[nodename stringValue] length]>0)?[nodename stringValue]:nil name:nil connection:gc];
	[node addDelegate:self];
	[node fetchInfo];
	[outlineview reloadData];
}

- (void)close {
	[window close];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self release];
}

- (void)jabberNodeGotItems:(AMPurpleJabberNode*)node {
    [outlineview reloadData];
}

- (void)jabberNodeGotInfo:(AMPurpleJabberNode*)node {
    [outlineview reloadData];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if(!item)
		return node;
	return [[item items] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if(![item items]) {
		// unknown
		return YES;
	}
	return [[item items] count] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return [item identities] != NULL;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	if([outlineview selectedRow] != -1) {
		AMPurpleJabberNode *selection = [outlineview itemAtRow:[outlineview selectedRow]];
		if(![selection features])
			[selection fetchInfo];
		[servicename setStringValue:[selection jid]];
		[nodename setStringValue:[selection node]?[selection node]:@""];
	}
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if(!item)
		return 1;
	return [[item items] count];
}

- (void)outlineViewItemWillExpand:(NSNotification *)notification
{
    AMPurpleJabberNode *item = [[notification userInfo] objectForKey:@"NSObject"];
	if(![item items])
		[item fetchItems];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    NSDictionary *style = [NSDictionary dictionaryWithObject:[item identities]?[NSColor blackColor]:[NSColor grayColor] forKey:NSForegroundColorAttributeName];

    NSString *identifier = [tableColumn identifier];
    
	if([identifier isEqualToString:@"jid"])
		return [[[NSAttributedString alloc] initWithString:[item jid] attributes:style] autorelease];
	else if([identifier isEqualToString:@"name"]) {
		if([item node]) {
			if([item name])
				return [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (%@)",[item name],[item node]] attributes:style] autorelease];
			return [[[NSAttributedString alloc] initWithString:[item node] attributes:style] autorelease];
		}
		if([item node])
			return [[[NSAttributedString alloc] initWithString:[item name] attributes:style] autorelease];
		// try to guess a name when there's none supplied
		NSRange slashsign = [[item jid] rangeOfString:@"/"];
		if(slashsign.location != NSNotFound)
			return [[[NSAttributedString alloc] initWithString:[[item jid] substringFromIndex:slashsign.location+1] attributes:style] autorelease];
		NSRange atsign = [[item jid] rangeOfString:@"@"];
		if(atsign.location != NSNotFound)
			return [[[NSAttributedString alloc] initWithString:[[item jid] substringToIndex:atsign.location] attributes:style] autorelease];
		if([[item identities] count] > 0) {
			NSDictionary *identity = [[item identities] objectAtIndex:0];
			id name = [identity objectForKey:@"name"];
			if(name != [NSNull null] && [name length] > 0)
				return [[[NSAttributedString alloc] initWithString:[identity objectForKey:@"name"] attributes:style] autorelease];
		}
		return [[[NSAttributedString alloc] initWithString:AILocalizedString(@"(unknown)",nil) attributes:style] autorelease];
	} else if([identifier isEqualToString:@"category"]) {
		if(![item identities])
			[[[NSAttributedString alloc] initWithString:AILocalizedString(@"Fetching...",nil) attributes:style] autorelease];
		
		NSMutableArray *identities = [[NSMutableArray alloc] init];
		
		NSEnumerator *e = [[item identities] objectEnumerator];
		NSDictionary *identity;
		while((identity = [e nextObject]))
			[identities addObject:[NSString stringWithFormat:@"%@ (%@)",[identity objectForKey:@"category"],[identity objectForKey:@"type"]]];
		
		NSString *result = [identities componentsJoinedByString:@", "];
		
		[identities release];
		return [[[NSAttributedString alloc] initWithString:result attributes:style] autorelease];
	} else
        return @"???";
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
	NSArray *identities = [item identities];
	if(!identities)
		return nil;
	NSMutableArray *result = [NSMutableArray array];
	NSEnumerator *e = [identities objectEnumerator];
	NSDictionary *identity;
	
	while((identity = [e nextObject])) {
		if([[identity objectForKey:@"category"] isEqualToString:@"gateway"])
			[result addObject:[NSString stringWithFormat:AILocalizedString(@"%@, double-click to register.","XMPP service discovery browser gateway tooltip"),[identity objectForKey:@"name"]]];
		else if([[identity objectForKey:@"category"] isEqualToString:@"conference"])
			[result addObject:AILocalizedString(@"Conference service, double-click to join",nil)];
		else if([[identity objectForKey:@"category"] isEqualToString:@"directory"])
			[result addObject:AILocalizedString(@"Directory service, double-click to search",nil)];
		else if([[identity objectForKey:@"category"] isEqualToString:@"automation"] &&
				[[identity objectForKey:@"type"] isEqualToString:@"command-node"])
			[result addObject:AILocalizedString(@"Ad-Hoc command, double-click to execute",nil)];
	}
	if([[item commands] count] > 0)
		[result addObject:AILocalizedString(@"This node provides ad-hoc commands. Open the context menu to access them.",nil)];
	if([result count] == 0)
		[result addObject:AILocalizedString(@"This node does not provide any services accessible to this program.",nil)];
	return [result componentsJoinedByString:@"\n"];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	BOOL expanded = [outlineView isItemExpanded:item];
	if(expanded && [item items] == nil) {
		if(!downloadprogress)
			downloadprogress = [[NSImage alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"downloadprogress" ofType:@"png"]];
		NSSize imgsize = [downloadprogress size];
		NSImage *img = [[NSImage alloc] initWithSize:imgsize];
		NSAffineTransform *transform = [NSAffineTransform transform];
		
		[transform translateXBy:imgsize.width/2.0 yBy:imgsize.height/2.0];
		NSTimeInterval intv = [NSDate timeIntervalSinceReferenceDate];
		intv -= floor(intv); // only get the fractional part
		[transform rotateByRadians:2.0*M_PI * (1.0-intv)];
		[transform translateXBy:-imgsize.width/2.0 yBy:-imgsize.height/2.0];
		
		[img lockFocus];
		[transform set];
		[downloadprogress drawInRect:NSMakeRect(0.0,0.0,imgsize.width,imgsize.height) fromRect:NSMakeRect(0.0,0.0,imgsize.width,imgsize.height)
											 operation:NSCompositeSourceOver fraction:1.0];
		[[NSAffineTransform transform] set];
		[img unlockFocus];
		[cell setImage:img];
		[img release];
		NSInvocation *inv = [[NSInvocation invocationWithMethodSignature:[outlineView methodSignatureForSelector:@selector(setNeedsDisplayInRect:)]] retain];
		[inv setSelector:@selector(setNeedsDisplayInRect:)];
		NSRect rect = [outlineView rectOfRow:[outlineView rowForItem:item]];
		[inv setArgument:&rect atIndex:2];
		
		[inv performSelector:@selector(invokeWithTarget:) withObject:outlineView afterDelay:0.1];
	} else {
		if(expanded) {
			if(!det_triangle_opened) {
				det_triangle_opened = [[NSImage alloc] initWithSize:NSMakeSize(13.0,13.0)];
				NSButtonCell *triangleCell = [[NSButtonCell alloc] initImageCell:nil];
				[triangleCell setButtonType:NSOnOffButton];
				[triangleCell setBezelStyle:NSDisclosureBezelStyle];
				[triangleCell setState:NSOnState];
				
				[det_triangle_opened lockFocus];
				[triangleCell drawWithFrame:NSMakeRect(0.0,0.0,13.0,13.0) inView:outlineView];
				[det_triangle_opened unlockFocus];
				
				[triangleCell release];
			}
				
			[cell setImage:det_triangle_opened];
		} else {
			if(!det_triangle_closed) {
				det_triangle_closed = [[NSImage alloc] initWithSize:NSMakeSize(13.0,13.0)];
				NSButtonCell *triangleCell = [[NSButtonCell alloc] initImageCell:nil];
				[triangleCell setButtonType:NSOnOffButton];
				[triangleCell setBezelStyle:NSDisclosureBezelStyle];
				[triangleCell setIntValue:NSOffState];
				
				[det_triangle_closed lockFocus];
				[triangleCell drawWithFrame:NSMakeRect(0.0,0.0,13.0,13.0) inView:outlineView];
				[det_triangle_closed unlockFocus];

				[triangleCell release];
			}
			
			[cell setImage:det_triangle_closed];
		}
	}
}

@end

@implementation AMPurpleJabberServiceDiscoveryBrowsing

- (id)initWithAccount:(AIAccount*)_account purpleConnection:(PurpleConnection*)_gc;
{
    if ((self = [super init]))
    {
        gc = _gc;
		account = _account;
		browsers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[browsers makeObjectsPerformSelector:@selector(close)];
	[browsers release];
	[rootnode release];
	[super dealloc];
}

- (IBAction)browse:(id)sender
{
	if(!rootnode) {
		JabberStream *js = gc->proto_data;
		JabberID *user = js->user;
		
		rootnode = [[AMPurpleJabberNode alloc] initWithJID:user->domain?[NSString stringWithUTF8String:user->domain]:nil node:nil name:user->domain?[NSString stringWithUTF8String:user->domain]:nil connection:gc];
	}
	AMPurpleJabberServiceDiscoveryBrowserController *browser = [[AMPurpleJabberServiceDiscoveryBrowserController alloc] initWithAccount:account purpleConnection:gc node:rootnode];
	[browsers addObject:browser];
	[browser release];
}

@end

//
//  AMXMLConsoleController.m
//  Adium
//
//  Created by Andreas Monitzer on 2007-06-06.
//  Copyright 2007 Andreas Monitzer. All rights reserved.
//

#import "AMXMLConsoleController.h"
#include <Libpurple/jabber.h>

static NSString *xmlprefix = @"<?xml version='1.0' encoding='UTF-8' ?>\n";

static void
xmlnode_received_cb(PurpleConnection *gc, xmlnode **packet, gpointer this)
{
    AMXMLConsoleController *self = (AMXMLConsoleController *)this;
    
    if(!this || [self gc] != gc)
        return;
    
	char *str = xmlnode_to_formatted_str(*packet, NULL);
    NSString *sstr = [NSString stringWithUTF8String:str];
    
    if([sstr hasPrefix:xmlprefix])
        sstr = [sstr substringFromIndex:[xmlprefix length]];
    
    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:[NSDictionary dictionaryWithObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName]];
    [self appendToLog:astr];
    [astr release];
    
	g_free(str);
}

static void
xmlnode_sent_cb(PurpleConnection *gc, char **packet, gpointer this)
{
    AMXMLConsoleController *self = (AMXMLConsoleController *)this;
	xmlnode *node;

    if (!this || [self gc] != gc)
        return;

	node = ((*packet && strlen(*packet) && ((*packet)[0] == '<')) ?
			xmlnode_from_str(*packet, -1) :
			NULL);

	if (!node)
		return;
	
	char *str = xmlnode_to_formatted_str(node, NULL);
    NSString *sstr = [NSString stringWithUTF8String:str];
    
    if([sstr hasPrefix:xmlprefix])
        sstr = [sstr substringFromIndex:[xmlprefix length]];

    NSAttributedString *astr = [[NSAttributedString alloc] initWithString:sstr
                                                               attributes:[NSDictionary dictionaryWithObject:[NSColor blueColor] forKey:NSForegroundColorAttributeName]];
    [self appendToLog:astr];
    [astr release];
    
	g_free(str);
	xmlnode_free(node);
}

@implementation AMXMLConsoleController

- (id)initWithPurpleConnection:(PurpleConnection*)_gc; {
    if((self = [super init])) {
        gc = _gc;
        [NSBundle loadNibNamed:@"AMPurpleJabberXMLConsole" owner:self];
        if(!xmlConsoleWindow) {
            AILog(@"Unable to load AMPurpleJabberXMLConsole!");
            [self release];
            return nil;
        }
        
        PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            [self release];
            return nil;
        }
        
        purple_signal_connect(jabber, "jabber-receiving-xmlnode", self,
                              PURPLE_CALLBACK(xmlnode_received_cb), self);
        purple_signal_connect(jabber, "jabber-sending-text", self,
                              PURPLE_CALLBACK(xmlnode_sent_cb), self);
    }
    return self;
}

- (void)dealloc {
    purple_signals_disconnect_by_handle(self);
    
    [xmlConsoleWindow release];
    [super dealloc];
}

- (IBAction)sendXML:(id)sender {
    NSData *rawXMLData = [[xmlInjectView string] dataUsingEncoding:NSUTF8StringEncoding];
    jabber_prpl_send_raw(gc, [rawXMLData bytes], [rawXMLData length]);
    // remove from text field
    [xmlInjectView setString:@""];
}

- (IBAction)clearLog:(id)sender {
    [xmlLogView setString:@""];
}

- (IBAction)showWindow:(id)sender {
    [xmlConsoleWindow makeKeyAndOrderFront:sender];
}

- (void)appendToLog:(NSAttributedString*)astr {
    if([enabledButton intValue]) {
        [self->xmlLogView replaceCharactersInRange:NSMakeRange([[self->xmlLogView string] length],0)
                                           withRTF:[astr RTFFromRange:NSMakeRange(0,[astr length])
                                                   documentAttributes:nil]];
        [self->xmlLogView scrollRangeToVisible:NSMakeRange([[self->xmlLogView string] length],0)];
    }
}

- (PurpleConnection*)gc {
    return gc;
}

@end

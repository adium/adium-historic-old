#import "AMPurpleJabberAdHocServer.h"
#include <Libpurple/jabber.h>
#import "ESPurpleJabberAccount.h"
#import "AMPurpleJabberFormGenerator.h"

@implementation AMPurpleJabberAdHocCommand

- (id)initWithServer:(AMPurpleJabberAdHocServer*)_server command:(xmlnode*)_command jid:(NSString*)_jid iqid:(NSString*)_iqid {
	if((self = [super init])) {
		server = _server;
		command = xmlnode_copy(_command);
		jid = [_jid copy];
		iqid = [_iqid copy];
	}
	return self;
}

- (void)dealloc {
	xmlnode_free(command);
	[jid release];
	[iqid release];
	[sessionid release];
	[super dealloc];
}

- (AMPurpleJabberFormGenerator*)form {
	xmlnode *form = xmlnode_get_child_with_namespace(command,"x","jabber:x:data");
	if(!form)
		return nil;
	return [[[AMPurpleJabberFormGenerator alloc] initWithXML:form] autorelease];
}

- (NSString*)jid {
	return jid;
}

- (NSString*)sessionid {
	if(sessionid)
		return sessionid;
	const char *sessionid_orig = xmlnode_get_attrib(command,"sessionid");
	if(!sessionid_orig)
		return nil;
	return [NSString stringWithUTF8String:sessionid_orig];
}

- (void)setSessionid:(NSString*)_sessionid {
	id old = sessionid;
	sessionid = [_sessionid copy];
	[old release];
}

- (AMPurpleJabberAdHocCommand*)generateReplyWithForm:(AMPurpleJabberFormGenerator*)form actions:(NSArray*)actions defaultAction:(unsigned)defaultAction status:(enum AMPurpleJabberAdHocCommandStatus)status {
	const char *nodeattr = xmlnode_get_attrib(command,"node");
	if(!nodeattr)
		return nil;
	xmlnode *newcmd = xmlnode_new("command");
	xmlnode_set_namespace(newcmd,"http://jabber.org/protocol/commands");
	xmlnode_set_attrib(newcmd,"node",nodeattr);
	switch(status) {
		case executing:
			xmlnode_set_attrib(newcmd,"status","executing");
			break;
		case canceled:
			xmlnode_set_attrib(newcmd,"status","canceled");
			break;
		case completed:
			xmlnode_set_attrib(newcmd,"status","completed");
			break;
	}
	NSString *sessionid_orig = [self sessionid];
	if(sessionid_orig)
		xmlnode_set_attrib(newcmd,"sessionid",[sessionid_orig UTF8String]);
	
	if(actions) {
		xmlnode *actionsnode = xmlnode_new_child(newcmd,"actions");
		xmlnode_set_attrib(actionsnode,"execute",[[actions objectAtIndex:defaultAction] UTF8String]);
		NSEnumerator *e = [actions objectEnumerator];
		NSString *actionstr;
		while((actionstr = [e nextObject]))
			xmlnode_new_child(actionsnode, [actionstr UTF8String]);
	}
	
	xmlnode_insert_child(newcmd,[form xml]);
	
	AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:server command:newcmd jid:jid iqid:iqid];
	xmlnode_free(newcmd);
	return [cmd autorelease];
}

- (AMPurpleJabberAdHocCommand*)generateReplyWithNote:(NSString*)text type:(enum AMPurpleJabberAdHocCommandNoteType)type status:(enum AMPurpleJabberAdHocCommandStatus)status {
	const char *nodeattr = xmlnode_get_attrib(command,"node");
	if(!nodeattr)
		return nil;
	xmlnode *newcmd = xmlnode_new("command");
	xmlnode_set_namespace(newcmd,"http://jabber.org/protocol/commands");
	xmlnode_set_attrib(newcmd,"node",nodeattr);
	switch(status) {
		case executing:
			xmlnode_set_attrib(newcmd,"status","executing");
			break;
		case canceled:
			xmlnode_set_attrib(newcmd,"status","canceled");
			break;
		case completed:
			xmlnode_set_attrib(newcmd,"status","completed");
			break;
	}
	NSString *sessionid_orig = [self sessionid];
	if(sessionid_orig)
		xmlnode_set_attrib(newcmd,"sessionid",[sessionid_orig UTF8String]);

	xmlnode *note = xmlnode_new_child(newcmd,"note");
	switch(type) {
		case error:
			xmlnode_set_attrib(note,"type","error");
			break;
		case info:
			xmlnode_set_attrib(note,"type","info");
			break;
		case warn:
			xmlnode_set_attrib(note,"type","warn");
			break;
	}
	
	xmlnode_insert_data(note,[text UTF8String],-1);
	
	AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:server command:newcmd jid:jid iqid:iqid];
	xmlnode_free(newcmd);
	return [cmd autorelease];
}

- (void)send {
	PurpleAccount *account = [[server account] purpleAccount];
	xmlnode *iq = xmlnode_new("iq");
	
	xmlnode_set_attrib(iq, "id", [iqid UTF8String]);
	xmlnode_set_attrib(iq, "to", [jid UTF8String]);
	xmlnode_set_attrib(iq, "type", "result");
	xmlnode *cmdcopy = xmlnode_copy(command);
	if(sessionid)
		xmlnode_set_attrib(cmdcopy, "sessionid", [sessionid UTF8String]);
	xmlnode_insert_child(iq, cmdcopy);
	
	int len = 0;
	char *text = xmlnode_to_str(iq, &len);
	PURPLE_PLUGIN_PROTOCOL_INFO(account->gc->prpl)->send_raw(account->gc, text, len);
	g_free(text);
	xmlnode_free(iq);
}

@end

@interface AMPurpleJabberAdHocServer (privateMethods)

- (BOOL)receivedCommand:(xmlnode*)command from:(NSString*)jid iqid:(NSString*)iqid;
- (void)addCommandsToXML:(xmlnode*)xml;

@end

static void AMPurpleJabberAdHocServer_received_data_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	AMPurpleJabberAdHocServer *self = this;
	PurpleAccount *account = [[self account] purpleAccount];
	if(account->gc == gc) {
		if(strcmp((*packet)->name,"iq"))
		   return;
		const char *type = xmlnode_get_attrib(*packet,"type");
		if(!type || strcmp(type,"set"))
			return; // doesn't talk to us, probably the user interacting with some other adhoc node
		const char *from = xmlnode_get_attrib(*packet,"from");
		const char *iqid = xmlnode_get_attrib(*packet,"id");
		xmlnode *command = xmlnode_get_child_with_namespace(*packet,"command","http://jabber.org/protocol/commands");
		if(command) {
			BOOL handled = [self receivedCommand:command
											from:from?[NSString stringWithUTF8String:from]:nil
											iqid:iqid?[NSString stringWithUTF8String:iqid]:nil];
			if(handled) {
				xmlnode_free(*packet);
				*packet = NULL;
			}
		}
	}
}

/* we have to catch the reply to a disco#info for http://jabber.org/protocol/commands and insert our nodes */
static void xmlnode_sent_cb(PurpleConnection *gc, xmlnode **packet, gpointer this) {
	xmlnode *xml = *packet;
	AMPurpleJabberAdHocServer *self = this;
	PurpleAccount *account = [[self account] purpleAccount];
	if(xml && account->gc == gc) {
		if(!strcmp(xml->name,"iq")) {
			const char *tostr = xmlnode_get_attrib(xml,"to");
			if(tostr) {
				NSString *to = [NSString stringWithUTF8String:tostr];
				NSRange slash = [to rangeOfString:@"/"];
				if(slash.location != NSNotFound) {
					NSString *barejid = [to substringToIndex:slash.location];
					if([barejid isEqualToString:[[self account] UID]]) {
						const char *type = xmlnode_get_attrib(xml,"type");
						if(type && !strcmp(type,"result")) {
							xmlnode *query = xmlnode_get_child_with_namespace(xml,"query","http://jabber.org/protocol/disco#items");
							if(query) {
								const char *node = xmlnode_get_attrib(query,"node");
								if(node && !strcmp(node,"http://jabber.org/protocol/commands"))
									[self addCommandsToXML:query];
							}
						}
					}
				}
			}
		}
	}
}

@implementation AMPurpleJabberAdHocServer

+ (void)initialize {
	jabber_add_feature("adiumcmd", "http://jabber.org/protocol/commands", NULL);
}

- (id)initWithAccount:(ESPurpleJabberAccount*)_account {
	if((self = [super init])) {
		account = _account;
		commands = [[NSMutableDictionary alloc] init];
		
		PurplePlugin *jabber = purple_find_prpl("prpl-jabber");
        if (!jabber) {
            AILog(@"Unable to locate jabber prpl");
            [self release];
            return nil;
        }

		purple_signal_connect(jabber, "jabber-receiving-xmlnode", self,
                              PURPLE_CALLBACK(AMPurpleJabberAdHocServer_received_data_cb), self);
        purple_signal_connect(jabber, "jabber-sending-xmlnode", self,
                              PURPLE_CALLBACK(xmlnode_sent_cb), self);
	}
	return self;
}

- (void)dealloc {
	purple_signals_disconnect_by_handle(self);
	[commands release];
	[super dealloc];
}

- (void)addCommand:(NSString*)node delegate:(id)delegate name:(NSString*)name {
	[commands setObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSValue valueWithNonretainedObject:delegate],@"delegate",
				name, @"name",
				nil] forKey:node];
}

- (void)removeCommand:(NSString*)node {
	[commands removeObjectForKey:node];
}

- (ESPurpleJabberAccount*)account {
	return account;
}

- (void)addCommandsToXML:(xmlnode*)xml {
	NSEnumerator *e = [commands keyEnumerator];
	NSString *node;
	JabberStream *js = purple_account_get_connection([[self account] purpleAccount])->proto_data;
	char *jid = g_strdup_printf("%s@%s/%s", js->user->node, js->user->domain, js->user->resource);
	
	while((node = [e nextObject])) {
		xmlnode *item = xmlnode_new_child(xml, "item");
		xmlnode_set_attrib(item,"jid",jid);
		xmlnode_set_attrib(item,"name",[[[commands objectForKey:node] objectForKey:@"name"] UTF8String]);
		xmlnode_set_attrib(item,"node",[node UTF8String]);
	}
	g_free(jid);
}

- (BOOL)receivedCommand:(xmlnode*)command from:(NSString*)jid iqid:(NSString*)iqid {
	// verify that it's the same bare jid this command was received from
	if(!jid)
		return NO;
	NSRange slash = [jid rangeOfString:@"/"];
	if(slash.location == NSNotFound || ![[jid substringToIndex:slash.location] isEqualToString:[account UID]])
		return NO;
	
	const char *node = xmlnode_get_attrib(command,"node");
	
	if(node) {
		id delegate = [[commands objectForKey:[NSString stringWithUTF8String:node]] objectForKey:@"delegate"];
		if(delegate && [[delegate nonretainedObjectValue] respondsToSelector:@selector(adHocServer:executeCommand:)]) {
			AMPurpleJabberAdHocCommand *cmd = [[AMPurpleJabberAdHocCommand alloc] initWithServer:self command:command jid:jid iqid:iqid];
			[[delegate nonretainedObjectValue] adHocServer:self executeCommand:cmd];
			[cmd release];
			return YES;
		}
	}
	return NO;
}

@end

@implementation AMPurpleJabberAdHocPing

+ (void)adHocServer:(AMPurpleJabberAdHocServer*)server executeCommand:(AMPurpleJabberAdHocCommand*)command {
	[[command generateReplyWithNote:@"Pong" type:info status:completed] send];
}

@end


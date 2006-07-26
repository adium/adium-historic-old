//
//  SmackXMPPAccountRegistrationController.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-07-21.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackXMPPAccountRegistrationController.h"
#import "SmackCocoaAdapter.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackXMPPRegistration.h"
#import "SmackXMPPAccount.h"
#import "SmackXMPPAccountViewController.h"
#import "SmackXMPPErrorMessagePlugin.h"

#import <AIUtilities/AIStringUtilities.h>
#import "AIAdium.h"
#import "AIInterfaceController.h"
#import "ESDebugAILog.h"

#import <CoreServices/CoreServices.h>

#import "ruli/ruli.h"

#define SERVERLISTURL @"http://www.xmpp.net/bycountry.shtml"
#define SERVERLISTTRANFORM [ \
@"<?xml version='1.0' encoding='utf-8'?>" \
@"<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'" \
@"                              xmlns:g='http://jabber.org/protocol/geoloc'" \
@"                              xmlns:o='jabber:x:oob'" \
@"                              xmlns='http://jabber.org/protocol/disco#items'>" \
 \
@"<xsl:output method='xml' version='1.0' encoding='utf-8' indent='no'/>" \
 \
@"<xsl:template match='/'>" \
@"<query>" \
@"<xsl:for-each select='html//table'>" \
@"	<xsl:for-each select='tr'>" \
@"		<xsl:if test='td[2]/a != \"\"'>" \
@"		<item>" \
@"			<xsl:attribute name='jid'><xsl:value-of select='td[2]/a'/></xsl:attribute>" \
@"			<o:x><o:url><xsl:value-of select='td[2]/a/@href'/></o:url></o:x>" \
@"			<g:geoloc>" \
@"				<g:description><xsl:value-of select='td[1]'/></g:description>" \
@"				<g:lat><xsl:value-of select='td[3]'/></g:lat>" \
@"				<g:lon><xsl:value-of select='td[4]'/></g:lon>" \
@"			</g:geoloc>" \
@"		</item>" \
@"		</xsl:if>" \
@"	</xsl:for-each>" \
@"</xsl:for-each>" \
@"</query>" \
@"</xsl:template>" \
 \
@"</xsl:stylesheet>" dataUsingEncoding:NSUTF8StringEncoding]


@implementation SmackXMPPAccountRegistrationController

- (id)initWithAccountViewController:(SmackXMPPAccountViewController*)avc
{
    if((self = [super init]))
    {
        accountviewcontroller = avc;
        
        MachineLocation loc;
        ReadLocation(&loc);
        
        latitude = FractToFloat(loc.latitude)*(M_PI/2.0f);
        longitude = FractToFloat(loc.longitude)*(M_PI/2.0f);
        
        NSURL *sourceURL = [NSURL URLWithString:SERVERLISTURL];
        NSError *error;
        NSXMLDocument *serverhtml = [[NSXMLDocument alloc] initWithContentsOfURL:sourceURL options:NSXMLDocumentTidyXML error:&error];
        if(serverhtml)
            serverlist = [[serverhtml objectByApplyingXSLT:SERVERLISTTRANFORM arguments:[NSDictionary dictionary] error:&error] retain];
        [serverhtml release];
        
        if(!serverlist)
        {
            [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Error Parsing %@","Error Parsing %@"), SERVERLISTURL] withDescription:[error localizedDescription]];
        } else {
            [serverlist setCharacterEncoding:@"UTF-8"];
            
            serverlist_root = [serverlist rootElement];
        }
        
        [NSBundle loadNibNamed:@"SmackXMPPAccountRegistration" owner:self];
        
        if(!window)
        {
            NSLog(@"Error loading SmackXMPPAccountRegistration.nib!");
            NSBeep();
            [self release];
            return nil;
        }
        [window makeKeyAndOrderFront:self];
        [self retain];
    }
    return self;
}

- (void)dealloc
{
    [smackAdapter release];
    [serverlist release];
    [errorPlugin release];
    errorPlugin = nil;

    [super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

#pragma mark tableview

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[serverlist_root elementsForName:@"item"] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
    if([[tableColumn identifier] isEqualToString:@"distance"]) {
        float latitude2, longitude2;
        
        NSXMLElement *item = [[serverlist_root elementsForName:@"item"] objectAtIndex:row];
        NSXMLElement *geoloc = [[item elementsForLocalName:@"geoloc" URI:@"http://jabber.org/protocol/geoloc"] lastObject];
        
        if(!geoloc)
            return AILocalizedString(@"N/A","N/A");
        
        NSString *latstr = [[[geoloc elementsForLocalName:@"lat" URI:@"http://jabber.org/protocol/geoloc"] lastObject] stringValue];
        if(!latstr)
            return AILocalizedString(@"N/A","N/A");
        NSString *lonstr = [[[geoloc elementsForLocalName:@"lon" URI:@"http://jabber.org/protocol/geoloc"] lastObject] stringValue];
        if(!lonstr)
            return AILocalizedString(@"N/A","N/A");
        
        // Calculate the distance between the computer and the xmpp server in km
        // Note that this assumes that the earth is a perfect sphere
        // If it turns out to be flat or doughnut-shaped, this will not work!
        
        latitude2 = [latstr floatValue] * (M_PI/180.0f);
        longitude2 = [lonstr floatValue] * (M_PI/180.0f);
        
        float d_lat = sinf((latitude2 - latitude)/2.0);
        float d_long = sinf((longitude2 - longitude)/2.0);
        float a = d_lat*d_lat + cosf(latitude)*cosf(latitude2)*d_long*d_long;
        float c = 2*atan2f(sqrtf(a),sqrtf(1.0-a));
        float d = 6372.797*c; // mean earth radius
        return [NSNumber numberWithFloat:d];
    }
    return [[[[serverlist_root elementsForName:@"item"] objectAtIndex:row] attributeForName:[tableColumn identifier]] stringValue];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSXMLElement *server = [[serverlist_root elementsForName:@"item"] objectAtIndex:[[notification object] selectedRow]];
    [serverField setStringValue:[[server attributeForName:@"jid"] stringValue]];
    NSXMLElement *active = [[server elementsForName:@"active"] lastObject];
    if(!active)
        [portField setStringValue:@""];
    else
        [portField setStringValue:[[active attributeForName:@"port"] stringValue]];
}

#pragma mark Connection stuff

- (SmackConnectionConfiguration*)connectionConfiguration {
    NSString *host = [serverField stringValue];
    int portnum = ([[portField stringValue] length]==0)?5222:[portField intValue];
    
    // do an SRV lookup
    
    ruli_sync_t *query = ruli_sync_query("_xmpp-client._tcp", [host cStringUsingEncoding:NSUTF8StringEncoding] /* ### punycode */, portnum, RULI_RES_OPT_SEARCH | RULI_RES_OPT_SRV_RFC3484 | RULI_RES_OPT_SRV_CNAME /* be tolerant to broken DNS configurations */);
    
    int srv_code;
    
    if(query != NULL && (srv_code = ruli_sync_srv_code(query)) == 0) {
        ruli_list_t *list = ruli_sync_srv_list(query);
        // we should use some kind of round-robbin to try the other results from this query
        
        if(ruli_list_size(list) > 0) {
            ruli_srv_entry_t *srventry = ruli_list_get(list,0);
            
            char dname[RULI_LIMIT_DNAME_TEXT_BUFSZ];
            int dname_length;
            
            if(ruli_dname_decode(dname, RULI_LIMIT_DNAME_TEXT_BUFSZ, &dname_length, srventry->target, srventry->target_len) == RULI_TXT_OK) {
                host = [[[NSString alloc] initWithBytes:dname length:dname_length encoding:NSASCIIStringEncoding] autorelease];
                portnum = srventry->port;
            } else
                AILog(@"XMPP: failed decoding SRV resolve domain name");
        } else
            AILog(@"XMPP: SRV query returned 0 results");
        
        ruli_sync_delete(query);
    } else
        AILog(@"XMPP: SRV resolve for host \"%@\" returned error %d", host, srv_code);
    
    NSLog(@"host = %@:%d",host,portnum);
    
    SmackConnectionConfiguration *conf = [SmackCocoaAdapter connectionConfigurationWithHost:host port:portnum service:[serverField stringValue]];
    
    // supply some sane defaults (don't overload the user with those options!)
    
    [conf setCompressionEnabled:NO];
    [conf setDebuggerEnabled:NO];
    [conf setExpiredCertificatesCheckEnabled:NO];
    [conf setNotMatchingDomainCheckEnabled:NO];
    [conf setSASLAuthenticationEnabled:YES];
    [conf setSelfSignedCertificateEnabled:YES];
    [conf setTLSEnabled:NO/*###*/];
    
    return conf;
}

- (IBAction)requestAccount:(id)sender
{
    [window makeFirstResponder:nil];
    
    [serverField setEnabled:NO];
    [portField setEnabled:NO];
    [serverlistTable setEnabled:NO];
    [requestButton setEnabled:NO];
    
    [progressIndicator startAnimation:nil];
    
    smackAdapter = [[SmackCocoaAdapter alloc] initForAccount:(SmackXMPPAccount*)self];
    errorPlugin = [[SmackXMPPErrorMessagePlugin alloc] initWithAccount:(SmackXMPPAccount*)self];
}

- (SmackXMPPConnection*)connection
{
    return connection;
}

#pragma mark SmackXMPPAccount posing stuff

- (WebView*)webView
{
    return webview;
}

- (void)registration:(SmackXMPPRegistration*)reg didEndWithSuccess:(BOOL)success
{
    if(success)
    {
        SmackXForm *resultForm = [reg resultForm];
        NSString *username = [[[resultForm getField:@"username"] getValues] next];
        NSString *password = [[[resultForm getField:@"password"] getValues] next];
        
        [accountviewcontroller setJID:[NSString stringWithFormat:@"%@@%@",username,[serverField stringValue]] password:password];
        
        [window performClose:nil];
    } else {
        [tabview selectTabViewItemWithIdentifier:@"serverselection"];
        
        [connection close];
        [smackAdapter release]; smackAdapter = nil;
        
        [serverField setEnabled:YES];
        [portField setEnabled:YES];
        [serverlistTable setEnabled:YES];
        [requestButton setEnabled:YES];
    }
}

- (NSString*)explicitFormattedUID
{
    return [NSString stringWithFormat:AILocalizedString(@"<Server %@>","<Server %@>"),[serverField stringValue]];
}

- (void)connected:(SmackXMPPConnection*)conn
{
    [progressIndicator stopAnimation:nil];

    connection = [conn retain];
    
    [[[SmackXMPPRegistration alloc] initWithAccount:(SmackXMPPAccount*)self registerWith:[serverField stringValue]] autorelease];
    
    [tabview selectTabViewItemWithIdentifier:@"registrationform"];
}

- (void)disconnected:(SmackXMPPConnection*)conn
{
    [connection release];
    connection = nil;
    [errorPlugin release];
    errorPlugin = nil;
}

- (void)connectionError:(NSString*)error
{
    [progressIndicator stopAnimation:nil];

    [[adium interfaceController] handleErrorMessage:[NSString stringWithFormat:AILocalizedString(@"Connection Error While Talking to %@.","Connection Error While Talking to %@."),[serverField stringValue]] withDescription:error];
    
    [connection close];
    [smackAdapter release]; smackAdapter = nil;
    
    [serverField setEnabled:YES];
    [portField setEnabled:YES];
    [serverlistTable setEnabled:YES];
    [requestButton setEnabled:YES];

    [tabview selectTabViewItemWithIdentifier:@"serverselection"];
}

- (void)receiveMessagePacket:(SmackMessage*)packet
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPMessagePacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}

- (void)receivePresencePacket:(SmackPresence*)packet
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPPresencePacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}

- (void)receiveIQPacket:(SmackIQ*)packet
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SmackXMPPIQPacketReceivedNotification
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:packet forKey:SmackXMPPPacket]];
}

@end

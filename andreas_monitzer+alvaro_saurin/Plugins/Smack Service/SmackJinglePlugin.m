//
//  SmackJinglePlugin.m
//  Adium
//
//  Created by Andreas Monitzer on 2006-08-10.
//  Copyright 2006 Andreas Monitzer. All rights reserved.
//

#import "SmackJinglePlugin.h"
#import "AIAdium.h"
#import <AIUtilities/AIStringUtilities.h>
#import <JavaVM/NSJavaVirtualMachine.h>

#import "ESTextAndButtonsWindowController.h"

#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"

#import "AIVideoConf.h"

@interface SmackJingleListener : NSObject {
}

- (SmackXJingleManager*)getManager;

@end

@interface SmackCocoaAdapter (jinglePlugin)

+ (SmackJingleListener*)createJingleListenerForConnection:(SmackXMPPConnection*)conn delegate:(id)delegate;

@end

@implementation SmackCocoaAdapter (jinglePlugin)

+ (SmackJingleListener*)createJingleListenerForConnection:(SmackXMPPConnection*)conn delegate:(id)delegate
{
    return [[(id)[[self classLoader] loadClass:@"net.adium.smackBridge.JingleListener"] getInstance:conn :delegate] autorelease];
}

@end

@implementation SmackJinglePlugin

- (id)initWithAccount:(SmackXMPPAccount*)a
{
    if((self = [super init]))
    {
        account = a;
    }
    return self;
}

- (void)dealloc
{
    [listener release];
    [super dealloc];
}

- (void)connected:(SmackXMPPConnection*)connection
{
    listener = [[SmackCocoaAdapter createJingleListenerForConnection:[account connection] delegate:self] retain];
}

- (void)disconnected:(SmackXMPPConnection*)connection
{
    [listener release];
    listener = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                 Payloads Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief	Get the list of supported audio payloads
 */
- (JavaVector*) getSupportedAudioPayloads
{
    JavaVector		*payloadsJava	= [SmackCocoaAdapter vector];    
	NSArray			*payloadsList	= [[adium vcController] getAudioPayloadsForProtocol:VC_RTP];
	NSEnumerator	*payloadsEnum	= [payloadsList objectEnumerator];
	VCPayload		*payload;
	
	// Add the list of payloads
	while ((payload = [payloadsEnum nextObject])) {
		[payloadsJava add:payload];
	}

	return payloadsJava;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                 Incoming Sessions
////////////////////////////////////////////////////////////////////////////////

- (void) acceptIncomingJingleSessionQuestion:(NSNumber*) number userInfo:(id) info
{	
	SmackXIncomingJingleSession	*session		= nil;
    JavaVector					*payloadTypes	= [self getSupportedAudioPayloads];
	SmackXJingleSessionRequest	*request		= info;	
	AITextAndButtonsReturnCode	 result			= [number intValue];

	switch (result) {
		
		case AITextAndButtonsDefaultReturn:
			NSLog (@"Establishing incoming Jingle session.");

			@try {
				session = [request accept:payloadTypes];
				[session start:request];
			} @catch (NSException *e) {
				[[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Jingle Error","Jingle Error")]
											 withDescription:[e reason]
											 withWindowTitle:AILocalizedString(@"Notice","Notice")
											   defaultButton:AILocalizedString(@"OK","OK")
											 alternateButton:nil
												 otherButton:nil
													  target:nil
													selector:NULL
													userInfo:nil];
			}
			break;

		case AITextAndButtonsAlternateReturn:
			NSLog (@"Rejecting incoming Jingle session.");
			[request reject];
			break;

		default:
			break;
	}
}

/*!
 * @brief    A session request is received
 */
- (void) setJingleSessionRequest:(SmackXJingleSessionRequest*) request
{
	NSString *question = [NSString stringWithFormat:AILocalizedString(@"Accept audio chat", nil)];
	NSString *description = [NSString stringWithFormat:AILocalizedString(@"You have been invited to an audio chat.\nDo you want to accept this invitation?", nil)];

	// Ask to the user if he/she accept the session
	[[adium interfaceController] displayQuestion:question
								 withDescription:description
								 withWindowTitle:AILocalizedString(@"Audio Session",nil)
								   defaultButton:AILocalizedString(@"Accept",nil)
								 alternateButton:AILocalizedString(@"Reject",nil)
									 otherButton:nil
										  target:self
										selector:@selector(acceptIncomingJingleSessionQuestion:userInfo:)
										userInfo:request];

	// Send a message saying that this is "ringing"
	[[listener getManager] sendContentInfo:[SmackXContentInfoAudio fromString:@"ringing"]];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Outgoing Sessions
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief    Start an outgoing session
 */
- (void)establishOutgoingJingleSessionTo:(NSString*)jid
{
	SmackXOutgoingJingleSession *session		= nil;
    JavaVector					*payloadTypes	= [self getSupportedAudioPayloads];

	NSLog (@"Establishing outgoing Jingle session.");
	
	@try {
		session = [[listener getManager] createOutgoingJingleSession:jid :payloadTypes];
		[session start:nil];
    } @catch (NSException *e) {
        [[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Jingle Error","Jingle Error")]
									 withDescription:[e reason]
									 withWindowTitle:AILocalizedString(@"Notice","Notice")
									   defaultButton:AILocalizedString(@"OK","OK")
									 alternateButton:nil
										 otherButton:nil
											  target:nil
											selector:NULL
											userInfo:nil];
    }
}

// add a menu item to the contact's context menu, so an outgoing session can be established
- (NSArray *)menuItemsForContact:(AIListContact *)inContact {
    SmackXDiscoverInfo *info = [inContact statusObjectForKey:@"XMPP:disco#info"];
    if(!info)
        return nil; // no info available, so we don't know if this account supports Jingle (we assume no)
    
    if(![info containsFeature:@"http://jabber.org/protocol/jingle"])
        return nil; // jingle not supported
    
    NSMutableArray *menuItems = [NSMutableArray array];
    
    NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Invite to Audio Chat","Invite to Audio Chat (Jingle)")
                                                   action:@selector(inviteToAudioChat:) keyEquivalent:@""];
    [mitem setTarget:self];
    [mitem setRepresentedObject:inContact];
    [menuItems addObject:mitem];
    [mitem release];
    
    return menuItems;
}

- (void)inviteToAudioChat:(NSMenuItem*)sender
{
    AIListContact *contact = [sender representedObject];

    // meta contact magic, will hopefully be fixed before 1.1 is released
    while([contact conformsToProtocol:@protocol(AIContainingObject)])
        contact = [contact preferredContact];
    if(!contact)
        return; // not online?

    [self establishOutgoingJingleSessionTo:[contact UID]];
}

@end

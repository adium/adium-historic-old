

#import "SmackJinglePlugin.h"
#import "AIAdium.h"
#import "AIInterfaceController.h"

#import <AIUtilities/AIStringUtilities.h>
#import <JavaVM/NSJavaVirtualMachine.h>

#import "ESTextAndButtonsWindowController.h"

#import "SmackXMPPAccount.h"
#import "SmackInterfaceDefinitions.h"
#import "SmackCocoaAdapter.h"

#import "AIVideoConf.h"
#import "AIVideoConfControllerProtocol.h"
#import "AIVideoConfController.h"

#define	DISCO_JINGLE_ID							@"http://jabber.org/protocol/jingle"
#define	DISCO_JINGLE_AUDIO_ID					@"http://jabber.org/protocol/jingle/audio"

#define CLASSNAME_JINGLE_SESSION_LISTENER		@"net.adium.smackBridge.SmackXMPPJingleListener$Session"
#define CLASSNAME_JINGLE_SESSION_REQ_LISTENER	@"net.adium.smackBridge.SmackXMPPJingleListener$SessionRequest"

#define CLASSNAME_PAYLOADTYPE					@"org.jivesoftware.smackx.jingle.PayloadType"
#define CLASSNAME_PAYLOADTYPE_AUDIO				@"org.jivesoftware.smackx.jingle.PayloadType$Audio"
#define CLASSNAME_CONTENTINFO_AUDIO				@"org.jivesoftware.smackx.jingle.ContentInfo$Audio"


#define JINGLE_JAR								@"smackx-jingle"

static JavaClassLoader *classLoader = nil;

////////////////////////////////////////////////////////////////////////////////
//                           Jingle Listeners
////////////////////////////////////////////////////////////////////////////////

@interface SmackXJingleSessionReqListener : NSObject {
}
+ (SmackXJingleSessionReqListener*) getInstance;

- (SmackXJingleManager*) getManager;
@end


@interface SmackXJingleSessionListener : NSObject {
}
+ (SmackXJingleSessionListener*) getInstance;
@end

////////////////////////////////////////////////////////////////////////////////
//                           Jingle plugin category
////////////////////////////////////////////////////////////////////////////////

@interface SmackCocoaAdapter (jinglePlugin)

+ (void) loadJingle;

+ (SmackXJingleSessionListener*) createJingleSessionListenerForSession:(SmackXJingleSession*)session
															 delegate:(id)delegate;

+ (SmackXJingleSessionReqListener*) createJingleSessionReqListenerForConnection:(SmackXMPPConnection*)conn
																	   delegate:(id)delegate;

+ (SmackXJingleContentInfoAudio*) contentInfoAudioWithName:(NSString *)name;

+ (SmackXPayloadType*) payloadTypeWithId:(int) ident
									name:(NSString *) name
								channels:(int) channels;

+ (SmackXPayloadTypeAudio*) payloadTypeAudioWithId:(int) ident
											  name:(NSString *) name
										  channels:(int) channels
										 clockRate:(int) clockRate;

@end


@implementation SmackCocoaAdapter (jinglePlugin)

/*!
 *	@brief	Load the Jingle extension
 */
+ (void) loadJingle
{
    if (!classLoader) {
        NSString *jingleJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:JINGLE_JAR
                                                                                   ofType:@"jar"
                                                                              inDirectory:@"Java"];
        classLoader = [[[[AIObject sharedAdiumInstance] javaController] classLoaderWithJARs:[NSArray arrayWithObject:jingleJarPath]
																		  parentClassLoader:[self classLoader]] retain];
    }
}

/*!
 *	@brief	Create a jingle session listener
 */
+ (SmackXJingleSessionListener*) createJingleSessionListenerForSession:(SmackXJingleSession*)session
															  delegate:(id)delegate
{
    return [[[self classLoader] loadClass:CLASSNAME_JINGLE_SESSION_LISTENER] getInstance:session :delegate :classLoader];	
}


/*!
 *	@brief	Create a jingle session request listener
 */
+ (SmackXJingleSessionReqListener*) createJingleSessionReqListenerForConnection:(SmackXMPPConnection*)conn
																	   delegate:(id) delegate
{
    return [[[self classLoader] loadClass:CLASSNAME_JINGLE_SESSION_REQ_LISTENER] getInstance:conn :delegate :classLoader];
}

/*!
 *	@brief	Create an audio content info message
 */
+ (SmackXJingleContentInfoAudio*) contentInfoAudioWithName:(NSString *)name
{
    return [[[classLoader loadClass:CLASSNAME_CONTENTINFO_AUDIO] newWithSignature:@"(Ljava/lang/String;)",name] autorelease];	
}

/*!
 *	@brief	Create a payload type
 */
+ (SmackXPayloadType*) payloadTypeWithId:(int) ident
									name:(NSString *) name
								channels:(int) channels
{
	return [[[classLoader loadClass:CLASSNAME_PAYLOADTYPE] newWithSignature:@"(ILjava/lang/String;I)",ident,name,channels] autorelease];
}

/*!
 *	@brief	Create an audio payload type
 */
+ (SmackXPayloadTypeAudio*) payloadTypeAudioWithId:(int) ident
											  name:(NSString *) name
										  channels:(int) channels
										 clockRate:(int) clockRate
{	
	return [[[classLoader loadClass:CLASSNAME_PAYLOADTYPE_AUDIO] newWithSignature:@"(ILjava/lang/String;II)",ident,name,channels,clockRate] autorelease];
}

@end




@implementation SmackJinglePlugin

// Content Info Messages
static SmackXJingleContentInfoAudio	*contentInfoBusy	= nil;
static SmackXJingleContentInfoAudio	*contentInfoHold	= nil;
static SmackXJingleContentInfoAudio	*contentInfoMute	= nil;
static SmackXJingleContentInfoAudio	*contentInfoQueued	= nil;
static SmackXJingleContentInfoAudio	*contentInfoRinging	= nil;

static NSDictionary	*audioSessions;

////////////////////////////////////////////////////////////////////////////////
#pragma mark                 Discovery Information
////////////////////////////////////////////////////////////////////////////////
/*!
 * @brief Add the disco features for Jingle
 */
- (void) addDiscoInfo
{
	SmackXServiceDiscoveryManager *sdm;
	
	sdm = [SmackCocoaAdapter serviceDiscoveryManagerForConnection:[account connection]];
	
    if (![sdm includesFeature:DISCO_JINGLE_ID])
        [sdm addFeature:DISCO_JINGLE_ID];
	
    if (![sdm includesFeature:DISCO_JINGLE_AUDIO_ID])
        [sdm addFeature:DISCO_JINGLE_AUDIO_ID];
}

/*!
 * @brief Remove the disco features for Jingle
 */
- (void) removeDiscoInfo
{
	[[SmackCocoaAdapter serviceDiscoveryManagerForConnection:[account connection]] removeFeature:DISCO_JINGLE_ID];
	[[SmackCocoaAdapter serviceDiscoveryManagerForConnection:[account connection]] removeFeature:DISCO_JINGLE_AUDIO_ID];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark                    Initialization
////////////////////////////////////////////////////////////////////////////////

- (id) initWithAccount:(SmackXMPPAccount*) acc
{
    if ((self = [super init])) {
        account = acc;

        [SmackCocoaAdapter loadJingle];

		// Create the list of sessions
		audioSessions = [NSDictionary dictionary];
		
		// Create the static content info messages
		contentInfoBusy		= [SmackCocoaAdapter contentInfoAudioWithName:@"busy"];
		contentInfoHold		= [SmackCocoaAdapter contentInfoAudioWithName:@"hold"];
		contentInfoMute		= [SmackCocoaAdapter contentInfoAudioWithName:@"mute"];
		contentInfoQueued	= [SmackCocoaAdapter contentInfoAudioWithName:@"queued"];
		contentInfoRinging	= [SmackCocoaAdapter contentInfoAudioWithName:@"ringing"];
    }
	
    return self;
}

- (void) dealloc
{
	[self removeDiscoInfo];
    [listener release];
    [super dealloc];
}

- (void) connected:(SmackXMPPConnection*) connection
{
    listener = [[SmackCocoaAdapter createJingleSessionReqListenerForConnection:[account connection]
																	  delegate:self] retain];
	[self addDiscoInfo];
}

- (void) disconnected:(SmackXMPPConnection*) connection
{
	[self removeDiscoInfo];
    [listener release];
    listener = nil;
}



////////////////////////////////////////////////////////////////////////////////
#pragma mark                 Payloads Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief	Get the list of supported audio payloads
 */
- (JavaVector *) getSupportedAudioPayloads
{
    JavaVector				*payloadsJava	= [SmackCocoaAdapter vector];
	NSArray					*payloadsList	= [[adium vcController] getAudioPayloadsForProtocol:VC_RTP];
	NSEnumerator			*payloadsEnum	= [payloadsList objectEnumerator];
	VCAudioPayload			*payload;
	SmackXPayloadTypeAudio	*smackPayload;
	
	// Add the list of payloads
	while ((payload = [payloadsEnum nextObject])) {

		// Create the Smack payload
		smackPayload = [SmackCocoaAdapter payloadTypeAudioWithId:[[payload valueForKey:@"mId"] intValue]
															name:[payload valueForKey:@"mName"]
														channels:[[payload valueForKey:@"mChannels"] intValue]
													   clockRate:[[payload valueForKey:@"mClockrate"] intValue]];
		
		// Add it to the list
		[payloadsJava add:smackPayload];
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
	int							 payloadsCount	= [payloadTypes size];
	SmackXJingleSessionRequest	*request		= info;	
	AITextAndButtonsReturnCode	 result			= [number intValue];

	switch (result) {

		case AITextAndButtonsDefaultReturn:
			NSLog (@"Jingle: accepting incoming session, offering %d payloads.",
				   payloadsCount);

			@try {
				if (payloadsCount > 0) {
					session = [request accept:payloadTypes];
					[session start:request];
				} else {
					NSLog (@"Jingle: no payloads to offer!.");					
				}
			} @catch (NSException *e) {
				NSLog (@"Jingle exception: %@ - %@ ", [e name], [e reason]);

				[[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Jingle Error",nil)]
											 withDescription:[e reason]
											 withWindowTitle:AILocalizedString(@"Notice",nil)
											   defaultButton:AILocalizedString(@"OK",nil)
											 alternateButton:nil
												 otherButton:nil
													  target:nil
													selector:NULL
													userInfo:nil];
			}
			break;

		case AITextAndButtonsAlternateReturn:
			NSLog (@"Jingle: rejecting incoming session.");
			[request reject];
			break;

		default:
			break;
	}
}

/*!
 * @brief    A session request is received
 *
 * A session request is received. We need to ask to the user if he/she accepts
 * the session.
 */
- (void) setSessionRequested:(SmackXJingleSessionRequest*) request
{
	NSString *question = [NSString stringWithFormat:AILocalizedString(@"Accept audio chat", nil)];
	NSString *description = [NSString stringWithFormat:AILocalizedString(@"You have been invited to an audio chat.\nDo you want to accept this invitation?", nil)];

	NSLog (@"Jingle: session request received.");
		
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
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Outgoing Sessions
////////////////////////////////////////////////////////////////////////////////

/*!
 * @brief    Start an outgoing session
 */
- (void) establishOutgoingJingleSessionTo:(NSString *)jid
{
	SmackXOutgoingJingleSession *session		= nil;
    JavaVector					*payloadTypes	= [self getSupportedAudioPayloads];
	int							 payloadsCount	= [payloadTypes size];
	SmackXJingleSessionListener	*sessionListener;

	NSLog (@"Jingle: establishing outgoing session to %@, offering %d payloads.", jid, payloadsCount);

	if (payloadsCount > 0) {
		@try {
			// Start the new session
			session = [[listener getManager] createOutgoingJingleSession:jid :payloadTypes];

			// Start the listener
			sessionListener = [[SmackCocoaAdapter createJingleSessionListenerForSession:session
																			   delegate:self] retain];

			NSLog (@"Jingle: starting session.");
			[session start:nil];
		
			// Register the session
			[audioSessions setValue:session forKey:[session getSid]];

		} @catch (NSException *e) {
			NSLog (@"Jingle: exception: %@ - %@ ", [e name], [e reason]);
			
			[[adium interfaceController] displayQuestion:[NSString stringWithFormat:AILocalizedString(@"Jingle Error",nil)]
										 withDescription:[e reason]
										 withWindowTitle:AILocalizedString(@"Jingle Exception",nil)
										   defaultButton:AILocalizedString(@"OK",nil)
										 alternateButton:nil
											 otherButton:nil
												  target:nil
												selector:NULL
												userInfo:nil];
		}		
	} else {
		NSLog (@"Jingle: no payloads available!");		
	}
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Session Events
////////////////////////////////////////////////////////////////////////////////

/*!
 *	@brief	The session has been established
 */
- (id) setSessionEstablished:(NSDictionary*) args
{
	SmackXPayloadTypeAudio		*s_pt	= [args valueForKey:@"pt"];
	SmackXTransportCandidate	*s_lc	= [args valueForKey:@"lc"];
	SmackXTransportCandidate	*s_rc	= [args valueForKey:@"rc"];
	
	NSLog (@"Jingle: session established: %@ (%@ -> %@)",
		   [s_pt getName],
		   [s_lc getIP],
		   [s_rc getIP]);

	VCAudioPayload *pt	= [VCAudioPayload createWithId:[s_pt getId]
												  name:[s_pt getName]
											  channels:[s_pt getChannels]
											 clockrate:[s_pt getClockRate]];
	VCTransport	*lc = [VCTransport createWithName:[s_lc getName]
											   ip:[s_lc getIP] port:[s_lc getPort]];
	VCTransport	*rc	= [VCTransport createWithName:[s_rc getName]
											   ip:[s_rc getIP] port:[s_rc getPort]];

	// Ok, we have a connection established: start the RTP connection!
	[[adium vcController] createConnectionWithProtocol:VC_RTP
											   payload:pt
												  from:lc
													to:rc];
	
	//XXX added blindly by evands - matches setSessionDeclined, though.
	return self;
}

/*!
 *	@brief	The session has been declined
 */
- (id) setSessionDeclined:(NSString *) reason
{
	NSLog (@"Jingle: session declined with reason %@", reason);

	[[adium interfaceController] handleMessage:@"Audio session declined"
							   withDescription:reason
							   withWindowTitle:@"Audio session declined"];	

	return self;
}

/*!
 *	@brief	The session has been closed
 */
- (id) setSessionClosed:(NSString *) reason
{
	NSLog (@"Jingle: session closed with reason %@", reason);

	return self;
}

/*!
 *	@brief	The session has been closed with an error
 */
- (id) setSessionClosedOnError:(NSException*) exc
{
	NSLog (@"Jingle: session closed on error with reason %@", [exc reason]);

	[[adium interfaceController] handleMessage:@"Audio session error"
							   withDescription:[exc reason]
							   withWindowTitle:@"Audio session error"];

	return self;
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark                     Menu Management
////////////////////////////////////////////////////////////////////////////////

/*!
 * Add a menu item to the contact's context menu, so an outgoing session can
 * be established.
 */
- (NSArray *) menuItemsForContact:(AIListContact *) inContact {
    NSMutableArray		*menuItems	= [NSMutableArray array];
    SmackXDiscoverInfo	*info		= [inContact statusObjectForKey:@"XMPP:disco#info"];
    if (!info)
        return nil; // no info available, so we don't know if this account supports Jingle (we assume no)
    
    if ([info containsFeature:@"http://jabber.org/protocol/jingle/audio"]) {
		NSLog (@"Jingle: user supports audio.");

		NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Invite to Audio Chat", nil)
													   action:@selector(inviteToAudioChat:)
												keyEquivalent:@""];
		[mitem setTarget:self];
		[mitem setRepresentedObject:inContact];
		
		[menuItems addObject:mitem];
		[mitem release];		
	}

	if ([info containsFeature:@"http://jabber.org/protocol/jingle/video"]) {
		NSLog (@"Jingle: user supports video.");
		
//		NSMenuItem *mitem = [[NSMenuItem alloc] initWithTitle:AILocalizedString(@"Invite to Audio Chat","Invite to Video Chat (Jingle)")
//													   action:@selector(inviteToVideoChat:) keyEquivalent:@""];
//		[mitem setTarget:self];
//		[mitem setRepresentedObject:inContact];
//		[menuItems addObject:mitem];
//		[mitem release];		
	}	
	
    return menuItems;
}

- (void) inviteToAudioChat:(NSMenuItem*) sender
{
    AIListContact *contact = [sender representedObject];

    // meta contact magic, will hopefully be fixed before 1.1 is released
	//XXX it just happens to be true that contacts which conform to AIContainingObject also implement preferredContact...
    while([contact conformsToProtocol:@protocol(AIContainingObject)])
        contact = [contact preferredContact];

	AILog(@"@: inviting %@ to an audio chat",self, contact);
	
    if (!contact)
        return; // not online?

    [self establishOutgoingJingleSessionTo:[contact UID]];
}

@end

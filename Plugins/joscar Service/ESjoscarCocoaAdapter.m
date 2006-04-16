//
//  ESjoscarCocoaAdapter.m
//  Adium
//
//  Created by Evan Schoenberg on 6/28/05.
//

#import "ESjoscarCocoaAdapter.h"
#import "RAFjoscarAccount.h"
#import "AIAccountController.h"
#import <JavaVM/JavaVM.h>
#import "joscarClasses.h"
#import <Adium/NDRunLoopMessenger.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/ESDebugAILog.h>
#import <Adium/AIHTMLDecoder.h>
#import <AIUtilities/AIFileManagerAdditions.h>
#import <Carbon/Carbon.h>
#import <AIUtilities/AIObjectAdditions.h>

#import "ESFileTransferController.h"pdate
#import "RAFjoscarLogHandler.h"

//#define JOSCAR_LOG_WARNING

#define OSCAR_JAR			@"oscar"
#define JOSCAR_JAR			@"joscar-0.9.4-cvs-bin"
#define JOSCAR_BRIDGE_JAR	@"joscar bridge"
#define RETROWEAVER_JAR		@"retroweaver-rt"
#define SOCKS_JAR			@"jsocks-klea"

static NDRunLoopMessenger	*mainThreadMessenger = nil;

extern CFRunLoopRef CFRunLoopGetMain(void);

NSDate* dateFromJavaDate(Date *javaDate);
Date* javaDateFromDate(NSDate *date);

OSErr FilePathToFileInfo(NSString *filePath, struct FileInfo *fInfo);

@interface ESjoscarCocoaAdapter (PRIVATE)
+ (void)prepareJavaVM;
- (void)addTimer:(NSTimer *)inTimer;
@end

@implementation ESjoscarCocoaAdapter

+ (void)initializeJavaVM
{
	[NSThread detachNewThreadSelector:@selector(prepareJavaVM)
							 toTarget:self
						   withObject:nil];
}

- (id)initForAccount:(RAFjoscarAccount *)inAccount
{
	if ((self = [super init])) {
		account = [inAccount retain];
		
		//Set up Java if necessary
		[[self class] prepareJavaVM];

		//Pass in 0 for no logging, 1 for FINE level logging, and 2 for WARNING level logging
		int logLevel = 0;

		//Do fine debugging for all debug builds
#ifdef DEBUG_BUILD
	#define JOSCAR_LOG_FINE
#endif

#ifdef JOSCAR_LOG_FINE
		AILog(@"Using Fine logging");
		logLevel = 1;
#else
	#ifdef JOSCAR_LOG_WARNING
		AILog(@"Using Warning logging");
		logLevel = 2;
	#endif
#endif
		
		joscarBridge = NewJoscarBridge(logLevel);
		
		[[joscarBridge getAdiumHandler] setOutputDestination:[[RAFjoscarLogHandler alloc] init]];
		
		[joscarBridge setDelegate:self];

		//Create a DefaultAppSession
		appSession = NewDefaultAppSession();
		
		if (!mainThreadMessenger) {
			mainThreadMessenger = [[NDRunLoopMessenger runLoopMessengerForCurrentRunLoop] retain];
		}

		accountProxy = [[mainThreadMessenger targetFromNoRunLoop:account] retain];
		selfProxy = [[mainThreadMessenger targetFromNoRunLoop:self] retain];
		joscarChatsDict = [[NSMutableDictionary alloc] init];
	}

	return self;
}

- (void)dealloc
{
	[joscarBridge setDelegate:nil];
	[joscarBridge release]; joscarBridge = nil;

	[appSession release];
	[pendingBuddyAddDict release];
	[pendingBuddyMoveDict release];

	[accountProxy release]; accountProxy = nil;
	[selfProxy release]; selfProxy = nil;
	
	[joscarChatsDict release]; joscarChatsDict = nil;
	
	[super dealloc];
}

- (AimProxyInfo *)aimProxyInfoForConfiguration:(NSDictionary *)proxyConfig
{
	AimProxyInfo		*proxyInfo = nil;
	AdiumProxyType  	proxyType = [[proxyConfig objectForKey:@"AdiumProxyType"] intValue];
	
	if (proxyType != Adium_Proxy_None) {
		NSString	*host, *username, *password;
		int			port;

		host = [proxyConfig objectForKey:@"Host"];
		port = [[proxyConfig objectForKey:@"Port"] intValue];
		username = [proxyConfig objectForKey:@"Username"];
		password = [proxyConfig objectForKey:@"Password"];
		
		switch (proxyType) {
			case Adium_Proxy_HTTP:
			case Adium_Proxy_Default_HTTP:
				proxyInfo = [AimProxyInfoClass forHttp:host :port :username :password];				
				break;
				
			case Adium_Proxy_SOCKS4:
			case Adium_Proxy_Default_SOCKS4:
				proxyInfo = [AimProxyInfoClass forSocks4:host :port];
				break;
				
			case Adium_Proxy_SOCKS5:
			case Adium_Proxy_Default_SOCKS5:
				proxyInfo = [AimProxyInfoClass forSocks5:host :port :username :password];
				break;
				
			case Adium_Proxy_None:
				//Can't get here
				break;
		}

	} else {
		proxyInfo = [AimProxyInfoClass forNoProxy];
	}
	
	return proxyInfo;
}

- (void)connectWithPassword:(NSString *)password proxyConfiguration:(NSDictionary *)proxyConfiguration
{
	AimConnectionProperties	*aimConnectionProperties;
	Screenname				*screenName;
	AimSession				*aimSession;

	//Create a Screenname
	screenName = [NewScreenname([account serversideUID]) autorelease];
		
	//Open an aimSession with the screenName; this returns an aimSession object
	aimSession = [appSession openAimSession:screenName];
	
	//Build an aimConnectionProperties object which will specify the information we need to connect
	aimConnectionProperties = [NewAimConnectionProperties(screenName, password) autorelease];
	
	//Open the aimConnection from the aimSession using the aimConnectionProperties. aimConnection is an instance variable
	[aimConnection release];
	aimConnection = [[aimSession openConnection:aimConnectionProperties] retain];

	[[aimConnection getBuddyInfoManager] addGlobalBuddyInfoListener:joscarBridge];
	[aimConnection addStateListener:joscarBridge];
	[aimConnection addOpenedServiceListener:joscarBridge];
	[[aimConnection getChatRoomManager] addListener:joscarBridge];

	[aimConnection setProxy:[self aimProxyInfoForConfiguration:proxyConfiguration]];
	//Connect!
	AILog(@"*** %@ connecting %@ with Java bridge %@ ***",appSession, screenName, joscarBridge);

	[aimConnection connect];
}

- (void)disconnect
{
	[aimConnection disconnect];
}

- (NSString *)getSecurid
{
	AILog(@"Retrieving securID for %@", account);
	return [account mainPerformSelector:@selector(getSecurid)
							returnValue:YES];
}

/*
 * @brief Login service opened
 *
 * Once the login service is open, we can set the securID provider.
 */
- (void)setLoginServiceOpened:(HashMap *)userInfo
{
	[[aimConnection getLoginService] setSecuridProvider:joscarBridge];	
}

/*
 * @brief Profile update for a contact
 */
- (void)setAwayMessage:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	NSString			*message = [userInfo get:@"Away message"];

	if (message && [message length])
		[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
					setStatusMessage:[[message copy] autorelease]];
}

- (void)setBuddyCommentChanged:(HashMap *)userInfo
{
	Buddy			*buddy = [userInfo get:@"Buddy"];
	NSString		*comment = [userInfo get:@"New Comment"];
	
	[accountProxy contactWithUID:[[[[buddy getScreenname] getNormal] copy] autorelease]
		   changedToBuddyComment:[[comment copy] autorelease]];
}

- (void)setAliasChanged:(HashMap *)userInfo
{
	Buddy			*buddy = [userInfo get:@"Buddy"];
	NSString		*alias = [userInfo get:@"Alias"];
	
	[accountProxy contactWithUID:[[[[buddy getScreenname] getNormal] copy] autorelease]
				  changedToAlias:[[alias copy] autorelease]];
}


/*
 * @brief Profile update for a contact
 */
- (void)setProfile:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	NSString			*profile = [userInfo get:@"Profile"];

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
					  setProfile:[[profile copy] autorelease]];
}

- (void)setStatusUpdate:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	BuddyInfo			*info = [userInfo get:@"BuddyInfo"];
	
	//Request the away message to go with this status update
	[[aimConnection getInfoService] requestAwayMessage:sn];
	
	NSString	*UID = [[[sn getNormal] copy] autorelease];
	
	[accountProxy contactWithUID:UID
						isOnline:[NSNumber numberWithBool:[info isOnline]]
						  isAway:[NSNumber numberWithBool:[info isAway]]
					   idleSince:dateFromJavaDate([info getIdleSince])
					 onlineSince:dateFromJavaDate([info getOnlineSince])
					warningLevel:[NSNumber numberWithInt:[info getWarningLevel]]
						  mobile:[NSNumber numberWithBool:([info isMobile] || ([UID characterAtIndex:0] == '+'))]
						 aolUser:[NSNumber numberWithBool:[info isAolUser]]];
}

- (void)setContactOnline:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	BuddyInfo			*info = [userInfo get:@"BuddyInfo"];

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
						isOnline:[NSNumber numberWithBool:[info isOnline]]];
	
	//Request the away message since the contact just signed on
	//[[aimConnection getInfoService] requestAwayMessage:sn];
}

- (void)setIncomingStatusMessage:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	BuddyInfo			*info = [userInfo get:@"BuddyInfo"];
	NSString *iTMSLink = [info getItunesUrl];
	NSString *message = [info getStatusMessage];

	if (iTMSLink)
		message = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>",iTMSLink,message];

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
				setStatusMessage:[[message copy] autorelease]];
}

/*
 * @brief The connectivity state of our account changed (DISCONNECTED, ONLINE, etc.)
 *
 * The userInfo's ErrorMessage key will have a one-word code for the error which occured. If
 * it is nil, no error occurred.
 */
- (void)setStateChange:(HashMap *)userInfo
{
	NSString		*newState = [userInfo get:@"NewState"];
	NSString		*errorMessageShort = [userInfo get:@"ErrorMessage"];
	NSString		*errorCode = [userInfo get:@"ErrorCode"];

	[accountProxy stateChangedTo:[[newState copy] autorelease]
			   errorMessageShort:[[errorMessageShort copy] autorelease]
					   errorCode:[[errorCode copy] autorelease]];
}

/*
 * @brief A buddy was added
 *
 * Called retroactively for each buddy in our list after we connect
 */
- (void)setBuddyAdded:(HashMap *)userInfo
{
	Buddy			*buddy = [userInfo get:@"Buddy"];
	Group			*group = [userInfo get:@"Group"];	
	Screenname		*sn = [buddy getScreenname];

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
					formattedUID:[[[sn getFormatted] copy] autorelease]
						   alias:[[[buddy getAlias] copy] autorelease]
						 comment:[[[buddy getBuddyComment] copy] autorelease]
					addedToGroup:[[[group getName] copy] autorelease]];
}

/*
 * @brief A buddy was removed
 */
- (void)setBuddyRemoved:(HashMap *)userInfo
{
	Buddy			*buddy = [userInfo get:@"Buddy"];
	Group			*group = [userInfo get:@"Group"];	
	Screenname		*sn = [buddy getScreenname];

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
				removedFromGroup:[[[group getName] copy] autorelease]];
}

- (void)setIconUpdate:(HashMap *)userInfo
{
	Screenname			*sn = [userInfo get:@"Screenname"];
	BuddyInfo			*info = [userInfo get:@"BuddyInfo"];
	NSData				*iconData = [NSData dataWithData:[joscarBridge dataFromByteBlock:[info getIconData]]];

	AILog(@"+++ Icon update for %@ is %@",[sn getNormal],[[[NSImage alloc] initWithData:iconData] autorelease]);

	[accountProxy contactWithUID:[[[sn getNormal] copy] autorelease]
					  iconUpdate:iconData];
}


#pragma mark Messaging
- (NSString *)processOutgoingMessage:(NSString *)message /*toUID:(NSString *)inUID*/ joscarData:(id *)outJoscarData
{
	//Do nothing if there are no <img> tags in message
	if ([message rangeOfString:@"<img" options:NSCaseInsensitiveSearch].location == NSNotFound) {
		if (outJoscarData != NULL) *outJoscarData = nil;

		return message;
	}

	NSCharacterSet		*elementEndCharacters = [NSCharacterSet characterSetWithCharactersInString:@" >"];
	NSString			*chunkString;
	NSMutableString		*processedString;
	NSMutableSet		*attachmentsSet = nil;
	NSScanner			*scanner;
	int					imageID = 1;

    scanner = [NSScanner scannerWithString:message];
	[scanner setCaseSensitive:NO];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	processedString = [[NSMutableString alloc] init];
	
    //Parse the HTML
    while (![scanner isAtEnd]) {
        //Find an HTML IMG tag
        if ([scanner scanUpToString:@"<img" intoString:&chunkString]) {
			//Append the text leading up the the IMG tag; a directIM may have image tags inline with message text
            [processedString appendString:chunkString];
        }
		
        //Look for the start of a tag
        if ([scanner scanString:@"<" intoString:nil]) {
			//Get the tag itself
			if ([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]) {
				if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
					if ([scanner scanUpToString:@">" intoString:&chunkString]) {
						//Load the src image
						NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];

						NSString		*source, *altName, *identifier;
						NSImage			*image;
						NSData			*imageData;
						NSSize			imageSize;
						File			*file;
						FileAttachment	*fileAttachment;
						unsigned		dataLength;
						
						source = [[NSURL URLWithString:[imgArguments objectForKey:@"src"]] path];
						altName = [imgArguments objectForKey:@"alt"];

						imageData = [[NSData alloc] initWithContentsOfFile:source];
						image = [[NSImage alloc] initWithData:imageData];
						dataLength = [imageData length];
						[imageData release];

						imageSize = [image size];
						[image release];

						identifier = [NSString stringWithFormat:@"%i", imageID++];

						file = NewFile(source);
						fileAttachment = [NewFileAttachment(file, identifier, (long long)dataLength) autorelease];
						[file release];

						//Only add the srcTag if we have an altName with which to work
						NSString *srcTag = (altName ? [NSString stringWithFormat:@"SRC=\"%@\" ", altName] : @"");
	
						//
						NSString *newTag;

						newTag = [NSString stringWithFormat:@"<IMG %@ ID=\"%@\" WIDTH=\"%i\" HEIGHT=\"%i\" DATASIZE=\"%u\">",
							srcTag, identifier,
							(int)imageSize.width, (int)imageSize.height,
							dataLength];
						[processedString appendString:newTag];
						
						if (!attachmentsSet) attachmentsSet = [[[NSMutableSet alloc] init] autorelease];
						[attachmentsSet addObject:fileAttachment];
						[fileAttachment release];
					}
				}
				
				if (![scanner isAtEnd]) {
					[scanner setScanLocation:[scanner scanLocation]+1];
				}
			}
		}
	}
	
	if ((attachmentsSet != nil) && (outJoscarData != NULL)) {
		*outJoscarData = attachmentsSet;
		NSLog(@"Attachments: %@",attachmentsSet);
	}

	return [processedString autorelease];
}

/*
 * @brief A directIM conversation was established
 */
- (void)setOpenedDirectIMConversation:(HashMap *)userInfo
{
	DirectimConversation	*conversation = [userInfo get:@"DirectimConversation"];
	Screenname				*sn = [conversation getBuddy];
	NSString				*inUID = [sn getNormal];

	NSLog(@"Opened direct IM with %@",inUID);
}

/*
 * @brief A directIM conversation was closed
 */
- (void)setClosedDirectIMConversation:(HashMap *)userInfo
{
	DirectimConversation	*conversation = [userInfo get:@"DirectimConversation"];
	Screenname				*sn = [conversation getBuddy];
	
	NSLog(@"Closed direct IM with %@",[sn getNormal]);
}

/*
 * @brief Send a message to a one-on-one chat
 */
- (BOOL)chatWithUID:(NSString *)inUID sendMessage:(NSString *)message isAutoreply:(BOOL)isAutoreply joscarData:(NSSet *)attachmentsSet
{
	Screenname			*sn = [NewScreenname(inUID) autorelease];
	Message				*msg;

	if (attachmentsSet) {
		HashSet *attachmentsHashSet = NewHashSet([attachmentsSet count]);
		
		//Add each Attachment in attachmentsSet to the HashSet we'll pass to joscar
		NSEnumerator *enumerator;
		Attachment	 *attachment;
		
		enumerator = [attachmentsSet objectEnumerator];
		while ((attachment = [enumerator nextObject])) {
			[attachmentsHashSet add:attachment];
		}
		
		//Create the DirectMessage
		msg = [NewDirectMessage(message, isAutoreply, attachmentsHashSet) autorelease];
		[attachmentsHashSet release];

	} else {
		msg = [NewBasicInstantMessage(message,
									  isAutoreply) autorelease];		
	}
	
	[[aimConnection getIcbmService] sendAutomatically:sn :msg];
	
	return YES;
}

/*
 * @brief Send a typing state to a one-on-one chat
 */
- (void)chatWithUID:(NSString *)inUID setTypingState:(AITypingState)typingState
{
	Screenname			*sn = [NewScreenname(inUID) autorelease];
	ImConversation		*conversation = [[aimConnection getIcbmService] getImConversation:sn];
	TypingState			*joscarTypingState;

	switch (typingState) {
		case AITyping:
			joscarTypingState = [joscarBridge typingStateFromString:@"TYPING"];
			break;
		case AIEnteredText:
			joscarTypingState = [joscarBridge typingStateFromString:@"PAUSED"];
			break;
		case AINotTyping:
		default:
			joscarTypingState = [joscarBridge typingStateFromString:@"NO_TEXT"];
			break;				
	}
	
	/* Send typing */
	[conversation setTypingState:joscarTypingState];
}

/*
 * @brief Process an incoming DirectIM message for its embedded img tags
 *
 * Such tags should have the Attachments handled with an end result of an image file on disk and the <img>
 * tag replaced with one whose src= points to that image.
 *
 * @param message The HTML message we received
 * @param directMessage A DirectMessage which was sent to the account by -[self setGotMessage:] below and then back to us
 */
- (NSString *)processIncomingDirectMessage:(NSString *)message joscarData:(id)directMessage
{
	//Do nothing if there are no <img> tags
	if ([message rangeOfString:@"<img" options:NSCaseInsensitiveSearch].location == NSNotFound) {
		return message;
	}
	
	NSScanner			*scanner;
    NSString			*chunkString = nil;
    NSMutableString		*processedString;
	NSCharacterSet		*elementEndCharacters = [NSCharacterSet characterSetWithCharactersInString:@" >"];

    //set up
	scanner = [NSScanner scannerWithString:message];
	[scanner setCaseSensitive:NO];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	processedString = [[NSMutableString alloc] init];
	
	NSObject<Set> *attachmentsSet = [(DirectMessage *)directMessage getAttachments];

    //Parse the HTML
    while (![scanner isAtEnd]) {
        //Find an HTML IMG tag
        if ([scanner scanUpToString:@"<img" intoString:&chunkString]) {
			//Append the text leading up the the IMG tag; a directIM may have image tags inline with message text
            [processedString appendString:chunkString];
        }
		
        //Look for the start of a tag
        if ([scanner scanString:@"<" intoString:nil]) {
			//Get the tag itself
			if ([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]) {
				if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
					if ([scanner scanUpToString:@">" intoString:&chunkString]) {
						//Load the src image
						NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];
						NSLog(@"%@ gives arguments %@",chunkString, imgArguments);
						
						NSString		*name, *identifier;
						NSString		*imagePath = nil;
						
						identifier = [imgArguments objectForKey:@"id"];
						name = [imgArguments objectForKey:@"src"];

						if(!name) name = @"Received Image";

						id<Iterator>	iterator = [attachmentsSet iterator];
						Attachment		*attachment;
						
						while (!imagePath && 
							   [iterator hasNext] && (attachment = (Attachment *)[iterator next])) {
							NSLog(@"Looking for %@; Attachment %@ has ID %@",identifier, attachment, [attachment getId]);
							if ([identifier isEqualToString:[attachment getId]]) {
								//Found the right attachment
								if ([attachment isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.icbm.dim.FileAttachment")]) {
									//If it's already on disk, get the path
									imagePath = [[(FileAttachment *)attachment getFile] getCanonicalPath];
								} else {					
									//If it is not on disk, write it out so we can use it
									imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
									imagePath = [[NSFileManager defaultManager] uniquePathForPath:imagePath];
									[[joscarBridge dataFromAttachment:attachment] writeToFile:imagePath atomically:YES];
								}
							}
						}
						
						//Append the tag; the 'scaledToFitImage' class lets us apply CSS to directIM images only
						[processedString appendString:[NSString stringWithFormat:@"<IMG CLASS=\"scaledToFitImage\" SRC=\"%@\" ALT=\"%@\">",imagePath, name]];
					}
				}
				
				if (![scanner isAtEnd]) {
					[scanner setScanLocation:[scanner scanLocation]+1];
				}
			}
		}
	}

	return ([processedString autorelease]);
}

/*
 * @brief Received a message in a conversation
 */
- (void)setGotMessage:(HashMap *)userInfo
{	
	Conversation	*conversation = [userInfo get:@"Conversation"];
	MessageInfo		*messageInfo = [userInfo get:@"MessageInfo"];
	Message			*message = [messageInfo getMessage];
	NSString		*messageBody = [[[message getMessageBody] copy] autorelease];
	NSNumber		*isAutoResponse = [NSNumber numberWithBool:[message isAutoResponse]];
	Screenname		*sn = [conversation getBuddy];

	NSString		*UID = [[[sn getNormal] copy] autorelease];

	if ([message isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.icbm.DirectMessage")]) {
			[accountProxy chatWithUID:UID
				receivedDirectMessage:messageBody
						  isAutoreply:isAutoResponse
						   joscarData:message];

	} else {
		[accountProxy chatWithUID:UID
				  receivedMessage:messageBody
					  isAutoreply:isAutoResponse];
	}		
}

/*
 * @brief Received a typing update for a conversation
 */
- (void)setGotTypingState:(HashMap *)userInfo
{	
	Conversation	*conversation = [userInfo get:@"Conversation"];
	TypingInfo		*typingInfo = [userInfo get:@"TypingInfo"];
	TypingState		*joscarTypingState = [typingInfo getTypingState];
	Screenname		*sn = [conversation getBuddy];
	AITypingState	typingState;
	
	if ([[joscarTypingState name] isEqualToString:@"PAUSED"])
		typingState = AIEnteredText;
	else if ([[joscarTypingState name] isEqualToString:@"TYPING"])
		typingState = AITyping;
	else
		typingState = AINotTyping;
	
	[accountProxy chatWithUID:[[[sn getNormal] copy] autorelease]
			   gotTypingState:[NSNumber numberWithInt:typingState]];
}

- (void)setMissedMessages:(HashMap *)userInfo
{
	ImConversation	*conversation = [userInfo get:@"ImConversation"];
	MissedImInfo	*missedImInfo = [userInfo get:@"MissedImInfo"];
	Screenname		*sn = [conversation getBuddy];
	AIChatErrorType errorType = AIChatUnknownError;
	Screenname		*imSource = [missedImInfo getFrom];
	BOOL			receiving = [imSource isEqual:sn];

	//getName returns one of @"TOO_FAST", @"TOO_LARGE", @"SENDER_WARNING_LEVEL", @"YOUR_WARNING_LEVEL"
	NSString		*imError = [[missedImInfo getReason] getName];
	if ([imError isEqualToString:@"TOO_LARGE"]) {
		errorType = (receiving ? AIChatMessageReceivingMissedTooLarge : AIChatMessageSendingTooLarge);

	} else if ([imError isEqualToString:@"TOO_FAST"]) {
		errorType = (receiving ? AIChatMessageReceivingMissedRateLimitExceeded : AIChatMessageSendingMissedRateLimitExceeded);
		
	} else if ([imError isEqualToString:@"SENDER_WARNING_LEVEL"]) {
		errorType = (receiving ? AIChatMessageReceivingMissedRemoteIsTooEvil : AIChatMessageReceivingMissedLocalIsTooEvil);

	} else if ([imError isEqualToString:@"YOUR_WARNING_LEVEL"]) {
		errorType = AIChatMessageReceivingMissedLocalIsTooEvil;
	}

	[accountProxy chatWithUID:[[[sn getNormal] copy] autorelease]
					 gotError:[NSNumber numberWithInt:errorType]];
}
				   
#pragma mark File transfer
- (void)setNewIncomingFileTransfer:(HashMap *)userInfo
{
	IncomingFileTransfer	*incomingFileTransfer = [userInfo get:@"IncomingFileTransfer"];
	
	[accountProxy newIncomingFileTransferWithUID:[[[[incomingFileTransfer getBuddyScreenname] getNormal] copy] autorelease]
										fileName:[[[[incomingFileTransfer getRequestFileInfo] getFilename] copy] autorelease]
										fileSize:[NSNumber numberWithLongLong:[[incomingFileTransfer getRequestFileInfo] getTotalFileSize]]
									  identifier:[NSValue valueWithPointer:incomingFileTransfer]];	
}

- (void)acceptIncomingFileTransferWithIdentifier:(NSValue *)identifier destinationPath:(NSString *)localPath
{
	IncomingFileTransfer	*incomingFileTransfer = (IncomingFileTransfer *)[identifier pointerValue];

	FileMapper *fileMapper = [NewJoscarFileMapper(NO, localPath) autorelease];
	[incomingFileTransfer setFileMapper:fileMapper];

	[incomingFileTransfer accept];
}

- (void)rejectIncomingFileTransferWithIdentifier:(NSValue *)identifier
{
	IncomingFileTransfer	*incomingFileTransfer = (IncomingFileTransfer *)[identifier pointerValue];
	[incomingFileTransfer decline];
}

- (void)cancelFileTransferWithIdentifier:(NSValue *)identifier
{
	FileTransfer	*fileTransfer = (FileTransfer *)[identifier pointerValue];
	[fileTransfer close];
}

- (void)addPaths:(NSArray *)pathArray toOutgoingFileTransfer:(OutgoingFileTransfer *)outgoingFileTransfer
{
	NSEnumerator	*enumerator;
	ArrayList		*fileList = [NewArrayList() autorelease];
	NSFileManager	*defaultManager = [NSFileManager defaultManager];
	NSString		*path;
	NSString		*commonPrefix = nil;

	//Build an ArrayList
	enumerator = [pathArray objectEnumerator];
	while ((path = [enumerator nextObject])) {		
		BOOL	isDir;

		if ([defaultManager fileExistsAtPath:path isDirectory:&isDir] &&
			!isDir) {
			//Looking at a file, add it directly
			[fileList add:[NewFile(path) autorelease]];

		} else {
			//Looking at a directory
			NSDirectoryEnumerator	*pathEnumerator = [defaultManager enumeratorAtPath:path];
			NSString				*filename;
			
			while ((filename = [pathEnumerator nextObject])) {
				//Only add regular files
				if ([[[pathEnumerator fileAttributes] objectForKey:NSFileType] isEqualToString:NSFileTypeRegular]) {
					[fileList add:[NewFile([path stringByAppendingPathComponent:filename]) autorelease]];
				}
			}
		}
		
		if (!commonPrefix) {
			commonPrefix = path;
		} else {
			commonPrefix = [commonPrefix commonPrefixWithString:path options:NSLiteralSearch];
		}
	}

	/**
	 * documentation for addFilesInHierarchy:
	 * Adds each file in {@code files} under the given {@code root}. Each file
	 * will be sent with its full relative path from the {@code root}, not
	 * including the {@code root}'s name, but prefixed with the {@code folderName}.
	 *
	 * For example, calling this method with folderName of "cool", root
	 * "/home/klea/xyz", and files "/home/klea/xyz/file1" &amp;
	 * "/home/klea/xyz/dir/file2", will produce {@code TransferredFile}s with
	 * paths of "cool/file1" and "cool/dir/file2".
	 */
	if ([pathArray count] == 1) {
		//Sending one folder; its name is our root we'll send to the remote contact
		NSLog(@"Sending %@ with name %@ and root %@",fileList, [[pathArray objectAtIndex:0] lastPathComponent], commonPrefix);
		[outgoingFileTransfer addFilesInHierarchy:[[pathArray objectAtIndex:0] lastPathComponent] :[NewFile(commonPrefix) autorelease] :fileList];
	} else {
		//Sending multiple files or folders; their commonality is the name we'll send to the remote contact
		NSLog(@"Sending %@ with name %@ and root %@",fileList, [commonPrefix lastPathComponent], commonPrefix);
		[outgoingFileTransfer addFilesInHierarchy:[commonPrefix lastPathComponent] :[NewFile(commonPrefix) autorelease] :fileList];		
	}
}

/*
 * @brief Begin an outgoing file transfer
 *
 * @result The identifier for the joscar outgoing file transfer
 */
- (NSValue *)initiateOutgoingFileTransferForUID:(NSString *)UID
									   forFiles:(NSArray *)pathArray;
{
	OutgoingFileTransfer	*outgoingFileTransfer;
	RvConnectionManager		*rvConnectionManager;
	Screenname				*sn = [NewScreenname(UID) autorelease];

	rvConnectionManager = [[aimConnection getIcbmService] getRvConnectionManager];
	outgoingFileTransfer = [rvConnectionManager createOutgoingFileTransfer:sn];
	
	//Add the listener for this file transfer
	[outgoingFileTransfer addEventListener:joscarBridge];
	
	if ([pathArray count] == 1) {
		NSString	*path = [pathArray objectAtIndex:0];
		BOOL		isDir;

		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] &&
			isDir) {
			[self addPaths:pathArray toOutgoingFileTransfer:outgoingFileTransfer];
		} else {
			File	*file = [NewFile(path) autorelease];
			[outgoingFileTransfer setSingleFile:file];
		}

	} else {
		[self addPaths:pathArray toOutgoingFileTransfer:outgoingFileTransfer];
	}

	[joscarBridge prepareOutgoingFileTransfer:outgoingFileTransfer];
	[NSThread detachNewThreadSelector:@selector(sendRequest:) 
							 toTarget:outgoingFileTransfer 
						   withObject:[NewInvitationMessage(NULL) autorelease]];
	return [NSValue valueWithPointer:outgoingFileTransfer];
}

- (void)setGetMacFileInfo:(HashMap *)userInfo
{
	NSString	*filePath = [userInfo get:@"FilePath"];
	struct FileInfo fInfo;
	
	if (FilePathToFileInfo(filePath, &fInfo) == noErr) {
		NSData		*fInfoData;
		ByteBlock	*fInfoByteBlock;
		void		*fInfoBytes;
		size_t		fInfoLength;
		
		fInfoLength = sizeof(fInfo);
		
		fInfoBytes = malloc(fInfoLength);
		memcpy(fInfoBytes, &fInfo, fInfoLength);
		fInfoData = [[NSData alloc] initWithBytes:fInfoBytes length:fInfoLength];
		
		fInfoByteBlock = [joscarBridge byteBlockFromData:fInfoData];
		[userInfo put:@"FInfoByteBlock" :fInfoByteBlock];
		
		[fInfoData release];
		free(fInfoBytes);
	}
}

- (void)setFileTransferUpdate:(HashMap *)userInfo
{
	FileTransfer		*fileTransfer = [userInfo get:@"FileTransfer"];
	FileTransferState	*ftState = [userInfo get:@"FileTransferState"];
	NSString			*newState = [ftState toString];
	NSDictionary		*pollingUserInfo = nil;
	NSValue				*identifier = [NSValue valueWithPointer:fileTransfer];
	FileTransferStatus	fileTransferStatus;
	BOOL				shouldPollForStatus = NO;

	NSLog(@"File transfer update: %@",userInfo);

	if ([newState isEqualToString:@"WAITING"]) {
		fileTransferStatus = Not_Started_FileTransfer;
		
	} else if ([newState isEqualToString:@"CONNECTING"]) {
		fileTransferStatus = Not_Started_FileTransfer;
		
	} else if ([newState isEqualToString:@"CONNECTED"]) {
		//XXX Adium doesn't have a state for this yet
		fileTransferStatus = Accepted_FileTransfer;
		
	} else if ([newState isEqualToString:@"TRANSFERRING"]) {
		TransferringFileEvent	*fileEvent = [userInfo get:@"FileTransferEvent"];
//		TransferredFileInfo		*fileInfo = [fileEvent getFileInfo];
		ProgressStatusProvider	*progressStatusProvider = [fileEvent getProgressProvider];
		
		fileTransferStatus = In_Progress_FileTransfer;
		shouldPollForStatus = YES;
		
		pollingUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
			identifier, @"FileTransferValue",
			progressStatusProvider, @"ProgressStatusProvider",
			nil];

	} else if ([newState isEqualToString:@"FINISHED"]) {
		fileTransferStatus = Complete_FileTransfer;

	} else if ([newState isEqualToString:@"FAILED"]) {
		fileTransferStatus = Failed_FileTransfer;

	} else if ([newState isEqualToString:@"PREPARING"]) {
		fileTransferStatus = Checksumming_Filetransfer;
	} else {
		fileTransferStatus = Unknown_Status_FileTransfer;
	}

	if (shouldPollForStatus) {
		NSTimer	*ftPollingTimer;
		
		if (!fileTransferPollingTimersDict) fileTransferPollingTimersDict = [[NSMutableDictionary alloc] init];
	
		if (!(ftPollingTimer = [fileTransferPollingTimersDict objectForKey:identifier])) {
			//Create a repeating timer if necessary
			ftPollingTimer = [NSTimer timerWithTimeInterval:0.5
													 target:self 
												   selector:@selector(fileTransferPoll:) 
												   userInfo:pollingUserInfo
													repeats:YES];
			//Add iton the main run loop
			[selfProxy addTimer:ftPollingTimer];
			
			//Keep track of it for later removal
			[fileTransferPollingTimersDict setObject:ftPollingTimer
											  forKey:identifier];
		}
	} else {
		if (fileTransferPollingTimersDict) {
			NSTimer	*ftPollingTimer;
			
			if ((ftPollingTimer = [fileTransferPollingTimersDict objectForKey:identifier])) {
				//Remove our current polling timer
				[ftPollingTimer invalidate];
				[fileTransferPollingTimersDict removeObjectForKey:identifier];
				
				//If the tracking dict is now clear, release it
				if (![fileTransferPollingTimersDict count]) {
					[fileTransferPollingTimersDict release]; fileTransferPollingTimersDict = nil;
				}
			}
		}
	}
	
	//Inform the account of the status update
	if (fileTransferStatus != Unknown_Status_FileTransfer) {
		[accountProxy updateFileTransferWithIdentifier:identifier
								  toFileTransferStatus:[NSNumber numberWithInt:fileTransferStatus]];
	}
}

/*
 * @brief Add a timer on the main run loop
 */
- (void)addTimer:(NSTimer *)inTimer
{
	[[NSRunLoop currentRunLoop] addTimer:inTimer forMode:NSDefaultRunLoopMode];
}

/*
 * @brief Called periodically (on the main thread) to update file transfer status
 */
- (void)fileTransferPoll:(NSTimer *)inTimer
{
	NSDictionary			*userInfo = [inTimer userInfo];
	NSValue					*identifier = [userInfo objectForKey:@"FileTransferValue"];
	ProgressStatusProvider	*statusProvider = [userInfo objectForKey:@"ProgressStatusProvider"];
	
	//Inform the account of the status update
	[account updateFileTransferWithIdentifier:identifier
								   toPosition:[NSNumber numberWithLongLong:[statusProvider getPosition]]];
}

#pragma mark Buddy list editing
/*
 * @brief Find a MutableGroup
 *
 * @param groupName The name of the group
 */
- (MutableGroup *)mutableGroupWithName:(NSString *)groupName
{
	MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];
	id<Iterator>		iterator = [[buddyList getGroups] iterator];
	Group				*group;
	MutableGroup		*targetGroup = nil;
	
	while ([iterator hasNext] && (group = (Group *)[iterator next])) {
		//Can be a MutableGroup or an SsiBuddyGroup (a subclass of MutableGroup) for us to add
		if ([[group getName] isEqualToString:groupName]) {
			if ([group isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.SsiBuddyGroup")] ||
				[group isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.MutableGroup")]) {
				targetGroup = (MutableGroup *)group;
				break;

			} else {
				AILog(@"%@ is of the class %@ and is not recognized as mutable",
					  group,
					  NSStringFromClass([group class]));
			}
		}
	}
	
	return targetGroup;
}

/*
 * @brief Add contacts to a group
 */
- (void)addContactsWithUIDs:(NSArray *)UIDs toGroup:(NSString *)groupName
{
	MutableGroup	*mutableGroup = [self mutableGroupWithName:groupName];
	
	if (mutableGroup) {
		NSEnumerator	*enumerator;
		NSString		*UID;
		
		enumerator = [UIDs objectEnumerator];
		while ((UID = [enumerator nextObject])) {
			[mutableGroup addBuddy:UID];
		}

	} else {
		/* We don't have a group for the move yet. We need to add it; after we are 
		* notified that it was added, we can add UIDs into it.
		*/		
		NSArray				*currentPendingArray;
		MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];

		if (!pendingBuddyAddDict) {
			//Need to create a pending add dictionary
			pendingBuddyAddDict = [[NSMutableDictionary alloc] init];
		} else {
			//Get any already-pending buddies (wow, must be a really fast user... or a really slow connection)
			if ((currentPendingArray = [pendingBuddyMoveDict objectForKey:groupName])) {
				UIDs = [UIDs arrayByAddingObjectsFromArray:currentPendingArray];
			}
		}
		
		[pendingBuddyAddDict setObject:UIDs
								 forKey:groupName];
		[buddyList addGroup:groupName];
	}
}

/*
 * @brief Remove contacts from the buddy list
 */
- (void)removeContactsWithUIDs:(NSArray *)UIDs
{
	MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];
	id<Iterator>		iterator = [[buddyList getGroups] iterator];
	Group				*group;
	
	//Look at every group
	while ([iterator hasNext] && (group = (Group *)[iterator next])) {
		//Can be a MutableGroup or an SsiBuddyGroup (a subclass of MutableGroup) for us to delete
		if ([group isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.SsiBuddyGroup")] ||
			[group isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.MutableGroup")]) {
			id<Iterator>		iterator = [[group getBuddiesCopy] iterator];
			Buddy				*buddy;
			
			//Look at every buddy in this group
			while ([iterator hasNext] && (buddy = (Buddy *)[iterator next])) {
				//If we've found a buddy we should remove, delete it
				if ([UIDs indexOfObject:[[buddy getScreenname] getNormal]] != NSNotFound) {
					[(MutableGroup *)group deleteBuddy:buddy];
				}
			}				
		}
	}
}

/*
 * @brief Move contacts into a group
 */
- (void)moveContactsWithUIDs:(NSArray *)UIDs toGroup:(NSString *)groupName
{
	MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];
	id<Iterator>		groupsIterator = [[buddyList getGroups] iterator];
	Group				*group;
	MutableGroup		*mutableGroup = [self mutableGroupWithName:groupName];
	ArrayList			*listOfBuddies = [NewArrayList() autorelease];

	while ([groupsIterator hasNext] && (group = (Group *)[groupsIterator next])) {
		//Check to see if this group has any of the buddies we are moving
		id<Iterator>		buddiesIterator = [[group getBuddiesCopy] iterator];
		Buddy				*buddy;
		
		//Look at every buddy in this group
		while ([buddiesIterator hasNext] && (buddy = (Buddy *)[buddiesIterator next])) {
			//If we've found a buddy we should remove, delete it
			if ([UIDs indexOfObject:[[buddy getScreenname] getNormal]] != NSNotFound) {
				[listOfBuddies add:buddy];
			}
		}
	}
	
	if (mutableGroup) {
		//Found our target group. Move the buddies immediately.
		[buddyList moveBuddies:listOfBuddies
							  :mutableGroup];
		
	} else {
		ArrayList	*currentPendingList;

		/* We don't have a group for the move yet. We need to add it; after we are 
		 * notified that it was added, we can move listOfBuddies into it.
		 */
		if (!pendingBuddyMoveDict) {
			pendingBuddyMoveDict = [[NSMutableDictionary alloc] init];
		} else {
			//Get any already-pending buddies (wow, must be a really fast user... or a really slow connection)
			if ((currentPendingList = [pendingBuddyMoveDict objectForKey:groupName])) {
				[listOfBuddies addAll:currentPendingList];
			}
		}

		[pendingBuddyMoveDict setObject:listOfBuddies
								 forKey:groupName];
		[buddyList addGroup:groupName];
	}
}

/*
 * @brief A Group was added
 *
 * We only care about this notification when the group was added in response to moving or adding a buddy
 * into a non-existant group.  Once the group is created, we use our tracking dictionaries, pendingBuddyAddDict and
 * pendingBuddyMoveDict, to complete the operation.
 */
- (void)setGroupAdded:(HashMap *)userInfo
{
	//Check to see if we have any pending move or add operations for this newly created group
	if (pendingBuddyMoveDict || pendingBuddyAddDict) {
		Group	*group = [userInfo get:@"Group"];
		NSString	*groupName = [group getName];
		NSArray		*pendingUIDsToAdd;
		ArrayList	*pendingBuddiesToMove;
		
		if ((pendingUIDsToAdd = [pendingBuddyAddDict objectForKey:groupName])) {
			//Add the contacts
			[self addContactsWithUIDs:pendingUIDsToAdd
							  toGroup:groupName];
			
			//Remove this pending entry
			[pendingBuddyAddDict removeObjectForKey:groupName];
			
			//Release the dict if it is no longer needed
			if (![pendingBuddyAddDict count]) {
				[pendingBuddyAddDict release]; pendingBuddyAddDict = nil;
			}
		}
		
		if ((pendingBuddiesToMove = [pendingBuddyMoveDict objectForKey:groupName])) {
			MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];
			MutableGroup		*mutableGroup = [self mutableGroupWithName:groupName];

			if (mutableGroup) {
				//Move the buddies
				[buddyList moveBuddies:pendingBuddiesToMove
									  :mutableGroup];
				
				//Remove this pending entry
				[pendingBuddyMoveDict removeObjectForKey:groupName];
				
				//Release the dict if it is no longer needed
				if (![pendingBuddyMoveDict count]) {
					[pendingBuddyMoveDict release]; pendingBuddyMoveDict = nil;
				}				
			}
		}
	}
}

#pragma mark Contact info
/*
 * @brief Find a MutableBuddy
 *
 * @param buddyName The name of the buddy
 */
- (MutableBuddy *)mutableBuddyWithName:(NSString *)buddyName
{
	MutableBuddyList	*buddyList = [[aimConnection getSsiService] getBuddyList];
	id<Iterator>		iterator = [[buddyList getGroups] iterator];
	Group				*group;
	MutableBuddy		*targetBuddy = nil;
	
	while (!targetBuddy && [iterator hasNext] && (group = (Group *)[iterator next])) {
		id<Iterator> groupIterator = [[group getBuddiesCopy] iterator];
		Buddy		*buddy;
		
		while ([groupIterator hasNext] && (buddy = (Buddy *)[groupIterator next])) {
			if ([[[buddy getScreenname] getNormal] isEqualToString:buddyName]) {
				if ([buddy isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.SsiBuddy")] ||
					[buddy isKindOfClass:NSClassFromString(@"net.kano.joustsim.oscar.oscar.service.ssi.MutableBuddy")]) {
					targetBuddy = (MutableBuddy *)buddy;
					break;					
				} else {
					AILog(@"%@ is of the class %@ and is not recognized as mutable",
						  buddy,
						  NSStringFromClass([buddy class]));
				}
			}
		}
	}
	
	return targetBuddy;
}

- (void)requestInfoForContactWithUID:(NSString *)UID
{
	Screenname	*sn = [NewScreenname(UID) autorelease];

	//Request the profile
	[[aimConnection getInfoService] requestUserProfile:sn];	
}

- (void)setAlias:(NSString *)inAlias forContactWithUID:(NSString *)UID
{
	[[self mutableBuddyWithName:UID] changeAlias:inAlias];
}

- (void)setNotes:(NSString *)inNotes forContactWithUID:(NSString *)UID
{
	[[self mutableBuddyWithName:UID] changeBuddyComment:inNotes];
}

#pragma mark Profile and Status
- (void)setUserProfile:(NSString *)profile
{
	[[aimConnection getInfoService] setUserProfile:profile];
}

- (void)setMessageAway:(NSString *)awayMessage
{
	/* DO NOT prevent sending null messages to the infoService
	 * sending a null pointer is how you clear the away state
	 */
	[[aimConnection getInfoService] setAwayMessage:awayMessage];
}

- (void)setIdleSince:(NSDate*)date
{
	[[aimConnection getBosService] setIdleSince:javaDateFromDate(date)];
}

- (void)setUnidle
{
	[[aimConnection getBosService] setUnidle];
}

- (void)setVisibleStatus:(BOOL)visible
{
	[[aimConnection getBosService] setVisibleStatus:visible];
}

- (void)setStatusMessage:(NSString *)msg
{
	[[aimConnection getBosService] setStatusMessage:msg];
}

- (void)setStatusMessage:(NSString *)msg withSongURL:(NSString *)itmsURL
{
	[[aimConnection getBosService] setStatusMessageSong:msg :itmsURL];
}


- (void)setAccountUserIconData:(NSData *)data
{
	NSLog(@"%@: setAccountUserIconData",self);

	if (data) {
		///ByteBlock from data
		[[aimConnection getMyBuddyIconManager] requestSetIcon:[joscarBridge byteBlockFromData:data]];

	} else {
		[[aimConnection getMyBuddyIconManager] requestClearIcon];
	}
}

#pragma mark Privacy functions

- (NSArray *)getBlockedBuddies
{
	id<Iterator> iter = [[[[aimConnection getSsiService] getPermissionList] getBlockedBuddies] iterator];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	while ([iter hasNext]) {
		Screenname *name = (Screenname *) [iter next];
		[array addObject:[name getNormal]];
	}
	return [array autorelease];
}

- (PRIVACY_OPTION)privacyMode
{	
	NSString *mode = [[[[aimConnection getSsiService] getPermissionList] getPrivacyMode] name];
	PRIVACY_OPTION prvType = PRIVACY_ALLOW_ALL;
	if ([mode isEqualToString:@"ALLOW_ALLOWED"])
		prvType = PRIVACY_ALLOW_USERS;
	if ([mode isEqualToString:@"BLOCK_ALL"])
		prvType = PRIVACY_DENY_ALL;
	if ([mode isEqualToString:@"BLOCK_BLOCKED"])
		prvType = PRIVACY_DENY_USERS;
	if ([mode isEqualToString:@"ALLOW_BUDDIES"])
		prvType = PRIVACY_ALLOW_CONTACTLIST;
	return prvType;
}

- (NSArray *)getAllowedBuddies
{
	id<Iterator> iter = [[[[aimConnection getSsiService] getPermissionList] getAllowedBuddies] iterator];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	while ([iter hasNext]) {
		Screenname *name = (Screenname *) [iter next];
		[array addObject:[name getNormal]];
	}
	return [array autorelease];
}

- (NSObject<Set> *)getEffectiveBlockedBuddies
{
	id<Iterator> iter = [[[[aimConnection getSsiService] getPermissionList] getEffectiveBlockedBuddies] iterator];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	while ([iter hasNext]) {
		Screenname *name = (Screenname *) [iter next];
		[array addObject:[name getNormal]];
	}
	return [array autorelease];
}

- (NSObject<Set> *)getEffectiveAllowedBuddies
{
	id<Iterator> iter = [[[[aimConnection getSsiService] getPermissionList] getEffectiveAllowedBuddies] iterator];
	NSMutableArray *array = [[NSMutableArray alloc] init];
	while ([iter hasNext]) {
		Screenname *name = (Screenname *) [iter next];
		[array addObject:[name getNormal]];
	}
	return [array autorelease];
}

- (void)addToBlockList:(NSString *)sn
{
	[[[aimConnection getSsiService] getPermissionList] addToBlockList:NewScreenname(sn)];
}
- (void)addToAllowedList:(NSString *)sn
{
	[[[aimConnection getSsiService] getPermissionList] addToAllowedList:NewScreenname(sn)];
}
- (void)removeFromBlockList:(NSString *)sn
{
	[[[aimConnection getSsiService] getPermissionList] removeFromBlockList:NewScreenname(sn)];
}
- (void)removeFromAllowedList:(NSString *)sn
{
	[[[aimConnection getSsiService] getPermissionList] removeFromAllowedList:NewScreenname(sn)];
}

- (void)setPrivacyMode:(PRIVACY_OPTION)mode
{
	NSString *modeName = nil;
	switch(mode) {
		case PRIVACY_ALLOW_ALL:
			modeName = @"ALLOW_ALL";
			break;
		case PRIVACY_ALLOW_CONTACTLIST:
			modeName = @"ALLOW_BUDDIES";
			break;
		case PRIVACY_DENY_ALL:
			modeName = @"BLOCK_ALL";
			break;
		case PRIVACY_DENY_USERS:
			modeName = @"BLOCK_BLOCKED";
			break;
		case PRIVACY_ALLOW_USERS:
			modeName = @"ALLOW_ALLOWED";
			break;
		default:
			break;
	}
	[[[aimConnection getSsiService] getPermissionList] setPrivacyMode:[joscarBridge privacyModeFromString:modeName]];
}

#pragma mark Date conversions
/*
 * @brief Convert a Java Date to an NSDate
 */
NSDate* dateFromJavaDate(Date *javaDate)
{
	// [javaDate toString] format: "dow mon dd hh:mm:ss zzz yyyy"	
	return (javaDate ? 
			[NSCalendarDate dateWithString:[javaDate toString]
							calendarFormat:@"%a %b %d %H:%M:%S %Z %Y"] :
			nil);
}

/*
 * @brief Make a Java Date from an NSDate.
 */
Date* javaDateFromDate(NSDate *date)
{
	return [NewDate(1000 * (long long)[date timeIntervalSince1970]) autorelease];
}

#pragma mark Java VM Preparation
+ (void)prepareJavaVM
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	@synchronized(self) {
		//Only one vm is needed for all accounts
		static	NSJavaVirtualMachine	*vm = nil;
		static BOOL		attachedVmToMainRunLoop = NO;
		BOOL			onMainRunLoop = (CFRunLoopGetCurrent() == CFRunLoopGetMain());

		if (!vm) {
			NSString	*oscarJarPath, *joscarJarPath, *joscarBridgePath, *retroweaverJarPath, *socksJarPath;
			NSString	*classPath;

			oscarJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:OSCAR_JAR
																			ofType:@"jar"
																	   inDirectory:@"Java"];
			joscarJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:JOSCAR_JAR
																			 ofType:@"jar"
																		inDirectory:@"Java"];
			joscarBridgePath = [[NSBundle bundleForClass:[self class]] pathForResource:JOSCAR_BRIDGE_JAR
																				ofType:@"jar"
																		   inDirectory:@"Java"];
			retroweaverJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:RETROWEAVER_JAR
																				  ofType:@"jar"
																			 inDirectory:@"Java"];
			socksJarPath = [[NSBundle bundleForClass:[self class]] pathForResource:SOCKS_JAR
																			ofType:@"jar"
																	   inDirectory:@"Java"];
			
			classPath = [NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",
				[NSJavaVirtualMachine defaultClassPath],
				retroweaverJarPath, socksJarPath, oscarJarPath, joscarJarPath, joscarBridgePath];
			
			vm = [[NSJavaVirtualMachine alloc] initWithClassPath:classPath];
			
			AILog(@"-[%@ prepareJavaVM]: Java %@ ; joscar %@. Using classPath: %@",
				  self,
				  [NSClassFromString(@"java.lang.System") getProperty:@"java.version"],
				  [NSClassFromString(@"net.kano.joscar.JoscarTools") getVersionString],
				  classPath);
			
			if (onMainRunLoop) {
				attachedVmToMainRunLoop = YES;
			}

		} else {
			if  (!attachedVmToMainRunLoop && onMainRunLoop) {
				[vm attachCurrentThread];
				attachedVmToMainRunLoop = YES;
			}
		}

		if (onMainRunLoop &&
			!NSClassFromString(@"net.kano.joscar.JoscarTools")) {
			NSMutableString	*msg = [NSMutableString string];
			
			[msg appendFormat:@"Java version %@ could not load JoscarTools\n",[NSClassFromString(@"java.lang.System") getProperty:@"java.version"]];
			[msg appendFormat:@"Retroweaver-rt.jar %@\n", ((NSClassFromString(@"com.rc.retroweaver.runtime.ClassLiteral") != NULL) ? @"loaded" : @"NOT loaded")];
			[msg appendFormat:@"jsocks-klea.jar %@\n", ((NSClassFromString(@"socks.Proxy") != NULL) ? @"loaded" : @"NOT loaded")];
			[msg appendFormat:@"joscar bridge.jar %@\n", ((NSClassFromString(@"net.adium.joscarBridge.joscarBridge") != NULL) ? @"loaded" : @"NOT loaded")];
			[msg appendFormat:@"oscar.jar %@\n", ((NSClassFromString(@"net.kano.joustsim.Screenname") != NULL) ? @"loaded" : @"NOT loaded")];
			[msg appendFormat:@"joscar-0.9.4-cvs-bin.jar %@\n", ((NSClassFromString(@"net.kano.joscar.JoscarTools") != NULL) ? @"loaded" : @"NOT loaded")];

			NSRunCriticalAlertPanel(@"Fatal Java error",
									msg,
									nil,nil,nil);
		}
		
#ifdef DEBUG_BUILD
		[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotificationName:object:)
												   withObject:@"AttachedJavaVM"
												   withObject:nil];
#endif
	}

	[pool release];
}


#pragma mark Group Chat
- (void)setChatInvitation:(HashMap *)invite
{
	id<ChatInvitation> invitation = [invite get:@"ChatInvitation"];
	[account inviteToChat:[invitation getRoomName] 
			  fromContact:[[invitation getScreenname] getNormal]
			  withMessage:[invitation getMessage] 
			 inviteObject:invitation];
}

- (AIChat *)handleChatInvitation:(id<ChatInvitation>)invite withDecision:(BOOL)decision
{
	AIChat *chat = nil;
	if (decision) {
		ChatRoomSession *chatSession = [invite accept];
		[joscarChatsDict setObject:chatSession forKey:[[chatSession getRoomInfo] getRoomName]];
		[chatSession addListener:joscarBridge];
		
		chat = [account mainThreadChatWithName:[[chatSession getRoomInfo] getRoomName]];
		
		id<Iterator> iter = [[chatSession getUsers] iterator];
		while ([iter hasNext]) {
			NSString *tmp = [(Screenname *)[iter next] getNormal];
			NSLog(@"found contact %@ to be part of chat %@", tmp, [chat name]);
			[chat addParticipatingListObject:[account contactWithUID:[(Screenname *)[iter next] getNormal]]];
		}	
	} else
		[invite reject];
	return chat;
}

- (void)joinChatRoom:(NSString *)name
{
	ChatRoomSession *chatSession;
	NSAssert(name != nil, @"room name is nil in ESjoscarAdapter -joinChatRoom, this should never happen");
	if (![joscarChatsDict objectForKey:name]) {
		chatSession = [[aimConnection getChatRoomManager] joinRoom:name];
		[chatSession addListener:joscarBridge];
		[joscarChatsDict setObject:chatSession forKey:name];
	}
}

- (void)inviteUser:(NSString *)inUID toChat:(NSString *)chatName withMessage:(NSString *)inviteMessage
{
	Screenname			*sn = [NewScreenname(inUID) autorelease];
	[(ChatRoomSession *)[joscarChatsDict objectForKey:chatName] invite:sn :inviteMessage];
}

- (void)setGroupChatStateChange:(HashMap *)map
{
	ChatRoomSession *session = [map get:@"ChatRoomSession"];
	NSString *chatName = [[session getRoomInfo] getRoomName];
//	NSString *oldStateString = [map get:@"oldState"];
	NSString *stateString = [map get:@"state"];
//	state can be any of these: "INITIALIZING", "CONNECTING","FAILED","INROOM","CLOSED"
	if ([stateString isEqualToString:@"FAILED"]) {
		[joscarChatsDict removeObjectForKey:chatName];
		[session removeListener:joscarBridge];
		[account chatFailed:chatName];
	} else if([stateString isEqualToString:@"CLOSED"]) {
		[joscarChatsDict removeObjectForKey:chatName];
		[session removeListener:joscarBridge];
	}
	
}

- (void)setGroupChatUsersJoined:(HashMap *)map
{
	ChatRoomSession *session = [map get:@"ChatRoomSession"];
	NSString *chatName = [[session getRoomInfo] getRoomName];
	id<Set> theSet = (id<Set>)[map get:@"Set"];
	id<Iterator> iter = [theSet iterator];
	NSMutableArray *joined = [[NSMutableArray alloc] init];
	while ([iter hasNext]) {
		NSString *tmp = [(Screenname *)[(ChatRoomUser *)[iter next] getScreenname] getNormal];
		[joined addObject:[[tmp copy] autorelease]];
	}
	[account objectsJoinedChat:[joined autorelease] chatName:chatName];
}

- (void)setGroupChatUsersLeft:(HashMap *)map
{
	ChatRoomSession *session = [map get:@"ChatRoomSession"];
	NSString *chatName = [[session getRoomInfo] getRoomName];
	id<Iterator> iter = [(id<Set>)[map get:@"Set"] iterator];
	NSMutableArray *left = [[NSMutableArray alloc] init];
	while ([iter hasNext])
		[left addObject:[[[(Screenname *)[(ChatRoomUser *)[iter next] getScreenname] getNormal] copy] autorelease]];
	[account objectsLeftChat:[left autorelease] chatName:chatName];
}

- (void)setGroupChatIncomingMessage:(HashMap *)map
{
	NSString *uid = [[(ChatRoomUser *)[map get:@"ChatRoomUser"] getScreenname] getNormal];
	if (![uid isEqualToString:[account UID]]) {
		NSString *name = [[(ChatRoomSession *)[map get:@"ChatRoomSession"] getRoomInfo] getRoomName];
		NSString *message = [(ChatMessage *)[map get:@"ChatMessage"] getMessage];
		[account gotMessage:message onGroupChatNamed:name fromUID:uid];
	}
}

- (void)groupChatWithName:(NSString *)name sendMessage:(NSString *)message isAutoReply:(BOOL)isAutoReply
{
	[(ChatRoomSession *)[joscarChatsDict objectForKey:name] sendMessage:message];
}

- (void)leaveGroupChatWithName:(NSString *)name
{
	[(ChatRoomSession *)[joscarChatsDict objectForKey:name] close];
	[joscarChatsDict removeObjectForKey:name];
}


#pragma mark Utilities

OSErr FilePathToFileInfo(NSString *filePath, struct FileInfo *fInfo)
{
	CFURLRef	cfUrl = CFURLCreateWithFileSystemPath( kCFAllocatorDefault,
													(CFStringRef)filePath, kCFURLPOSIXPathStyle, FALSE);
	FSRef		fileRef;
	OSErr		err = noErr;
	FSCatalogInfo catInfo;
	
	
	if (CFURLGetFSRef(cfUrl, &fileRef)) {
		err = FSGetCatalogInfo( &fileRef, kFSCatInfoFinderInfo, &catInfo,
								NULL, NULL, NULL );
		if (err == noErr) {
			memcpy(fInfo, catInfo.finderInfo, sizeof(fInfo));
		}
		
		CFRelease(cfUrl);
	}

	return err;
}

@end

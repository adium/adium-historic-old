//
//  RAFjoscarAccount.m
//  Adium
//
//  Created by Augie Fackler on 11/21/05.
//

#import "RAFjoscarAccount.h"
#import "RAFjoscarSecuridPromptController.h"
#import "AIAdium.h"
#import "AIPreferenceController.h"
#import "AIContactController.h"
#import "AIAccountController.h"
#import "AIContentController.h"
#import "AIChatController.h"
#import "AIStatusController.h"
#import <Adium/AIContentMessage.h>
#import <Adium/AIChat.h>
#import <Adium/ESDebugAILog.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIListGroup.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIListObject.h>
#import <Adium/ESTextAndButtonsWindowController.h>
#import <Adium/AIContentStatus.h>
#import <Adium/AITextAttachmentExtension.h>

#import <AIUtilities/AIApplicationAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIImageAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>
#import <AIUtilities/AIStringAdditions.h>

#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIStringUtilities.h>

#define	PREF_GROUP_ALIASES			@"Aliases"		//Preference group to store aliases in

#define CHAT_INVITE_TITLE AILocalizedString(@"Group Chat Invite","joscar group chat invitation window title")
#define BASE_INVITE_TEXT AILocalizedString(@"%@ invites you to a group chat with the following message:\n%@","joscar invite message for group chats")
#define ACCEPT_INVITE_TEXT AILocalizedString(@"Accept","joscar accept group chat button caption")
#define REJECT_INVITE_TEXT AILocalizedString(@"Reject","joscar reject group chat button caption")

@implementation RAFjoscarAccount

- (void)initAccount
{
	[super initAccount];
	AILog(@"Initializing %@",self);
	NSDictionary	*defaults = [NSDictionary dictionaryNamed:[NSString stringWithFormat:@"joscarDefaults"]
													 forClass:[self class]];
	
	if (defaults) {
		[[adium preferenceController] registerDefaults:defaults
											  forGroup:GROUP_ACCOUNT_STATUS
												object:self];
	} else {
		AILog(@"Failed to load joscar defaults");
	}	
	
	//Observe preferences changes
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_ALIASES];
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_NOTES];

	fileTransferDict = [[NSMutableDictionary alloc] init];

	static BOOL beganInitializingJavaVM = NO;
	if (!beganInitializingJavaVM && [self enabled]) {
		[ESjoscarCocoaAdapter initializeJavaVM];
		beganInitializingJavaVM = YES;
	}
	
	inSignOnDelay = NO;
}

- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	[fileTransferDict release]; fileTransferDict = nil;

	[super dealloc];
}

#pragma mark Account connectivity

- (void)connect
{		
	[super connect];
	
	//Make the joscar bridge for this account if necessary
	if (!joscarAdapter) {
		joscarAdapter = [[ESjoscarCocoaAdapter alloc] initForAccount:self];
	}
	AILog(@"+++ Connecting %@ via %@", self, joscarAdapter);

	[self getProxyConfigurationNotifyingTarget:self
									  selector:@selector(retrievedProxyConfiguration:context:)
									   context:nil];	
}

- (void)retrievedProxyConfiguration:(NSDictionary *)proxyConfiguration context:(id)context
{
	[joscarAdapter connectWithPassword:password proxyConfiguration:proxyConfiguration];
}

- (void)disconnect
{
	[super disconnect];
	
	[joscarAdapter disconnect];
}

- (AIListContact *)contactWithUID:(NSString *)inUID
{
	return ([[adium contactController] contactWithService:service
												  account:self
													  UID:inUID]);
}

- (NSString *)serversideUID
{
	return [self UID];
}

#pragma mark Contact status and info

- (void)contactWithUID:(NSString *)inUID setStatusMessage:(NSString *)statusMessage
{	
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[listContact setStatusMessage:((statusMessage && [statusMessage length]) ? 
								   [AIHTMLDecoder decodeHTML:statusMessage] : 
								   nil)
						   notify:NotifyLater];
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];	
}

- (void)contactWithUID:(NSString *)inUID setProfile:(NSString *)profile
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[listContact setProfile:[AIHTMLDecoder decodeHTML:profile] notify:NotifyLater];
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)contactWithUID:(NSString *)inUID
			  isOnline:(NSNumber *)isOnline
				isAway:(NSNumber *)isAway
			 idleSince:(NSDate *)idleSince
		   onlineSince:(NSDate *)onlineSince
		  warningLevel:(NSNumber *)warningLevel
				mobile:(NSNumber *)inMobile
			   aolUser:(NSNumber *)inAolUser
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	if ([listContact online] != [isOnline boolValue]) {
		[listContact setOnline:[isOnline boolValue]
						notify:NotifyLater
					  silently:silentAndDelayed];
	}

	//here we unset the away message if we're going from away to present
	if ([listContact statusType] == AIAwayStatusType && ![isAway boolValue])
		[listContact setStatusMessage:nil notify:NotifyLater];
	//here we set wether we're away or not. the Away message (if applicable) will come in via setStatusMessage in a bit.
	[listContact setStatusWithName:nil
						statusType:([isAway boolValue] ? AIAwayStatusType : AIAvailableStatusType)
							notify:NotifyLater];
	
	[listContact setIdle:(idleSince != nil)
			   sinceDate:idleSince
				  notify:NotifyLater];
	
	[listContact setSignonDate:onlineSince
						notify:NotifyLater];
	[listContact setWarningLevel:[warningLevel intValue]
						  notify:NotifyLater];
	
	[listContact setIsMobile:[inMobile boolValue]
					  notify:NotifyLater];
	
	[listContact setIsMobile:[inMobile boolValue]
					  notify:NotifyLater];

	[listContact setStatusObject:([inAolUser boolValue] ?
								 AILocalizedString(@"America Online", nil) :
								 nil)
						 forKey:@"Client"
						 notify:NotifyLater];

	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)contactWithUID:(NSString *)inUID
			  isOnline:(NSNumber *)isOnline
{
	AIListContact	*listContact = [self contactWithUID:inUID];

	if ([listContact online] != [isOnline boolValue]) {
		[listContact setOnline:[isOnline boolValue]
						notify:NotifyLater
					  silently:silentAndDelayed];

		//Apply any changes
		[listContact notifyOfChangedStatusSilently:silentAndDelayed];
	}	
}

//Update the status of a contact (Request their profile)
- (void)delayedUpdateContactStatus:(AIListContact *)inContact
{
	[joscarAdapter requestInfoForContactWithUID:[inContact UID]];
}

#pragma mark Account state and status
- (void)stateChangedTo:(NSString *)newState errorMessageShort:(NSString *)errorMessageShort errorCode:(NSString *)errorCode
{
	AILog(@"%@: State changed to %@ (%@ - %@)",self,newState,errorMessageShort,errorCode);

	if ([newState isEqualToString:@"FAILED"] || [newState isEqualToString:@"DISCONNECTED"]) {
		[self didDisconnect];
		
		if (errorMessageShort) {
			BOOL shouldReconnect = YES;
			
			if ([errorMessageShort isEqualToString:@"Password"]) {
				[self serverReportedInvalidPassword];
				
			} else if ([errorMessageShort isEqualToString:@"TooFrequently"]) {
				shouldReconnect = NO;
				NSLog(@"Connecting too frequently!");
				AILog(@"Connecting too frequently!");

			} else if ([errorMessageShort isEqualToString:@"TemporarilyBlocked"]) {
				shouldReconnect = NO;
				NSLog(@"Temporarily blocked!");
				AILog(@"Temporarily blocked!");
			} else {
				NSLog(@"Error message short is %@; code %@",errorMessageShort,
					  errorCode);
			}
			
			if (shouldReconnect) {
				[self autoReconnectAfterDelay:3.0];
			}
		}
		
	} else if ([newState isEqualToString:@"SIGNINGON"]) {
		//At the start of signing on, we'll get a bunch of object notifications in rapid succession... group 'em
		if (!inSignOnDelay) {
			[[adium contactController] delayListObjectNotifications];
			inSignOnDelay = YES;
		}
		
	} else if ([newState isEqualToString:@"ONLINE"]) {
		//Now end the grouping we started in SIGNINGON
		if (inSignOnDelay) {
			[[adium contactController] endListObjectNotificationsDelay];
			inSignOnDelay = NO;
		}
		
		//We're connected!
		[self didConnect];
		
		//Silence subsequent initial updates as they come in over the next 10 seconds or so
		[self silenceAllContactUpdatesForInterval:18.0];
		[[adium contactController] delayListObjectNotificationsUntilInactivity];
	}
}

- (void)didConnect
{
	[super didConnect];
	
	[self updateStatusForKey:@"TextProfile"];
	[self updateStatusForKey:KEY_USER_ICON];
}

- (void)didDisconnect
{
	[super didDisconnect];

	if (inSignOnDelay) {
		[[adium contactController] endListObjectNotificationsDelay];
		inSignOnDelay = NO;
	}
}

#pragma mark Status Messages and Idle

- (void)updateStatusForKey:(NSString *)key
{    
	AILog(@"%@: Updating status for %@",self,key);
	[super updateStatusForKey:key];

	if ([self online]) {
		if ([key isEqualToString:@"IdleSince"]) {
			NSDate	*idleSince = [self preferenceForKey:@"IdleSince" group:GROUP_ACCOUNT_STATUS];
			[self setAccountIdleSinceTo:idleSince];
			
		} else if ([key isEqualToString:@"TextProfile"]) {
			
			[self autoRefreshingOutgoingContentForStatusKey:key selector:@selector(setAccountProfileTo:)];
			
		} else if ([key isEqualToString:KEY_USER_ICON]) {
			NSData  *data = [self preferenceForKey:KEY_USER_ICON group:GROUP_ACCOUNT_STATUS];			
			
			[self setAccountUserIconData:data];
		}
	}
}

- (void)setAccountProfileTo:(NSAttributedString *)profile
{
	static AIHTMLDecoder *profileEncoder = nil;
	if (!profileEncoder) {
		profileEncoder = [[AIHTMLDecoder alloc] initWithHeaders:YES
													   fontTags:YES
												  closeFontTags:YES
													  colorTags:YES
													  styleTags:YES 
												 encodeNonASCII:YES 
												   encodeSpaces:NO
											  attachmentsAsText:NO
									  onlyIncludeOutgoingImages:YES 
												 simpleTagsOnly:YES 
												 bodyBackground:NO];
	}

	AILog(@"%@: Setting profile %@",self, profile);
	NSString *encodedProfile = [profileEncoder encodeHTML:profile imagesPath:nil];
	AILog(@"%@: Encoded to %@",self,encodedProfile);
	[joscarAdapter setUserProfile:encodedProfile];
}


- (void)setStatusState:(AIStatus *)statusState usingStatusMessage:(NSAttributedString *)statusMessage
{
	if ([statusState statusType] == AIOfflineStatusType) {
		[self disconnect];

	} else {
		if ([self online]) {
			NSString		*encodedAway = nil;
			NSString		*availableMessage = nil;
			NSString		*itmsURL = nil;

			AIStatusType	statusType = [statusState statusType];
			
			if (statusType == AIAwayStatusType) {
				if (statusMessage && [statusMessage length]) {
					static AIHTMLDecoder *awayEncoder = nil;
					if (!awayEncoder) {
						awayEncoder = [[AIHTMLDecoder alloc] initWithHeaders:NO
																	fontTags:YES
															   closeFontTags:YES
																   colorTags:YES
																   styleTags:YES 
															  encodeNonASCII:YES 
																encodeSpaces:NO
														   attachmentsAsText:NO
												   onlyIncludeOutgoingImages:YES 
															  simpleTagsOnly:YES 
															  bodyBackground:NO];
					}

					encodedAway = [awayEncoder encodeHTML:statusMessage imagesPath:nil];
				} else {
					encodedAway = [[adium statusController] localizedDescriptionForCoreStatusName:STATUS_NAME_AWAY];
				}

			} else if (statusType == AIAvailableStatusType) {
				availableMessage = [[statusMessage attributedStringByConvertingLinksToStrings] string];
				
				if ([statusMessage length]) {
					//Grab the message's subtext, which is the song link if we're using the Current iTunes Track status 
					itmsURL = [statusMessage attribute:@"AIMessageSubtext" atIndex:0 effectiveRange:NULL];
				}
			}
			
			[joscarAdapter setVisibleStatus:(statusType != AIInvisibleStatusType)];
			
			/* this sets the away message to nil if we weren't supposed to be away
			 * this way we're sure we actually are in the intended state
			 * same logic for the available message
			 */
			[joscarAdapter setMessageAway:encodedAway];

			if (itmsURL) {
				[joscarAdapter setStatusMessage:availableMessage withSongURL:itmsURL];
			} else {
				[joscarAdapter setStatusMessage:availableMessage];	
			}

		} else {
			[self connect];
		}
	}
}

- (void)setAccountIdleSinceTo:(NSDate *)idleSince
{
	if (idleSince)
		[joscarAdapter setIdleSince:idleSince];
	else
		[joscarAdapter setUnidle];
}

/*!
 * @brief Set our user image
 *
 * Pass nil for no image. This resizes and converts the image as needed for AIM.
 * After setting it with joscar, it sets it within Adium; if this is not called, the image will
 * show up neither locally nor remotely.
 */
- (void)setAccountUserIconData:(NSData *)imageData
{
	NSImage *image = (imageData ? [[[NSImage alloc] initWithData:imageData] autorelease] : nil);
	NSData	*buddyIconData = nil;
	NSSize	imageSize = (image ? [image size] : NSZeroSize);
	if (!NSEqualSizes(NSZeroSize, imageSize)) {
		NSSize	maxSize = NSMakeSize(50, 50);		
		
		if ((imageSize.width > maxSize.width ||
			 imageSize.height > maxSize.height)) {
			//Determine the scaled size.  If it's too big, scale to the largest permissable size
			image = [image imageByScalingToSize:maxSize];
			
			/* Our original data is no longer valid, since we had to scale to a different size */
			imageData = nil;
		}
		
		//Look for gif first if the image is animated
		if (imageData) {
			NSImageRep	*imageRep = [image bestRepresentationForDevice:nil];
			if ([imageRep isKindOfClass:[NSBitmapImageRep class]] &&
				[[(NSBitmapImageRep *)imageRep valueForProperty:NSImageFrameCount] intValue] > 1) {
				
				/* Try to use our original data.  If we had to scale, originalData will have been set
				* to nil and we'll continue below to convert the image. */
				AILog(@"l33t script kiddie animated GIF!!111");
				
				buddyIconData = imageData;
			}
		}

		//If we don't have data yet (not an animated gif), get a JPEG representation
		if (!buddyIconData) {
			/* OS X 10.4's JPEG representation does much better than 10.3's.  Unfortunately, that also
			 * means larger file sizes... which for AIM, means the buddy icon doesn't get sent.
			 * AIM max is 8 kilobytes; 10.4 produces 12 kb images.  0.90 is largely indistinguishable from 1.0 anyways.
			 */
			float compressionFactor = ([NSApp isOnTigerOrBetter] ?
									   0.9 :
									   1.0);

			buddyIconData = [image JPEGRepresentationWithCompressionFactor:compressionFactor];
		}
	}

	[joscarAdapter setAccountUserIconData:buddyIconData];
	
	//We now have an icon
	[self setStatusObject:image forKey:KEY_USER_ICON notify:NotifyNow];
}

#pragma mark Buddy list
- (void)setListContact:(AIListContact *)listContact toAlias:(NSString *)inAlias
{
	BOOL			changes = NO, nameChanges = NO;
	
	if (inAlias && ([inAlias length] == 0)) inAlias = nil;
	
	AIMutableOwnerArray	*displayNameArray = [listContact displayArrayForKey:@"Display Name"];
	NSString			*oldDisplayName = [displayNameArray objectValue];
	
	//If the mutableOwnerArray's current value isn't identical to this alias, we should set it
	if (![[displayNameArray objectWithOwner:self] isEqualToString:inAlias]) {
		[displayNameArray setObject:inAlias
						  withOwner:self
					  priorityLevel:Low_Priority];
		
		//If this causes the object value to change, we need to request a manual update of the display name
		if (oldDisplayName != [displayNameArray objectValue]) {
			nameChanges = YES;
		}
	}
	
	if (![[listContact statusObjectForKey:@"Server Display Name"] isEqualToString:inAlias]) {
		[listContact setStatusObject:inAlias
							  forKey:@"Server Display Name"
							  notify:NotifyLater];
		changes = YES;
	}
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
	
	if (nameChanges) {
		//Notify of display name changes
		[[adium contactController] listObjectAttributesChanged:listContact
												  modifiedKeys:[NSSet setWithObject:@"Display Name"]];
		
		//XXX - There must be a cleaner way to do this alias stuff!  This works for now
		//Request an alias change
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:listContact
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
}

- (void)contactWithUID:(NSString *)inUID
		  formattedUID:(NSString *)formattedUID
				 alias:(NSString *)alias
			   comment:(NSString *)comment
		  addedToGroup:(NSString *)groupName
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	if (![[listContact formattedUID] isEqualToString:formattedUID]){
		[listContact setFormattedUID:formattedUID
							  notify:NotifyLater];
	}

	if (![[listContact remoteGroupName] isEqualToString:groupName]){
		[listContact setRemoteGroupName:groupName];
	}
	
	if (comment && [comment length]) {
		[listContact setStatusObject:comment
							  forKey:@"Notes"
							  notify:NotifyLater];
	}
	
	//Will call [listContact notifyOfChangedStatusSilently:] for us
	[self setListContact:listContact toAlias:alias];
}

- (void)contactWithUID:(NSString *)inUID removedFromGroup:(NSString *)groupName
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[listContact setRemoteGroupName:nil];
}

- (void)contactWithUID:(NSString *)inUID changedToAlias:(NSString *)alias
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[self setListContact:listContact toAlias:alias];
}

- (void)contactWithUID:(NSString *)inUID changedToBuddyComment:(NSString *)comment
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[listContact setStatusObject:comment
						  forKey:@"Notes"
						  notify:NotifyLater];
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

- (void)contactWithUID:(NSString *)inUID iconUpdate:(NSData *)iconData
{
	AIListContact	*listContact = [self contactWithUID:inUID];
	
	[listContact setServersideIconData:iconData
								notify:NotifyLater];
	
	//Apply any changes
	[listContact notifyOfChangedStatusSilently:silentAndDelayed];
}

#pragma mark Messaging
//Open a chat for Adium
- (BOOL)openChat:(AIChat *)chat
{	
	if ([chat isGroupChat])
		[joscarAdapter joinChatRoom:[chat name]];
	
	//Created the chat successfully
	return YES;
}

- (BOOL)closeChat:(AIChat*)chat
{
	if ([chat isGroupChat])
		[joscarAdapter leaveGroupChatWithName:[chat name]];
    return YES;
}

/*
 * @brief Send a message
 */
- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	if (![[inContentMessage chat] isGroupChat]) {
		[joscarAdapter chatWithUID:[[[inContentMessage chat] listObject] UID]
					   sendMessage:[inContentMessage encodedMessage]
					   isAutoreply:[inContentMessage isAutoreply]
						joscarData:[inContentMessage encodedMessageAccountData]];
	} else {
		if (![inContentMessage isAutoreply])
			[joscarAdapter groupChatWithName:[[inContentMessage chat] name]
								 sendMessage:[inContentMessage encodedMessage]
								 isAutoReply:[inContentMessage isAutoreply]];
	}
	
	return YES;
}

/*
 * @brief Send a typing notification
 */
- (BOOL)sendTypingObject:(AIContentTyping *)inContentTyping
{
	AITypingState	typingState = [inContentTyping typingState];
	if (![[inContentTyping chat] isGroupChat]) {
		[joscarAdapter chatWithUID:[[[inContentTyping chat] listObject] UID]
					setTypingState:typingState];
	}

	return YES;
}

/*
 * @brief Should HTML be sent in messages to this contact?
 *
 * We don't want to send HTML to ICQ users or mobile phone users
 */
BOOL isHTMLContact(AIListObject *inListObject)
{
	char		firstCharacter = [[inListObject UID] characterAtIndex:0];
	
	return ((firstCharacter < '0' || firstCharacter > '9') && firstCharacter != '+');
}


/*
 * @encode Encode a message to HTML if appropriate
 *
 * We take this opportunity to process the HTML message, looking for IMG tags to send via DirectIM
 */
- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{
	NSAttributedString	*message = [inContentMessage message];
	NSString			*encodedMessage;

	if (isHTMLContact([inContentMessage destination])) {
		if([message containsAttachments]) {
			NSRange limitRange;
			NSRange effectiveRange;
			id attributeValue;
			
			limitRange = NSMakeRange(0, [message length]);
			
			while (limitRange.length > 0) {
				attributeValue = [message attribute:NSAttachmentAttributeName
											atIndex:limitRange.location 
							  longestEffectiveRange:&effectiveRange
											inRange:limitRange];
				if([attributeValue respondsToSelector:@selector(setImageClass:)])
					[(AITextAttachmentExtension *)attributeValue setImageClass:@"scaledToFitImage"];
				limitRange = NSMakeRange(NSMaxRange(effectiveRange),
										 NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
			}
		}
		
		static AIHTMLDecoder *messageEncoder = nil;
		if (!messageEncoder) {
			messageEncoder = [[AIHTMLDecoder alloc] init];
			[messageEncoder setIncludesHeaders:YES];
			[messageEncoder setIncludesFontTags:YES];
			[messageEncoder setClosesFontTags:NO];
			[messageEncoder setIncludesStyleTags:YES];
			[messageEncoder setIncludesColorTags:YES];
			[messageEncoder setEncodesNonASCII:NO];
			[messageEncoder setPreservesAllSpaces:NO];
			[messageEncoder setUsesAttachmentTextEquivalents:NO];
			[messageEncoder setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
			[messageEncoder setOnlyUsesSimpleTags:NO];
			[messageEncoder setAllowAIMsubprofileLinks:YES];
		}
		
		id	joscarDataForThisMessage = nil;
		encodedMessage = [joscarAdapter processOutgoingMessage:[messageEncoder encodeHTML:message
																			   imagesPath:NSTemporaryDirectory()]
													joscarData:&joscarDataForThisMessage];
		if (joscarDataForThisMessage) {
			[inContentMessage setEncodedMessageAccountData:joscarDataForThisMessage];
		}

	} else {
		encodedMessage = [[message attributedStringByConvertingLinksToStrings] string];
	}
	AILog(@"%@: Encoded %@ to send to %@",self, encodedMessage, [inContentMessage destination]);
	return encodedMessage;
}

- (void)chatWithContact:(AIListContact *)sourceContact receivedAttributedMessage:(NSAttributedString *)inMessage isAutoreply:(NSNumber *)isAutoreply
{	
	AIChat				*chat;
	AIContentMessage	*messageObject;
	
	if (!(chat = [[adium chatController] existingChatWithContact:sourceContact]))
		chat = [[adium chatController] openChatWithContact:sourceContact];
	
	messageObject = [AIContentMessage messageInChat:chat
										 withSource:sourceContact
										destination:self
											   date:[NSDate date]
											message:inMessage
										  autoreply:[isAutoreply boolValue]];
	
	[[adium contentController] receiveContentObject:messageObject];
	
	//We received a message; clear the typing state
	[chat setStatusObject:nil
				   forKey:KEY_TYPING
				   notify:NotifyNow];	
}

- (void)chatWithUID:(NSString *)inUID receivedMessage:(NSString *)inHTML isAutoreply:(NSNumber *)isAutoreply
{
	AIListContact		*sourceContact = [self contactWithUID:inUID];
	NSAttributedString	*attributedMessage;
	if (isHTMLContact(sourceContact)) { 
		attributedMessage = [[adium contentController] decodedIncomingMessage:inHTML
																  fromContact:sourceContact
																	onAccount:self];
	} else {
		NSString	*decryptedIncomingMessage;

		decryptedIncomingMessage = [[adium contentController] decryptedIncomingMessage:inHTML
																		   fromContact:sourceContact
																			 onAccount:self];
		
		if (([decryptedIncomingMessage rangeOfString:@"ichatballooncolor"].location != NSNotFound) ||
			([decryptedIncomingMessage rangeOfString:@"<HTML>"
											 options:(NSCaseInsensitiveSearch | NSLiteralSearch | NSAnchoredSearch)].location != NSNotFound)) {
			/* iChat ICQ contacts still send HTML. Decode it.
			 * Some ICQ clients send HTML anyways; the first part of the incoming message will be <HTML>. Decode it.
			 */
			attributedMessage = [AIHTMLDecoder decodeHTML:decryptedIncomingMessage];

		} else {
			attributedMessage = [[[NSAttributedString alloc] initWithString:decryptedIncomingMessage] autorelease];
		}
	}

	[self chatWithContact:sourceContact receivedAttributedMessage:attributedMessage isAutoreply:isAutoreply];
}

- (void)chatWithUID:(NSString *)inUID receivedDirectMessage:(NSString *)inHTML isAutoreply:(NSNumber *)isAutoreply joscarData:(id)joscarData
{
	AIListContact		*sourceContact = [self contactWithUID:inUID];
	NSAttributedString  *attributedMessage;
	NSString			*decryptedMessage, *processedMessage;
	
	//First, we must decrypt the message in case it is encrypted
	decryptedMessage = [[adium contentController] decryptedIncomingMessage:inHTML
															   fromContact:sourceContact
																 onAccount:self];
	
	processedMessage = [joscarAdapter processIncomingDirectMessage:decryptedMessage
														joscarData:joscarData];
	
	attributedMessage = [AIHTMLDecoder decodeHTML:processedMessage];

	[self chatWithContact:sourceContact receivedAttributedMessage:attributedMessage isAutoreply:isAutoreply];	
}
	
/*
 * @brief Got a typing state
 *
 * @param inUID The UID of the contact with which the chat is taking palce
 * @param typingState An NSNumber encapsulating an AITypingState
 */
- (void)chatWithUID:(NSString *)inUID gotTypingState:(NSNumber *)typingState
{
	AIListContact	*sourceContact = [self contactWithUID:inUID];
	AIChat			*chat;
	
	chat = [[adium chatController] chatWithContact:sourceContact];
	
	[chat setStatusObject:typingState
				   forKey:KEY_TYPING
				   notify:NotifyNow];	
}

- (void)chatWithUID:(NSString *)inUID gotError:(NSNumber *)errorType
{
	AIListContact	*sourceContact = [self contactWithUID:inUID];
	AIChat			*chat;
	
	chat = [[adium chatController] existingChatWithContact:sourceContact];

	[chat receivedError:errorType];
}

- (BOOL)canSendImagesForChat:(AIChat *)inChat
{
	//XXX Check against the chat's list object's capabilities for DirectIM
	return ![inChat isGroupChat];
}

- (void)chatWithUID:(NSString *)inUID setDirectIMConnected:(BOOL)isConnected
{
	AIListContact	*sourceContact = [self contactWithUID:inUID];

	[[adium contentController] displayStatusMessage:(isConnected ?
													 AILocalizedString(@"Direct Instant Message session started","Direct IM is an AIM-specific phrase for transferring images in the message window") :
													 AILocalizedString(@"Direct Instant Message session ended","Direct IM is an AIM-specific phrase for transferring images in the message window"))
											 ofType:@"directIM"
											 inChat:[[adium chatController] existingChatWithContact:sourceContact]];	
}


#pragma mark Contact list editing
/*!
* @brief Contact list editable?
 *
 * Returns YES if the contact list is currently editable
 */
- (BOOL)contactListEditable
{
    return [self online];
}

- (NSArray *)arrayOfUIDsForContacts:(NSArray *)listContacts
{
	NSMutableArray	*UIDs = [NSMutableArray array];
	NSEnumerator	*enumerator;
	AIListContact	*listContact;
	
	enumerator = [listContacts objectEnumerator];
	while ((listContact = [enumerator nextObject])) {
		[UIDs addObject:[listContact UID]];
	}
	
	return UIDs;
}

/*!
* @brief Add contacts
 *
 * Add contacts to a group on this account.  Create the group if it doesn't already exist.
 * @param contacts NSArray of AIListContact objects to add
 * @param group AIListGroup destination for contacts
 */
- (void)addContacts:(NSArray *)contacts toGroup:(AIListGroup *)inGroup
{
	[joscarAdapter addContactsWithUIDs:[self arrayOfUIDsForContacts:contacts]
							   toGroup:[inGroup UID]];
}


/*!
* @brief Remove contacts
 *
 * Remove contacts from this account.
 * @param contacts NSArray of AIListContact objects to remove
 */
- (void)removeContacts:(NSArray *)contacts
{	
	[joscarAdapter removeContactsWithUIDs:[self arrayOfUIDsForContacts:contacts]];
}

/*!
* @brief Move contacts
 *
 * Move existing contacts to a specific group on this account.  The passed contacts should already exist somewhere on
 * this account.
 * @param contacts NSArray of AIListContact objects to remove
 * @param inGroup AIListGroup destination for contacts
 */
- (void)moveListObjects:(NSArray *)contacts toGroup:(AIListGroup *)inGroup
{
	[joscarAdapter moveContactsWithUIDs:[self arrayOfUIDsForContacts:contacts]
								toGroup:[inGroup UID]];
}

#pragma mark File Transfer
- (BOOL)supportsFolderTransfer
{
	return YES;
}

- (void)newIncomingFileTransferWithUID:(NSString *)inUID
							  fileName:(NSString *)fileName
							  fileSize:(NSNumber *)fileSize
							identifier:(NSValue *)identifier
{
	AIListContact   *contact = [self contactWithUID:inUID];
    ESFileTransfer	*fileTransfer;
	
	fileTransfer = [[adium fileTransferController] newFileTransferWithContact:contact
																   forAccount:self
																		 type:Incoming_FileTransfer]; 
	[fileTransfer setSize:[fileSize longLongValue]];
	[fileTransfer setRemoteFilename:fileName];
	[fileTransfer setAccountData:identifier];
	
	[fileTransferDict setObject:fileTransfer
						 forKey:identifier];
	
    [[adium fileTransferController] receiveRequestForFileTransfer:fileTransfer];
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
	[joscarAdapter acceptIncomingFileTransferWithIdentifier:[fileTransfer accountData]
											destinationPath:[fileTransfer localFilename]];
}

//Instructs the account to initiate sending of a file
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer;
{
	NSValue		*identifier;
	NSString	*contactUID = [[fileTransfer contact] UID];
	NSArray		*files = [NSArray arrayWithObject:[fileTransfer localFilename]];
	
	identifier = [joscarAdapter initiateOutgoingFileTransferForUID:contactUID
														  forFiles:files];
	
	[fileTransfer setAccountData:identifier];
	[fileTransferDict setObject:fileTransfer
						 forKey:identifier];
}

//Instructs the account to reject a file receive request
- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
	[joscarAdapter rejectIncomingFileTransferWithIdentifier:[fileTransfer accountData]];
}

//Instructs the account to cancel a file transfer in progress
- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[joscarAdapter cancelFileTransferWithIdentifier:[fileTransfer accountData]];	
}

- (void)updateFileTransferWithIdentifier:(NSValue *)identifier toFileTransferStatus:(NSNumber *)fileTransferStatusNumber
{
	ESFileTransfer		*fileTransfer;
	FileTransferStatus	fileTransferStatus = [fileTransferStatusNumber intValue];
	
	fileTransfer = [fileTransferDict objectForKey:identifier];
	[fileTransfer setStatus:fileTransferStatus];
}

- (void)updateFileTransferWithIdentifier:(NSValue *)identifier toPosition:(NSNumber *)positionNumber
{
	ESFileTransfer		*fileTransfer;
	
	fileTransfer = [fileTransferDict objectForKey:identifier];
	[fileTransfer setPercentDone:0 bytesSent:[positionNumber longLongValue]];
}

#pragma mark Supported Property Keys
/*!
* @brief Supported status keys
 *
 * Returns an array of status keys supported by this account.  This account will not be informed of changes to keys
 * it does not support.  Available keys are:
 *   @"Display Name", @"Online", @"Offline", @"IdleSince", @"IdleManuallySet", @"User Icon"
 *   @"TextProfile", @"DefaultUserIconFilename", @"StatusState"
 * @return NSSet of supported keys
 */
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys){
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"Online",
			@"Offline",
			@"IdleSince",
			@"IdleManuallySet",
			@"TextProfile",
			nil];
		
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

/* Is this really necessary? */
- (BOOL)availableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact
{
	return [self online];
}

#pragma mark Privacy
//Add a list object to the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success.
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
	switch (type) {
		case PRIVACY_DENY:
			[joscarAdapter addToBlockList:[inObject UID]];
			break;
		case PRIVACY_PERMIT:
			[joscarAdapter addToAllowedList:[inObject UID]];
			break;
	}
	return YES;
}
//Remove a list object from the privacy list (either PRIVACY_PERMIT or PRIVACY_DENY). Return value indicates success
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
	switch (type) {
		case PRIVACY_DENY:
			[joscarAdapter removeFromBlockList:[inObject UID]];
			break;
		case PRIVACY_PERMIT:
			[joscarAdapter removeFromAllowedList:[inObject UID]];
			break;
	}
	return YES;
}
//Return an array of AIListContacts on the specified privacy list.  Returns an empty array if no contacts are on the list.
-(NSArray *)listObjectsOnPrivacyList:(PRIVACY_TYPE)type
{
	NSArray *tmp = nil;
	switch (type) {
		case PRIVACY_DENY:
			tmp = [joscarAdapter getBlockedBuddies];
			break;
		case PRIVACY_PERMIT:
			tmp = [joscarAdapter getAllowedBuddies];
			break;
	}
	NSEnumerator *enumerator = [tmp objectEnumerator];
	NSString *listObj;
	NSMutableArray *retArr=[[NSMutableArray alloc] init];
	while ((listObj = [enumerator nextObject]))
		[retArr addObject:[[adium contactController] contactWithService:[self service] account:self UID:listObj]];
	return [retArr autorelease];
}

//Identical to the above method, except it returns an array of strings, not list objects
-(NSArray *)listObjectIDsOnPrivacyList:(PRIVACY_TYPE)type
{
	NSArray *tmp = nil;
	switch (type) {
		case PRIVACY_DENY:
			tmp = [joscarAdapter getBlockedBuddies];
			break;
		case PRIVACY_PERMIT:
			tmp = [joscarAdapter getAllowedBuddies];
			break;
	}

	NSEnumerator *enumerator = [tmp objectEnumerator];
	NSString *listObj;
	NSMutableArray *retArr=[[NSMutableArray alloc] init];
	while ((listObj = [enumerator nextObject]))
		[retArr addObject:[[[adium contactController] contactWithService:[self service] account:self UID:listObj] internalObjectID]];
	return [retArr autorelease];
}
//Set the privacy options
-(void)setPrivacyOptions:(PRIVACY_OPTION)option
{
	[joscarAdapter setPrivacyMode:option];
}

//Get the privacy options
-(PRIVACY_OPTION)privacyOptions
{
	return [joscarAdapter privacyMode];
}

#pragma mark Preferences Observer
/*
 * @brief Observe preference changes to store alias and notes information on the server
 */
- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	if ([group isEqualToString:PREF_GROUP_ALIASES]) {
		//If the notification object is a listContact belonging to this account, update the serverside information
		if ([self online] &&
			([key isEqualToString:@"Alias"])) {
			
			NSString *alias = [object preferenceForKey:@"Alias"
												 group:PREF_GROUP_ALIASES 
								 ignoreInheritedValues:YES];
			
			if ([object isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*enumerator = [[(AIMetaContact *)object containedObjects] objectEnumerator];
				AIListContact	*containedListContact;
				while ((containedListContact = [enumerator nextObject])) {
					if ([containedListContact account] == self) {
						[joscarAdapter setAlias:alias forContactWithUID:[containedListContact UID]];
					}
				}
				
			} else if ([object isKindOfClass:[AIListContact class]]) {
				if ([(AIListContact *)object account] == self) {
					[joscarAdapter setAlias:alias forContactWithUID:[object UID]];
				}
			}
		}

	} else if ([group isEqualToString:PREF_GROUP_NOTES]) {
		if ([self online] &&
			[key isEqualToString:@"Notes"]) {
			
			NSString  *notes = [object preferenceForKey:@"Notes" 
													group:PREF_GROUP_NOTES
									ignoreInheritedValues:YES];
			
			if ([object isKindOfClass:[AIMetaContact class]]) {
				NSEnumerator	*enumerator = [[(AIMetaContact *)object containedObjects] objectEnumerator];
				AIListContact	*containedListContact;
				while ((containedListContact = [enumerator nextObject])) {
					if ([containedListContact account] == self) {
						[joscarAdapter setNotes:notes forContactWithUID:[containedListContact UID]];
					}
				}
				
			} else if ([object isKindOfClass:[AIListContact class]]) {
				if ([(AIListContact *)object account] == self) {
					[joscarAdapter setNotes:notes forContactWithUID:[object UID]];
				}
			}
		}
	}
}

- (AIChat *)mainThreadChatWithName:(NSString *)name
{
	AIChat *chat;

/*	[[adium chatController] mainPerformSelector:@selector(chatWithName:onAccount:chatCreationInfo:)
									 withObject:name
									 withObject:self
									 withObject:nil
								  waitUntilDone:YES];*/
	[[adium chatController] chatWithName:name onAccount:self chatCreationInfo:nil];
	
	//Now return the existing chat
	chat = [[adium chatController] existingChatWithName:name onAccount:self];
	
	return chat;
}

#pragma mark Group Chat
/*
 * If the user sent an initial message, this will be triggered and have no effect.
 *
 * If a remote user sent an initial message, however, a chat will be created without being opened.  This call is our
 * cue to actually open chat.
 *
 * Another situation in which this is relevant is when we request joining a group chat; the chat should only be actually
 * opened once the server notifies us that we are in the room.
 *
 * This will ultimately call -[CBGaimAccount openChat:] below if the chat was not previously open.
 */
- (void)addChat:(AIChat *)chat
{
	[[adium notificationCenter] addObserver:self selector:@selector(chatClosed:) name:Chat_WillClose object:chat];
	//Open the chat
	[[adium interfaceController] openChat:chat]; 
}

- (void)setTypingFlagOfChat:(AIChat *)chat to:(NSNumber *)typingStateNumber
{
    AITypingState currentTypingState = [chat integerStatusObjectForKey:KEY_TYPING];
	AITypingState newTypingState = [typingStateNumber intValue];
	
    if (currentTypingState != newTypingState) {
		[chat setStatusObject:(newTypingState ? typingStateNumber : nil)
					   forKey:KEY_TYPING
					   notify:NotifyNow];
    }
}

- (void)inviteContact:(AIListContact *)inContact toChat:(AIChat *)chat withMessage:(NSString *)inviteMessage
{
	[joscarAdapter inviteUser:[inContact UID] toChat:[chat name] withMessage:inviteMessage];
}

- (void)inviteToChat:(NSString *)name fromContact:(NSString *)uid withMessage:(NSString *)message inviteObject:(id)invite
{
	NSString *inviteText = [NSString stringWithFormat:BASE_INVITE_TEXT, uid, message];
	ESTextAndButtonsWindowController *windowController;
#warning we need to get an icon that makes sense
	windowController = [ESTextAndButtonsWindowController showTextAndButtonsWindowWithTitle:CHAT_INVITE_TITLE
																			 defaultButton:ACCEPT_INVITE_TEXT
																		   alternateButton:REJECT_INVITE_TEXT
																			   otherButton:nil
																				  onWindow:nil
																		 withMessageHeader:nil
																				andMessage:[AIHTMLDecoder decodeHTML:inviteText]
																					 image:nil
																					target:self
																				  userInfo:invite];
}

- (void)textAndButtonsWindowDidEnd:(NSWindow *)window returnCode:(AITextAndButtonsReturnCode)returnCode userInfo:(id)userInfo
{
	[self addChat:[joscarAdapter handleChatInvitation:(id<ChatInvitation>)userInfo withDecision:(AITextAndButtonsDefaultReturn == returnCode)]];
	[window orderOut:self];
}

- (void)gotMessage:(NSString *)message onGroupChatNamed:(NSString *)name fromUID:(NSString *)uid
{
	AIChat				*chat = [self mainThreadChatWithName:name];
	AIContentMessage	*messageObject;
	AIListContact		*sourceContact = [self contactWithUID:uid];
	NSAttributedString *attributedMessage = [[adium contentController] decodedIncomingMessage:message
																				  fromContact:sourceContact
																					onAccount:self];
	
	messageObject = [AIContentMessage messageInChat:chat
										 withSource:[self contactWithUID:uid]
										destination:self
											   date:[NSDate date]
											message:attributedMessage
										  autoreply:NO]; //as far as I can tell group chats shouldn't see autoreplies
	[[adium contentController] receiveContentObject:messageObject];
	
	//We received a message; clear the typing state
	[chat setStatusObject:nil
				   forKey:KEY_TYPING
				   notify:NotifyNow];	
}

- (void)chatFailed:(NSString *)name
{	
	AIChat *chat = [self mainThreadChatWithName:name];
	AIContentStatus *status = [AIContentStatus statusInChat:chat 
												 withSource:chat 
												destination:self 
													   date:[NSDate date] 
													message:@"Error: A connection failure has occurred."
												   withType:@"group_chat_connection_failure"];
	NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
	[userInfo setObject:status forKey:@"AIContentObject"];
	[[adium notificationCenter] postNotificationName:Content_ContentObjectAdded object:userInfo userInfo:[userInfo autorelease]];
}

- (void)chatClosed:(NSNotification *)notif
{
	[joscarAdapter leaveGroupChatWithName:[(AIChat*)[notif object] name]];
}

- (void)objectsLeftChat:(NSArray *)objects chatName:(NSString *)name
{
	AIChat *chat = [self mainThreadChatWithName:name];
	NSEnumerator *iter = [objects objectEnumerator];
	NSString *uid;
	while ((uid = [iter nextObject]))
		[chat removeParticipatingListObject:[self contactWithUID:uid]];
}

- (void)objectsJoinedChat:(NSArray *)objects chatName:(NSString *)name
{
	AIChat *chat = [self mainThreadChatWithName:name];
	NSEnumerator *iter = [objects objectEnumerator];
	NSString *uid;
	while ((uid = [iter nextObject]))
		[chat addParticipatingListObject:[self contactWithUID:uid]];
}

- (NSString *)getSecurid
{
	return [RAFjoscarSecuridPromptController getSecuridForAccount:self];
}

#pragma mark Account Actions
- (void)goToURL:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender representedObject]]];
}

/*!
* @brief Menu items for the account's actions
 *
 * Returns an array of menu items for account-specific actions.  This is the best place to add protocol-specific
 * actions that aren't otherwise supported by Adium.  It will only be queried if the account is online.
 * @return NSArray of NSMenuItem instances for this account
 */
- (NSArray *)accountActionMenuItems
{
	if (![self online]) return nil;

	BOOL isICQ = isdigit([[self UID] characterAtIndex:0]);

	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSMenuItem		*menuItem;

	if (isICQ) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Change User Details", nil) stringByAppendingEllipsis]
																		 target:self
																		 action:@selector(goToURL:)
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:@"http://www.icq.com/whitepages/user_details.php"];
		[menuItemArray addObject:menuItem];
	}

	//Change Password
	//gchar *substituted = gaim_strreplace(od->authinfo->chpassurl, "%s", gaim_account_get_username(gaim_connection_get_account(gc)));

	menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[AILocalizedString(@"Configure IM Forwarding", nil) stringByAppendingEllipsis]
																	 target:self
																	 action:@selector(goToURL:)
															  keyEquivalent:@""] autorelease];
	[menuItem setRepresentedObject:@"http://mymobile.aol.com/dbreg/register?action=imf&clientID=1"];
	[menuItemArray addObject:menuItem];
	
	//[menuItemArray addObject:[NSMenuItem separatorItem]];
	
	if (isICQ) {
		//"Set Privacy Options..."
	} else {
		/*
		 "Confirm Account"
		 "Display Currently Registered E-Mail Address"
		 "Change Currently Registered E-Mail Address..."
		 */
	}
	
	//[menuItemArray addObject:[NSMenuItem separatorItem]];
	
	//"Show Buddies Awaiting Authorization"
	//[menuItemArray addObject:[NSMenuItem separatorItem]];

	//"Search for Buddy by E-Mail Address..."
	
	return menuItemArray;
}

- (void)requestAuthorization:(id)sender
{
	[joscarAdapter requestAuthorizationForContactWithUID:[[sender representedObject] UID]];
}

//Returns an array of menuItems specific for this contact based on its account and potentially status
- (NSArray *)menuItemsForContact:(AIListContact *)inContact
{
	BOOL isICQ = isdigit([[inContact UID] characterAtIndex:0]);

	NSMutableArray	*menuItemArray = [NSMutableArray array];
	NSMenuItem		*menuItem;
	
	if (isICQ) {
		menuItem = [[[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:AILocalizedString(@"Request Authorization", nil)
																		 target:self
																		 action:@selector(requestAuthorization:)
																  keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:inContact];
		[menuItemArray addObject:menuItem];
	}

	return menuItemArray;
}


@end

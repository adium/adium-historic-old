//
//  ESPurpleAIMAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleAIMAccount.h"
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import "SLPurpleCocoaAdapter.h"
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>

#define MAX_AVAILABLE_MESSAGE_LENGTH	58

@interface ESPurpleAIMAccount (PRIVATE)
- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString;
- (void)setFormattedUID;

- (void)updateInfo:(AIListContact *)theContact;
@end

@implementation ESPurpleAIMAccount

static BOOL				createdEncoders = NO;
static AIHTMLDecoder	*encoderCloseFontTagsAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderCloseFontTags = nil;
static AIHTMLDecoder	*encoderAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderGroupChat = nil;

#pragma mark Initialization and setup

- (const char *)protocolPlugin
{
    return "prpl-aim";
}

- (void)initAccount
{
	[super initAccount];

	//XXX
	[SLPurpleCocoaAdapter sharedInstance];

	arrayOfContactsForDelayedUpdates = nil;
	delayedSignonUpdateTimer = nil;
	
	if (!createdEncoders) {
		encoderCloseFontTagsAttachmentsAsText = [[AIHTMLDecoder alloc] init];
		[encoderCloseFontTagsAttachmentsAsText setIncludesHeaders:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesFontTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setClosesFontTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesStyleTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setIncludesColorTags:YES];
		[encoderCloseFontTagsAttachmentsAsText setEncodesNonASCII:NO];
		[encoderCloseFontTagsAttachmentsAsText setPreservesAllSpaces:NO];
		[encoderCloseFontTagsAttachmentsAsText setUsesAttachmentTextEquivalents:YES];
		[encoderCloseFontTagsAttachmentsAsText setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderCloseFontTagsAttachmentsAsText setOnlyUsesSimpleTags:NO];
		[encoderCloseFontTagsAttachmentsAsText setAllowAIMsubprofileLinks:YES];
		
		encoderCloseFontTags = [[AIHTMLDecoder alloc] init];
		[encoderCloseFontTags setIncludesHeaders:YES];
		[encoderCloseFontTags setIncludesFontTags:YES];
		[encoderCloseFontTags setClosesFontTags:YES];
		[encoderCloseFontTags setIncludesStyleTags:YES];
		[encoderCloseFontTags setIncludesColorTags:YES];
		[encoderCloseFontTags setEncodesNonASCII:NO];
		[encoderCloseFontTags setPreservesAllSpaces:NO];
		[encoderCloseFontTags setUsesAttachmentTextEquivalents:NO];
		[encoderCloseFontTags setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderCloseFontTags setOnlyUsesSimpleTags:NO];
		[encoderCloseFontTags setAllowAIMsubprofileLinks:YES];

		encoderAttachmentsAsText = [[AIHTMLDecoder alloc] init];
		[encoderAttachmentsAsText setIncludesHeaders:YES];
		[encoderAttachmentsAsText setIncludesFontTags:YES];
		[encoderAttachmentsAsText setClosesFontTags:NO];
		[encoderAttachmentsAsText setIncludesStyleTags:YES];
		[encoderAttachmentsAsText setIncludesColorTags:YES];
		[encoderAttachmentsAsText setEncodesNonASCII:NO];
		[encoderAttachmentsAsText setPreservesAllSpaces:NO];
		[encoderAttachmentsAsText setUsesAttachmentTextEquivalents:YES];
		[encoderAttachmentsAsText setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderAttachmentsAsText setOnlyUsesSimpleTags:NO];
		[encoderAttachmentsAsText setAllowAIMsubprofileLinks:YES];

		encoderGroupChat = [[AIHTMLDecoder alloc] init];
		[encoderGroupChat setIncludesHeaders:NO];
		[encoderGroupChat setIncludesFontTags:YES];
		[encoderGroupChat setClosesFontTags:NO];
		[encoderGroupChat setIncludesStyleTags:YES];
		[encoderGroupChat setIncludesColorTags:YES];
		[encoderGroupChat setEncodesNonASCII:NO];
		[encoderGroupChat setPreservesAllSpaces:NO];
		[encoderGroupChat setUsesAttachmentTextEquivalents:YES];
		[encoderGroupChat setOnlyConvertImageAttachmentsToIMGTagsWhenSendingAMessage:YES];
		[encoderGroupChat setOnlyUsesSimpleTags:YES];
		[encoderGroupChat setAllowAIMsubprofileLinks:YES];

		createdEncoders = YES;
	}

	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_NOTES];
}

- (void)dealloc
{
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[super dealloc];
}

#pragma mark Connectivity

/*!
* @brief We are connected.
 */
- (oneway void)accountConnectionConnected
{
	[super accountConnectionConnected];
	
	[self setFormattedUID];
}

/*!
* @brief Set the spacing and capitilization of our formatted UID serverside
 */
- (void)setFormattedUID
{
	NSString	*formattedUID;
	
	//Set our capitilization properly if necessary
	formattedUID = [self formattedUID];
	
	if (![[formattedUID lowercaseString] isEqualToString:formattedUID]) {
		
		//Remove trailing and leading whitespace
		formattedUID = [formattedUID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		[[self gaimThread] performSelector:@selector(OSCARSetFormatTo:onAccount:)
								withObject:formattedUID
								withObject:self
								afterDelay:5.0];
	}
}

#pragma mark Encoding attributed strings
//AIM doesn't require we close our tags, so don't waste the characters
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject
{
	NSString	*returnString;
	
	//We don't want to send HTML to ICQ users, or mobile phone users
	if (inListObject) {
		BOOL		nonHTMLUser;
		char		firstCharacter = [[inListObject UID] characterAtIndex:0];

	    nonHTMLUser = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
		
		if (nonHTMLUser) {
			returnString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];
		} else {
			returnString = [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString
																  imagesPath:nil];
		}

	} else {
		returnString = [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString
															  imagesPath:nil];
		AILog(@"Encoded to %@ for no contact",returnString);
	}
	
	return returnString;
}

- (NSString *)encodedAttributedStringForSendingContentMessage:(AIContentMessage *)inContentMessage
{		
	AIListObject *inListObject = [inContentMessage destination];
	NSAttributedString *inAttributedString = [inContentMessage message];

	if (inListObject) {
		BOOL		nonHTMLUser = NO;
		char		firstCharacter = [[inListObject UID] characterAtIndex:0];
		nonHTMLUser = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
		
		if (nonHTMLUser) {
			//We don't want to send HTML to ICQ users, or mobile phone users
			return ([[inAttributedString attributedStringByConvertingLinksToStrings] string]);
			
		} else {
			//We have a list object and are sending both to and from an AIM account; encode to HTML and look for outgoing images
			NSString	*returnString;
			
			returnString = [encoderCloseFontTags encodeHTML:inAttributedString
												 imagesPath:@"/tmp"];
			
			if ([returnString rangeOfString:@"<IMG " options:NSCaseInsensitiveSearch].location != NSNotFound) {
				//There's an image... we need to see about a Direct Connect, aborting the send attempt if none is established 
				//and sending after it is if one is established
				
				//Check for a PeerConnection for a direct IM currently open
				PeerConnection	*conn;
				OscarData		*od = (OscarData *)account->gc->proto_data;
				const char		*who = [[inListObject UID] UTF8String];
				
				conn = peer_connection_find_by_type(od, who, OSCAR_CAPABILITY_DIRECTIM);
				
				returnString = [self stringByProcessingImgTagsForDirectIM:returnString];

				if ((conn != NULL) && (conn->ready)) {
					//We have a connected dim already; simply continue, and we'll be told to send it in a moment
					
				} else {
					//Either no dim, or the dim we have is no longer conected (oscar_direct_im_initiate_immediately will reconnect it)						
					peer_connection_propose(od, OSCAR_CAPABILITY_DIRECTIM, who);
					
					//Add this content message to the sending queue for this contact to be sent once a connection is established
					if (!directIMQueue) directIMQueue = [[NSMutableDictionary alloc] init];
					
					NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[inListObject internalObjectID]];
					if (!thisContactQueue) {
						thisContactQueue = [NSMutableArray array];
						
						[directIMQueue setObject:thisContactQueue
										  forKey:[inListObject internalObjectID]];
					}
					
					[thisContactQueue addObject:inContentMessage];
				}
			}
			
			return (returnString);
		}

	} else { //Send HTML when signed in as an AIM account and we don't know what sort of user we are sending to (most likely multiuser chat)
		AILog(@"Encoding %@ for no contact",inAttributedString);
		return [encoderGroupChat encodeHTML:inAttributedString
								 imagesPath:nil];
	}
}

/*!
 * @brief Can we send images for this chat?
 */
- (BOOL)canSendImagesForChat:(AIChat *)inChat
{	
	if ([inChat isGroupChat]) return NO;

	OscarData *od = ((account && account->gc) ? account->gc->proto_data : NULL);
	if (od) {
		AIListObject *listObject = [inChat listObject];
		const char *contactUID = [[listObject UID] UTF8String];
		aim_userinfo_t *userinfo = aim_locate_finduserinfo(od, contactUID);
		
		if (userinfo &&
			aim_sncmp(purple_account_get_username(account), contactUID) &&
			[listObject online]) {
			return (userinfo->capabilities & OSCAR_CAPABILITY_DIRECTIM);

		} else {
			return NO;
		}

	} else {
		return NO;
	}
}

- (BOOL)sendMessageObject:(AIContentMessage *)inContentMessage
{
	if (directIMQueue) {
		NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[[inContentMessage destination] internalObjectID]];
		if ([thisContactQueue containsObject:inContentMessage]) {
			//This message is in our queue of messages to send...
			PeerConnection	*conn;
			OscarData		*od = (OscarData *)account->gc->proto_data;
			const char		*who = [[[inContentMessage destination] UID] UTF8String];
			
			conn = peer_connection_find_by_type(od, who, OSCAR_CAPABILITY_DIRECTIM);
			
			if ((conn != NULL) && (conn->ready)) {
				//We have a connected dim ready; send it!  We already displayed it, though, so don't do that.
				[inContentMessage setDisplayContent:NO];
				return [super sendMessageObject:inContentMessage];
			} else {
				//Don't send now, as we'll do the actual send when the dim is connected, in directIMConnected: above, and return here.
				return YES;				
			}
		}
	}

	return [super sendMessageObject:inContentMessage];
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* Remove various actions which are either duplicates of superior Adium actions (*grin*)
	 * or are just silly ("Confirm Account" for example). */
	if (strcmp(label, "Set Available Message...") == 0) {
		return nil;
	} else if (strcmp(label, "Format Screen Name...") == 0) {
		return nil;
	} else if (strcmp(label, "Confirm Account") == 0) {
		return nil;
	}

	return [super titleForAccountActionMenuLabel:label];
}

#pragma mark DirectIM (IM Image)
//We are now connected via DirectIM to theContact
- (void)directIMConnected:(AIListContact *)theContact
{
	AILog(@"Direct IM Connected: %@",[theContact UID]);

	[[adium contentController] displayEvent:AILocalizedString(@"Direct IM connected","Direct IM is an AIM-specific phrase for transferring images in the message window")
									 ofType:@"directIMConnected"
									 inChat:[[adium chatController] chatWithContact:theContact]];
	//Send any pending directIM messages for this contact
	NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[theContact internalObjectID]];
	if (thisContactQueue) {
		NSEnumerator	*enumerator;
		AIContentObject	*contentObject;
		
		enumerator = [thisContactQueue objectEnumerator];
		while ((contentObject = [enumerator nextObject])) {
			[[adium contentController] sendContentObject:contentObject];
		}
		
		[directIMQueue removeObjectForKey:[theContact internalObjectID]];
		
		if (![directIMQueue count]) {
			[directIMQueue release]; directIMQueue = nil;
		}
	}
}

- (void)directIMDisconnected:(AIListContact *)theContact
{
	AILog(@"Direct IM Disconnected: %@",[theContact UID]);	

	[[adium contentController] displayEvent:AILocalizedString(@"Direct IM disconnected","Direct IM is an AIM-specific phrase for transferring images in the message window")
									 ofType:@"directIMDisconnected"
									 inChat:[[adium chatController] chatWithContact:theContact]];	
}

- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString
{
	NSScanner			*scanner;

	static NSCharacterSet *elementEndCharacters = nil;
	if (!elementEndCharacters)
		elementEndCharacters = [[NSCharacterSet characterSetWithCharactersInString:@" >"] retain];
	static NSString		*tagStart = @"<", *tagEnd = @">";
	NSString			*chunkString;
	NSMutableString		*processedString;
	
    scanner = [NSScanner scannerWithString:inString];
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
        if ([scanner scanString:tagStart intoString:nil]) {
			//Get the tag itself
			if ([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]) {
				if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
					if ([scanner scanUpToString:tagEnd intoString:&chunkString]) {
						
						//Load the src image
						NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];
						NSString		*source = [imgArguments objectForKey:@"src"];
						NSString		*alt = [imgArguments objectForKey:@"alt"];
						NSString		*filename;
						NSData			*imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:source]];
						
						//Store the src image's data gaimside
						filename = (alt ? alt : [source lastPathComponent]);
						if (![[filename pathExtension] length]) {
							filename = [filename stringByAppendingPathExtension:@"png"];
						}

						int				imgstore = purple_imgstore_add([imageData bytes], [imageData length], [filename UTF8String]);

						AILog(@"Adding image id %i with name %s", [filename UTF8String]);

						NSString		*newTag = [NSString stringWithFormat:@"<IMG ID=\"%i\" CLASS=\"scaledToFitImage\">",imgstore];
						[processedString appendString:newTag];
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

#pragma mark Contact updates
- (oneway void)updateContact:(AIListContact *)theContact forEvent:(NSNumber *)event
{
	SEL updateSelector = nil;
	
	switch ([event intValue]) {
		case PURPLE_BUDDY_INFO_UPDATED: {
			updateSelector = @selector(updateInfo:);
			break;
		}
		case PURPLE_BUDDY_DIRECTIM_CONNECTED: {
			updateSelector = @selector(directIMConnected:);
			break;
		}
		case PURPLE_BUDDY_DIRECTIM_DISCONNECTED:{
			updateSelector = @selector(directIMDisconnected:);
			break;
		}
	}
	
	if (updateSelector) {
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateInfo:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	
	if (purple_account_is_connected(account) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od, [[theContact UID] UTF8String]))) {
		
		//Update the profile if necessary - length must be greater than one since we get "" with info_len 1
		//when attempting to retrieve the profile of an AOL member (which can't be done via AIM).
		if ((userinfo->info_len > 1) && (userinfo->info != NULL) && (userinfo->info_encoding != NULL)) {
			
			//Away message
			NSString *profileString = [self stringWithBytes:userinfo->info
													 length:userinfo->info_len
												   encoding:userinfo->info_encoding];
			
			NSString *oldProfileString = [theContact statusObjectForKey:@"TextProfileString"];
			
			if (profileString && [profileString length]) {
				if (![profileString isEqualToString:oldProfileString]) {
					
					//Due to OSCAR being silly, we can get a single control character as profileString.
					//This passes the [profileString length] check above, but we don't want to store it as our profile.
					NSAttributedString	*attributedProfile = [AIHTMLDecoder decodeHTML:profileString];
					if ([attributedProfile length]) {
						[theContact setStatusObject:attributedProfile
											 forKey:@"TextProfile" 
											 notify:NO];
					}

					//Store the string for comparison purposes later (since [attributedProfile string] != the HTML of the string,
					//					and we don't want to have to decode it just to compare it)
					[theContact setStatusObject:profileString
										 forKey:@"TextProfileString" 
										 notify:NO];
				}
			} else if (oldProfileString) {
				[theContact setStatusObject:nil forKey:@"TextProfileString" notify:NO];
				[theContact setStatusObject:nil forKey:@"TextProfile" notify:NO];	
			}
		}
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:NO];
	}
}	


#pragma mark Status
/*!
* @brief Encode an attributed string for a status type
 *
 * Away messages are HTML encoded.  Available messages are plaintext.
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forStatusState:(AIStatus *)statusState
{
	if (statusState && ([statusState statusType] == AIAvailableStatusType)) {
		NSString	*messageString = [[inAttributedString attributedStringByConvertingLinksToStrings] string];
		return [messageString stringWithEllipsisByTruncatingToLength:MAX_AVAILABLE_MESSAGE_LENGTH];
	} else {
		return [super encodedAttributedString:inAttributedString forStatusState:statusState];
	}
}

#pragma mark Suported keys
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys) {
		supportedPropertyKeys = [[NSMutableSet alloc] initWithObjects:
			@"AvailableMessage",
			@"Invisible",
			nil];
		[supportedPropertyKeys unionSet:[super supportedPropertyKeys]];
	}
	
	return supportedPropertyKeys;
}

#pragma mark Typing notifications

/*!
 * @brief Suppress typing notifications after send?
 *
 * AIM assumes that "typing stopped" is not explicitly stopped when the user sends.  This is particularly visible
 * in iChat. Returning YES here prevents messages sent to iChat from jumping up and down in ichat as the typing
 * notification is removed and then the incoming text is added.
 */
- (BOOL)suppressTypingNotificationChangesAfterSend
{
	return YES;
}

#pragma mark Group chat

- (void)addUser:(NSString *)contactName toChat:(AIChat *)chat newArrival:(NSNumber *)newArrival
{
	AIListContact *listContact;
	
	if ((chat) &&
		(listContact = [self contactWithUID:contactName])) {
		
		if (!namesAreCaseSensitive) {
			[listContact setStatusObject:contactName forKey:@"FormattedUID" notify:NotifyNow];
		}
		
		/* Purple incorrectly flags group chat participants as being on a mobile device... we're just going
		 * to assume that a contact in a group chat is by definition not on their cell phone. This assumption
		 * could become wrong in the future... we can deal with it more properly at that time. :P -eds
		 */	
		if ([listContact isMobile]) {
			[listContact setIsMobile:NO notify:NotifyLater];
			
			[listContact setStatusObject:nil
								  forKey:@"Client"
								  notify:NotifyLater];
			
			[listContact notifyOfChangedStatusSilently:NO];
		}
		
		[chat addParticipatingListObject:listContact notify:(newArrival && [newArrival boolValue])];
	}
}


@end

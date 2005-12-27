//
//  ESGaimAIMAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimAIMAccount.h"
#import "AIChatController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AIPreferenceController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>

#define MAX_AVAILABLE_MESSAGE_LENGTH	58

#define AOL_MOBILE_DEVICE AILocalizedString(@"AOL Mobile Device", "Phrase to describe the client through which a contact is connected mobilely; cell phones, for example, may be AOL Mobile Devices.")

@interface ESGaimAIMAccount (PRIVATE)
- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString;
- (void)setFormattedUID;

- (void)updateInfo:(AIListContact *)theContact;
- (void)updateMiscellaneous:(AIListContact *)theContact;

@end

@implementation ESGaimAIMAccount

static BOOL				createdEncoders = NO;
static AIHTMLDecoder	*encoderCloseFontTagsAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderCloseFontTags = nil;
static AIHTMLDecoder	*encoderAttachmentsAsText = nil;
static AIHTMLDecoder	*encoderGroupChat = nil;

#pragma mark Initialization and setup
- (void)initAccount
{
	[super initAccount];
	
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
#if 0
			if (GAIM_DEBUG) {
				//We have a list object and are sending both to and from an AIM account; encode to HTML and look for outgoing images
				NSString	*returnString;
				
				returnString = [encoderCloseFontTags encodeHTML:inAttributedString
													 imagesPath:@"/tmp"];
				
				if ([returnString rangeOfString:@"<IMG " options:NSCaseInsensitiveSearch].location != NSNotFound) {
					//There's an image... we need to see about a Direct Connect, aborting the send attempt if none is established 
					//and sending after it is if one is established

					//Check for a oscar_direct_im (dim) currently open
					struct oscar_direct_im  *dim;
					const char				*who = [[inListObject UID] UTF8String];
					
					dim = (struct oscar_direct_im  *)oscar_find_direct_im(account->gc, who);
					
					if (dim && (dim->connected)) {
						//We have a connected dim already; process the string and keep the modified copy
						returnString = [self stringByProcessingImgTagsForDirectIM:returnString];
						
					} else {
						//Either no dim, or the dim we have is no longer conected (oscar_direct_im_initiate_immediately will reconnect it)
						oscar_direct_im_initiate_immediately(account->gc, who);
						
						//Add this content message to the sending queue for this contact to be sent once a connection is established
						if (!directIMQueue) directIMQueue = [[NSMutableDictionary alloc] init];
						
						NSMutableArray	*thisContactQueue = [directIMQueue objectForKey:[inListObject internalObjectID]];
						if (!thisContactQueue) {
							thisContactQueue = [NSMutableArray array];
							
							[directIMQueue setObject:thisContactQueue
											  forKey:[inListObject internalObjectID]];
						}
						
						[thisContactQueue addObject:contentMessage];
						
						//Return nil for now to indicate that the message should not be sent
						returnString = nil;
					}
				}
				
				return (returnString);
				
			} else {
				//XXX - DirectIM is not ready for prime time.  Temporary.
				return [encoderAttachmentsAsText encodeHTML:inAttributedString
												 imagesPath:nil];
				
			}
#endif /* 0 */
			//XXX - DirectIM is not ready for prime time.  Temporary.
			return [encoderAttachmentsAsText encodeHTML:inAttributedString
											 imagesPath:nil];
		}
		
	} else { //Send HTML when signed in as an AIM account and we don't know what sort of user we are sending to (most likely multiuser chat)
		AILog(@"Encoding %@ for no contact",inAttributedString);
		return [encoderGroupChat encodeHTML:inAttributedString
								 imagesPath:nil];
	}
}

/*!
 * @brief Can we send images for this chat?
 *
 * @result YES if we are currently in a direct IM session or are connecting to one
 */
- (BOOL)canSendImagesForChat:(AIChat *)inChat
{
	if (inChat && [inChat listObject]) {
		//Check for a oscar_direct_im (dim) currently open
		struct oscar_direct_im  *dim;
		const char				*who = [[[inChat listObject] UID] UTF8String];

		if (account && account->gc && who) {
			//dim = (struct oscar_direct_im  *)oscar_find_direct_im(account->gc, who);
			dim = NULL;

			if (dim) {
				return YES;
			}
		}
	}
	
	return NO;
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if (strcmp(label, "Direct IM") == 0) {
		//XXX
		if (/*GAIM_DEBUG && */![[[inContact service] serviceID] isEqualToString:@"ICQ"]) {
			return [NSString stringWithFormat:AILocalizedString(@"Initiate Direct IM with %@",nil),[inContact formattedUID]];
		} else {
			return nil;
		}
	}

	return [super titleForContactMenuLabel:label forContact:inContact];
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

	[[adium contentController] displayStatusMessage:AILocalizedString(@"Direct IM connected","Direct IM is an AIM-specific phrase for transferring images in the message window")
											 ofType:@"directIM"
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

	[[adium contentController] displayStatusMessage:AILocalizedString(@"Direct IM disconnected","Direct IM is an AIM-specific phrase for transferring images in the message window")
											 ofType:@"directIM"
											 inChat:[[adium chatController] chatWithContact:theContact]];	
}

- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString
{
	NSScanner			*scanner;
	//    NSCharacterSet		*tagCharStart, *tagEnd, *absoluteTagEnd;
	static NSCharacterSet *elementEndCharacters = nil;
	if (!elementEndCharacters)
		elementEndCharacters = [[NSCharacterSet characterSetWithCharactersInString:@" >"] retain];
	static NSString		*tagStart = @"<", *tagEnd = @">";
	NSString			*chunkString;
	NSMutableString		*processedString;
	
	//    tagCharStart = [NSCharacterSet characterSetWithCharactersInString:@"<"];
	//    tagEnd = [NSCharacterSet characterSetWithCharactersInString:@" >"];
	//    absoluteTagEnd = [NSCharacterSet characterSetWithCharactersInString:@">"];
	
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
		
        //Process the tag
        if ([scanner scanString:tagStart intoString:nil]) { //If a tag wasn't found, we don't process.
														  //Get the tag itself
			if ([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]) {
				if ([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame) {
					if ([scanner scanUpToString:tagEnd intoString:&chunkString]) {
						
						//Load the src image
						NSDictionary	*imgArguments = [AIHTMLDecoder parseArguments:chunkString];
						NSString		*source = [imgArguments objectForKey:@"src"];
						NSString		*alt = [imgArguments objectForKey:@"alt"];
						
						NSData			*imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:source]];
						
						//Store the src image's data gaimside
						int				imgstore = gaim_imgstore_add([imageData bytes], [imageData length], (alt ? [alt UTF8String] : [source UTF8String]));
						
						NSString		*newTag = [NSString stringWithFormat:@"<IMG ID=\"%i\">",imgstore];
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
		case GAIM_BUDDY_INFO_UPDATED: {
			updateSelector = @selector(updateInfo:);
			break;
		}
		case GAIM_BUDDY_MISCELLANEOUS: {  
			updateSelector = @selector(updateMiscellaneous:);
			break;
		}
		case GAIM_BUDDY_DIRECTIM_CONNECTED: {
			updateSelector = @selector(directIMConnected:);
			break;
		}
		case GAIM_BUDDY_DIRECTIM_DISCONNECTED:{
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
	
	if (gaim_account_is_connected(account) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[theContact UID] UTF8String]))) {
		
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

- (void)updateMiscellaneous:(AIListContact *)theContact
{
	OscarData			*od;
	NSString			*theContactUID;
	aim_userinfo_t		*userinfo;
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) && 
		(theContactUID = [theContact UID]) && 
		(userinfo = aim_locate_finduserinfo(od->sess, [theContactUID UTF8String]))) {

		//Client
		NSString	*storedString = [theContact statusObjectForKey:@"Client"];
		NSString	*client = nil;
		BOOL		isMobile = NO;

		if (userinfo->present & AIM_USERINFO_PRESENT_FLAGS) {
			if (userinfo->capabilities & AIM_CAPS_HIPTOP) {
				client = AILocalizedString(@"AIM via Hiptop", "A 'Hiptop' is a mobile device; this phrase descibes a contact who is connected to AIM through a hiptop.");
				isMobile = YES;
				
			} else if (userinfo->flags & AIM_FLAG_WIRELESS) {
				/* Incorrectly called just before a contact is added to a group chat */
				if (![[adium chatController] contactIsInGroupChat:theContact]) {
					client = AOL_MOBILE_DEVICE;
					isMobile = YES;
				}
				
			} else if (userinfo->flags & AIM_FLAG_ADMINISTRATOR) {
				client = AILocalizedString(@"AOL Administrator", nil);
				
			} else if (userinfo->flags & AIM_FLAG_AOL) {
				client = AILocalizedString(@"America Online", nil);
			}/* else if ((userinfo->flags & AIM_FLAG_FREE) || (userinfo->flags & AIM_FLAG_UNCONFIRMED)) {
							client = @"AOL Instant Messenger";
			}*/
		}

		[theContact setIsMobile:isMobile notify:NotifyLater];

		if (client) {
			//Set the client if necessary
			if (storedString == nil || ![client isEqualToString:storedString]) {
				[theContact setStatusObject:client forKey:@"Client" notify:NotifyLater];
						
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		} else {
			//Clear the client value if one was present before
			if (storedString) {
				[theContact setStatusObject:nil forKey:@"Client" notify:NotifyLater];
						
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];	
			}
		}
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
		
		/* Gaim incorrectly flags group chat participants as being on a mobile device... we're just going
		 * to assume that a contact in a group chat is by definition not on their cell phone. This assumption
		 * could become wrong in the future... we can deal with it more properly at that time. :P -eds
		 */	
		if ([[listContact statusObjectForKey:@"Client"] isEqualToString:AOL_MOBILE_DEVICE]) {
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

//
//  ESGaimAIMAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2005 The Adium Team. All rights reserved.
//

#import "ESGaimAIMAccount.h"
#import "AIContactController.h"
#import "AIPreferenceController.h"
#import "SLGaimCocoaAdapter.h"
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/CBObjectAdditions.h>

#define DELAYED_UPDATE_INTERVAL			1.0
#define MAX_AVAILABLE_MESSAGE_LENGTH	59

@interface ESGaimAIMAccount (PRIVATE)
- (NSString *)serversideCommentForContact:(AIListContact *)theContact;
- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString;
- (void)setFormattedUID;
@end

@implementation ESGaimAIMAccount

#pragma mark Initialization and setup
- (void)initAccount
{
	[super initAccount];
	
	arrayOfContactsForDelayedUpdates = nil;
	delayedSignonUpdateTimer = nil;
	
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
	
	[[adium preferenceController] registerPreferenceObserver:self forGroup:PREF_GROUP_NOTES];
}

- (void)dealloc
{
	//Hmm.. we can't actually get here since we are retained by the preference controller as an observer.
	[[adium preferenceController] unregisterPreferenceObserver:self];
	
	[encoderCloseFontTagsAttachmentsAsText release];
	[encoderCloseFontTags release];
	[encoderAttachmentsAsText release];
	
	[super dealloc];
}


- (BOOL)shouldSetAliasesServerside
{
	return(YES);
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
	
	if (![[formattedUID lowercaseString] isEqualToString:formattedUID]){
		
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
	BOOL		nonHTMLUser = NO;
	NSString	*returnString;
	
	//We don't want to send HTML to ICQ users, or mobile phone users
	if(inListObject){
		char	firstCharacter = [[inListObject UID] characterAtIndex:0];
	    nonHTMLUser = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
	}
	
	if (nonHTMLUser){
		returnString = [inAttributedString string];
	}else{
		returnString = [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString
															  imagesPath:nil];
	}
	
	return returnString;
}

- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forListObject:(AIListObject *)inListObject contentMessage:(AIContentMessage *)contentMessage
{		
	if(inListObject){
		BOOL		nonHTMLUser = NO;
		char		firstCharacter = [[inListObject UID] characterAtIndex:0];
		nonHTMLUser = ((firstCharacter >= '0' && firstCharacter <= '9') || firstCharacter == '+');
		
		if (nonHTMLUser){
			//We don't want to send HTML to ICQ users, or mobile phone users
			return ([inAttributedString string]);
			
		}else{
			if (GAIM_DEBUG){
				//We have a list object and are sending both to and from an AIM account; encode to HTML and look for outgoing images
				NSString	*returnString;
				
				returnString = [encoderCloseFontTags encodeHTML:inAttributedString
													 imagesPath:@"/tmp"];
				
				if ([returnString rangeOfString:@"<IMG " options:NSCaseInsensitiveSearch].location != NSNotFound){
					//There's an image... we need to see about a Direct Connect, aborting the send attempt if none is established 
					//and sending after it is if one is established
					NSLog(@"No Direct Connect for you! Come back two year!");
					
					//Check for a oscar_direct_im (dim) currently open
					struct oscar_direct_im  *dim;
					const char				*who = [[inListObject UID] UTF8String];
					
					dim = (struct oscar_direct_im  *)oscar_find_direct_im(account->gc, who);
					
					if (dim && (dim->connected)){
						//We have a connected dim already; process the string and keep the modified copy
						returnString = [self stringByProcessingImgTagsForDirectIM:returnString];
						
					}else{
						//Either no dim, or the dim we have is no longer conected (oscar_direct_im_initiate_immediately will reconnect it)
						oscar_direct_im_initiate_immediately(account->gc, who);
						
						//Add this content message to the sending queue for this contact to be sent once a connection is established
						//XXX
						
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
		}
		
	}else{ //Send HTML when signed in as an AIM account and we don't know what sort of user we are sending to (most likely multiuser chat)
		return [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString
													  imagesPath:nil];
	}
}

-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to UTF-8
	NSStringEncoding	desiredEncoding = NSUTF8StringEncoding;

	//Only attempt to check encoding if we were passed one
	if (encoding && (encoding[0] != '\0')){
		NSString			*encodingString = [NSString stringWithUTF8String:encoding];

		if (encodingString){
			if ([encodingString rangeOfString:@"unicode-2-0"].location != NSNotFound){
				desiredEncoding = NSUnicodeStringEncoding;
			}else if ([encodingString rangeOfString:@"iso-8859-1"].location != NSNotFound){
				desiredEncoding = NSISOLatin1StringEncoding;
			}
		}
		
	}

	return [[[NSString alloc] initWithBytes:bytes length:length encoding:desiredEncoding] autorelease];
}


#pragma mark Delayed updates

- (void)gotGroupForContact:(AIListContact *)theContact
{
	if(theContact){
		if (!arrayOfContactsForDelayedUpdates) arrayOfContactsForDelayedUpdates = [[NSMutableArray array] retain];
		[arrayOfContactsForDelayedUpdates addObject:theContact];
		
		if (!delayedSignonUpdateTimer){
			delayedSignonUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:DELAYED_UPDATE_INTERVAL 
																		 target:self
																	   selector:@selector(_performDelayedUpdates:) 
																	   userInfo:nil 
																		repeats:YES] retain];
		}
	}
}

- (void)_performDelayedUpdates:(NSTimer *)timer
{
	if ([arrayOfContactsForDelayedUpdates count]){
		AIListContact *theContact = [arrayOfContactsForDelayedUpdates objectAtIndex:0];
		
		[theContact setStatusObject:[self serversideCommentForContact:theContact]
							 forKey:@"Notes"
							 notify:YES];
		
		[arrayOfContactsForDelayedUpdates removeObjectAtIndex:0];
		
	}else{
		[arrayOfContactsForDelayedUpdates release]; arrayOfContactsForDelayedUpdates = nil;
		[delayedSignonUpdateTimer invalidate]; [delayedSignonUpdateTimer release]; delayedSignonUpdateTimer = nil;
	}
}

#pragma mark Contact notes
-(NSString *)serversideCommentForContact:(AIListContact *)theContact
{	
	NSString *serversideComment = nil;
	
	if (gaim_account_is_connected(account)){
		const char  *uidUTF8String = [[theContact UID] UTF8String];
		GaimBuddy   *buddy;
		
		if (buddy = gaim_find_buddy(account, uidUTF8String)){
			GaimGroup   *g;
			char		*comment;
			OscarData   *od;
			
			if ((g = gaim_find_buddys_group(buddy)) &&
				(od = account->gc->proto_data) &&
				(comment = aim_ssi_getcomment(od->sess->ssi.local, g->name, buddy->name))){
				gchar		*comment_utf8;
				
				comment_utf8 = gaim_utf8_try_convert(comment);
				serversideComment = [NSString stringWithUTF8String:comment_utf8];
				g_free(comment_utf8);
				
				free(comment);
			}
		}
	}
	
	return(serversideComment);
}

- (void)preferencesChangedForGroup:(NSString *)group key:(NSString *)key
							object:(AIListObject *)object preferenceDict:(NSDictionary *)prefDict firstTime:(BOOL)firstTime
{
	[super preferencesChangedForGroup:group key:key object:object preferenceDict:prefDict firstTime:firstTime];
	
	if([group isEqualToString:PREF_GROUP_NOTES]){
		//If the notification object is a listContact belonging to this account, update the serverside information
		if (account &&
			[object isKindOfClass:[AIListContact class]] && 
			[(AIListContact *)object account] == self){
			
			if ([key isEqualToString:@"Notes"]){
				NSString  *comment = [object preferenceForKey:@"Notes" 
														group:PREF_GROUP_NOTES
										ignoreInheritedValues:YES];
				
				[[super gaimThread] OSCAREditComment:comment forUID:[object UID] onAccount:self];
			}			
		}
	}
}

#pragma mark File transfer

/*
 * @brief Allow a file transfer with an object?
 *
 * Only return YES if the user's capabilities include AIM_CAPS_SENDFILE indicating support for file transfer
 */
- (BOOL)allowFileTransferWithListObject:(AIListObject *)inListObject
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[inListObject UID] UTF8String]))){
		
		return (userinfo->capabilities & AIM_CAPS_SENDFILE);
	}
	
	return NO;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}

- (void)cancelFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super cancelFileTransfer:fileTransfer];
}

#pragma mark Contact List Menu Items
- (NSString *)titleForContactMenuLabel:(const char *)label forContact:(AIListContact *)inContact
{
	if(strcmp(label, "Edit Buddy Comment") == 0){
		return(nil);
	}else if(strcmp(label, "Direct IM") == 0){
		//XXX
		if (GAIM_DEBUG && ![[[inContact service] serviceID] isEqualToString:@"ICQ"]){
			return([NSString stringWithFormat:AILocalizedString(@"Initiate Direct IM with %@",nil),[inContact formattedUID]]);
		}else{
			return(nil);
		}
	}

	return([super titleForContactMenuLabel:label forContact:inContact]);
}

#pragma mark DirectIM (IM Image)
//We are now connected via DirectIM to theContact
- (void)directIMConnected:(AIListContact *)theContact
{
	//Send any pending directIM messages
	NSLog(@"Direct IM Connected: %@",[theContact UID]);
}
- (void)directIMDisconnected:(AIListContact *)theContact
{
	NSLog(@"Direct IM Disconnected: %@",[theContact UID]);	
}

- (NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString
{
	NSScanner			*scanner;
	//    NSCharacterSet		*tagCharStart, *tagEnd, *absoluteTagEnd;
	static NSCharacterSet *elementEndCharacters = nil;
	if(!elementEndCharacters)
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
    while(![scanner isAtEnd]){
        //Find an HTML IMG tag
        if([scanner scanUpToString:@"<img" intoString:&chunkString]){
			//Append the text leading up the the IMG tag; a directIM may have image tags inline with message text
            [processedString appendString:chunkString];
        }
		
        //Process the tag
        if([scanner scanString:tagStart intoString:nil]){ //If a tag wasn't found, we don't process.
														  //Get the tag itself
			if([scanner scanUpToCharactersFromSet:elementEndCharacters intoString:&chunkString]){
				if([chunkString caseInsensitiveCompare:@"IMG"] == NSOrderedSame){
					if([scanner scanUpToString:tagEnd intoString:&chunkString]){
						
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
				
				if (![scanner isAtEnd]){
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
	
	switch([event intValue]){
		case GAIM_BUDDY_STATUS_MESSAGE: {
			updateSelector = @selector(updateStatusMessage:);
			break;
		}
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
	
	if (updateSelector){
		[self performSelector:updateSelector
				   withObject:theContact];
	}
	
	[super updateContact:theContact forEvent:event];
}

- (void)updateStatusMessage:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	struct buddyinfo	*bi;
	const char			*uidUTF8String = [[theContact UID] UTF8String];
	
	NSLog(@"%@: Update status message for %@",self, theContact);
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, uidUTF8String))){
		
		GaimBuddy		*b;
		AIStatusType	statusType = (((b = gaim_find_buddy(account, uidUTF8String)) && (b->uc & UC_UNAVAILABLE)) ? 
									  AIAwayStatusType : 
									  AIAvailableStatusType);
		NSString		*statusMessage = nil;

		bi = g_hash_table_lookup(od->buddyinfo, uidUTF8String);
		
		if ((bi != NULL) && (bi->availmsg != NULL) && !(userinfo->flags & AIM_FLAG_AWAY)) {
			
			//Available status message - bi->availmsg has already been converted to UTF8 if needed for us.
			statusMessage = [NSString stringWithUTF8String:(bi->availmsg)];
			
		} else if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away != NULL)){
			if ((userinfo->away_len > 0) && 
				(userinfo->away_encoding != NULL)) {
				
				//Away message using specified encoding
				statusMessage = [self stringWithBytes:userinfo->away
											   length:userinfo->away_len
											 encoding:userinfo->away_encoding];
			}else{
				//Away message, no encoding provided, assume UTF8
				statusMessage = [NSString stringWithUTF8String:userinfo->away];
			}
		}
		
		//Update the status
		[theContact setStatusWithName:nil
						   statusType:statusType
						statusMessage:(statusMessage ? [AIHTMLDecoder decodeHTML:statusMessage] : nil)
							   notify:NotifyLater];
		
		//Apply the change
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
}


- (void)_updateAwayOfContact:(AIListContact *)theContact toAway:(BOOL)newAway
{
	[self updateStatusMessage:theContact];
}
- (void)updateInfo:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	
	if (gaim_account_is_connected(account) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, [[theContact UID] UTF8String]))){
		
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
					if([attributedProfile length]){
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
		(userinfo = aim_locate_finduserinfo(od->sess, [theContactUID UTF8String]))){
		
		/*
		 userinfo->membersince;
		 userinfo->capabilities;
		 */
		
		//Client
		NSString *storedString = [theContact statusObjectForKey:@"Client"];
		NSString *client = nil;
		
		if (userinfo->present & AIM_USERINFO_PRESENT_FLAGS) {
			if (userinfo->capabilities & AIM_CAPS_HIPTOP) {
				client = @"AIM via Hiptop";
			} else if (userinfo->flags & AIM_FLAG_WIRELESS) {
				client = @"AOL Mobile Device";
			} else if (userinfo->flags & AIM_FLAG_ADMINISTRATOR) {
				client = @"AOL Administrator";
			} else if (userinfo->flags & AIM_FLAG_AOL) {
				client = @"America Online";
			}/* else if ((userinfo->flags & AIM_FLAG_FREE) || (userinfo->flags & AIM_FLAG_UNCONFIRMED)) {
							client = @"AOL Instant Messenger";
			}*/
		}
		
		/*
		 if (b->name && (b->uc & 0xffff0000) && isdigit(b->name[0])) {
			 
			 //ICQ
			 int uc = b->uc >> 16;
			 if (uc & AIM_ICQ_STATE_INVISIBLE)
				 emblems[i++] = "invisible";
			 else if (uc & AIM_ICQ_STATE_CHAT)
				 emblems[i++] = "freeforchat";
			 else if (uc & AIM_ICQ_STATE_DND)
				 emblems[i++] = "dnd";
			 else if (uc & AIM_ICQ_STATE_OUT)
				 emblems[i++] = "na";
			 else if (uc & AIM_ICQ_STATE_BUSY)
				 emblems[i++] = "occupied";
			 else if (uc & AIM_ICQ_STATE_AWAY)
				 emblems[i++] = "away";
		 } else {
			 if (b->uc & UC_UNAVAILABLE) 
				 emblems[i++] = "away";
		 }
		 
		 if (b->uc & UC_WIRELESS)
		 emblems[i++] = "wireless";
		 if (b->uc & UC_AOL)
		 emblems[i++] = "aol";
		 if (b->uc & UC_ADMIN)
		 emblems[i++] = "admin";
		 if (b->uc & UC_AB && i < 4)
		 emblems[i++] = "activebuddy";
		 
		 if ((i < 4) && (userinfo != NULL) && (userinfo->capabilities & AIM_CAPS_HIPTOP))
		 emblems[i++] = "hiptop";
		 
		 if ((i < 4) && (userinfo != NULL) && (userinfo->capabilities & AIM_CAPS_SECUREIM))
		 emblems[i++] = "secure";
		 */
		
		if(client) {
			//Set the client if necessary
			if (storedString == nil || ![client isEqualToString:storedString]){
				[theContact setStatusObject:client forKey:@"Client" notify:NO];
				
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];
			}
		} else {
			//Clear the client value if one was present before
			if (storedString){
				[theContact setStatusObject:nil forKey:@"Client" notify:NO];
				
				//Apply any changes
				[theContact notifyOfChangedStatusSilently:silentAndDelayed];	
			}
		}
	}
}

#pragma mark Status
/*!
* @brief Perform the actual setting a state
 *
 * This is called by setStatusState.  It allows subclasses to perform any other behaviors, such as modifying a display
 * name, which are called for by the setting of the state; most of the processing has already been done, however, so
 * most subclasses will not need to implement this.
 *
 * @param statusState The AIStatus which is being set
 * @param gaimStatusType The status type which will be passed to Gaim, or NULL if Gaim's status will not be set for this account
 * @param statusMessage A properly encoded message which will be associated with the status if possible.
 */
- (void)setStatusState:(AIStatus *)statusState withGaimStatusType:(const char *)gaimStatusType andMessage:(NSString *)statusMessage
{
	if(!strcmp(gaimStatusType, "Available")){
		/*
		 * As of gaim 1.x, setting an available message in OSCAR requires a special call, not the normal
		 * serv_set_away() call. */
		
		//Set the available message, or clear it.  This also brings us back from away if necessary.
		[[self gaimThread] OSCARSetAvailableMessageTo:statusMessage onAccount:self];

	}else{
		[super setStatusState:statusState withGaimStatusType:gaimStatusType andMessage:statusMessage];
	}
}

/*!
* @brief Return the gaim status type to be used for a status
 *
 * Active services provided nonlocalized status names.  An AIStatus is passed to this method along with a pointer
 * to the status message.  This method should handle any status whose statusNname this service set as well as any statusName
 * defined in  AIStatusController.h (which will correspond to the services handled by Adium by default).
 * It should also handle a status name not specified in either of these places with a sane default, most likely by loooking at
 * [statusState statusType] for a general idea of the status's type.
 *
 * @param statusState The status for which to find the gaim status equivalent
 * @param statusMessage A pointer to the statusMessage.  Set *statusMessage to nil if it should not be used directly for this status.
 *
 * @result The gaim status equivalent
 */
- (char *)gaimStatusTypeForStatus:(AIStatus *)statusState
						  message:(NSAttributedString **)statusMessage
{
	AIStatusType	statusType = [statusState statusType];
	char			*gaimStatusType = NULL;
	
	//Only special case we need is for invisibility.
	if(statusType == AIInvisibleStatusType)
		gaimStatusType = "Invisible";
	
	//If we are setting one of our custom statuses, don't use a status message
	if(gaimStatusType != NULL) 	*statusMessage = nil;
	
	//If we didn't get a gaim status type, request one from super
	if(gaimStatusType == NULL) gaimStatusType = [super gaimStatusTypeForStatus:statusState message:statusMessage];
	
	return gaimStatusType;
}

/*!
* @brief Encode an attributed string for a status type
 *
 * Away messages are HTML encoded.  Available messages are plaintext.
 */
- (NSString *)encodedAttributedString:(NSAttributedString *)inAttributedString forGaimStatusType:(const char *)gaimStatusType
{
	if(!strcmp(gaimStatusType, "Available")){
		return([[inAttributedString string] stringWithEllipsisByTruncatingToLength:MAX_AVAILABLE_MESSAGE_LENGTH]);
	}else{
		return([super encodedAttributedString:inAttributedString forGaimStatusType:gaimStatusType]);
	}
}

#pragma mark Suported keys
- (NSSet *)supportedPropertyKeys
{
	static NSMutableSet *supportedPropertyKeys = nil;
	
	if (!supportedPropertyKeys){
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
	return(YES);
}
@end

//
//  CBGaimOscarAccount.m
//  Adium
//
//  Created by Colin Barrett on Thu Nov 06 2003.
//

#import "CBGaimOscarAccount.h"

#define KEY_OSCAR_HOST  @"Oscar:Host"
#define KEY_OSCAR_PORT  @"Oscar:Port"

#define DELAYED_UPDATE_INTERVAL		1.0

@interface CBGaimOscarAccount (PRIVATE)
-(NSString *)serversideCommentForContact:(AIListContact *)theContact;
-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
-(NSString *)stringByProcessingImgTagsForDirectIM:(NSString *)inString;
@end

@implementation CBGaimOscarAccount

static BOOL didInitOscar = NO;

- (const char*)protocolPlugin
{
	if (!didInitOscar){
		didInitOscar = gaim_init_oscar_plugin();
		if (!didInitOscar) NSLog(@"CBGaimOscarAccount: Oscar plugin failed to load.");
	}
	
    return "prpl-oscar";
}

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
	
}

- (void)dealloc
{
	[[adium notificationCenter] removeObserver:self];

	[encoderCloseFontTagsAttachmentsAsText release];
	[encoderCloseFontTags release];
	[encoderAttachmentsAsText release];

	[super dealloc];
}

- (BOOL)shouldSetAliasesServerside
{
	return(YES);
}

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
#warning DirectIM is not ready for prime time.  Temporary.
				return [encoderAttachmentsAsText encodeHTML:inAttributedString
												 imagesPath:nil];

			}
		}
		
	}else{ //Send HTML when signed in as an AIM account and we don't know what sort of user we are sending to (most likely multiuser chat)
		return [encoderCloseFontTagsAttachmentsAsText encodeHTML:inAttributedString
													  imagesPath:nil];
	}
}

//Override _contactWithUID to mark mobile and ICQ users as such via the displayServiceID
- (AIListContact *)_contactWithUID:(NSString *)sourceUID
{
	AIListContact	*contact;
	
	if (!namesAreCaseSensitive){
		sourceUID = [sourceUID compactedString];
	}
	
	contact = [[adium contactController] existingContactWithService:service
															account:self
																UID:sourceUID];
	if(!contact){
		contact = [[adium contactController] contactWithService:[self _serviceForUID:sourceUID]
														account:self
															UID:sourceUID];
	}
	
	return(contact);
}

- (AIService *)_serviceForUID:(NSString *)contactUID
{
	AIService	*contactService;
	NSString	*contactServiceID = nil;
	
	const char	firstCharacter = [contactUID characterAtIndex:0];
	
	//Determine service based on UID
	if([contactUID hasSuffix:@"@mac.com"]){
		contactServiceID = @"libgaim-oscar-Mac";
	}else if(firstCharacter >= '0' && firstCharacter <= '9'){
		contactServiceID = @"libgaim-oscar-ICQ";
	//		}else if(isMobile = (firstCharacter == '+')){
	//			contactServiceID = @"libgaim-oscar-AIM";
	}else{
		contactServiceID = @"libgaim-oscar-AIM";
	}
	
	contactService = [[adium accountController] serviceWithUniqueID:contactServiceID];
	
	return(contactService);
}
	
#pragma mark Account Connection

- (BOOL)shouldAttemptReconnectAfterDisconnectionError:(NSString *)disconnectionError
{
	BOOL shouldAttemptReconnect = YES;

	if (disconnectionError) {
		if ([disconnectionError rangeOfString:@"Incorrect nickname or password."].location != NSNotFound) {
			[[adium accountController] forgetPasswordForAccount:self];
		}else if ([disconnectionError rangeOfString:@"signed on with this screen name at another location"].location != NSNotFound) {
			shouldAttemptReconnect = NO;
		}else if ([disconnectionError rangeOfString:@"too frequently"].location != NSNotFound) {
			shouldAttemptReconnect = NO;	
		}
	}
	
	return shouldAttemptReconnect;
}

- (NSString *)connectionStringForStep:(int)step
{
	switch (step)
	{
		case 0:
			return AILocalizedString(@"Connecting",nil);
			break;
		case 1:
			return AILocalizedString(@"Screen name sent",nil);
			break;
		case 2:
			return AILocalizedString(@"Password sent",nil);
			break;			
		case 3:
			return AILocalizedString(@"Received authorization",nil);
			break;
		case 4:
			return AILocalizedString(@"Connection established",nil);
			break;
		case 5:
			return AILocalizedString(@"Finalizing connection",nil);
			break;
	}
	return nil;
}

- (NSString *)hostKey
{
	return KEY_OSCAR_HOST;
}
- (NSString *)portKey
{
	return KEY_OSCAR_PORT;
}

- (oneway void)accountConnectionConnected
{
	NSString	*formattedUID;
	
	[super accountConnectionConnected];

	//Set our capitilization properly if necessary
	formattedUID = [self formattedUID];

	if (![[formattedUID lowercaseString] isEqualToString:formattedUID]){
		
		//Remove trailing whitespace
		while([formattedUID hasSuffix:@" "]) formattedUID = [formattedUID substringToIndex:([formattedUID length]-1)];
		
		[[self gaimThread] performSelector:@selector(OSCARSetFormatTo:onAccount:)
								withObject:formattedUID
								withObject:self
								afterDelay:5.0];
	}
}

#pragma mark Buddy updates
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
	NSString			*statusMsgString = nil;
	NSString			*oldStatusMsgString = [theContact statusObjectForKey:@"StatusMessageString"];
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	struct buddyinfo	*bi;
	
	const char			*buddyName = [[theContact UID] UTF8String];
	
	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) &&
		(userinfo = aim_locate_finduserinfo(od->sess, buddyName))){
	
		bi = g_hash_table_lookup(od->buddyinfo, buddyName);
		
		if ((bi != NULL) && (bi->availmsg != NULL) && !(userinfo->flags & AIM_FLAG_AWAY)) {

			//Available status message - bi->availmsg has already been converted to UTF8 if needed for us.
			statusMsgString = [NSString stringWithUTF8String:(bi->availmsg)];
			
		} else if ((userinfo->flags & AIM_FLAG_AWAY) && (userinfo->away != NULL)){
			
			if ((userinfo->away_len > 0) && 
				(userinfo->away_encoding != NULL)) {
				
				//Away message using specified encoding
				statusMsgString = [self stringWithBytes:userinfo->away
												 length:userinfo->away_len
											   encoding:userinfo->away_encoding];
			}else{
				//Away message, no encoding provided, assume UTF8
				statusMsgString = [NSString stringWithUTF8String:userinfo->away];
			}
			
			//If the away message changed, make sure the contact is marked as away
			/*
			BOOL		newAway;
			NSNumber	*storedValue;
			
			newAway =  ((buddy->uc & UC_UNAVAILABLE) != 0);
			storedValue = [theContact statusObjectForKey:@"Away"];
			if((!newAway && (storedValue == nil)) || newAway != [storedValue boolValue]) {
				[theContact setStatusObject:[NSNumber numberWithBool:newAway] forKey:@"Away" notify:NO];
			}
			 */
		}
		
		//Update the status message if necessary
		if (statusMsgString && [statusMsgString length]) {
			if (![statusMsgString isEqualToString:oldStatusMsgString]) {
				[theContact setStatusObject:statusMsgString forKey:@"StatusMessageString" notify:NO];
				[theContact setStatusObject:[AIHTMLDecoder decodeHTML:statusMsgString]
									 forKey:@"StatusMessage"
									 notify:NO];
			}
		} else if (oldStatusMsgString) {
			[theContact setStatusObject:nil forKey:@"StatusMessageString" notify:NO];
			[theContact setStatusObject:nil forKey:@"StatusMessage" notify:NO];
		}
		
		//Apply any changes
		[theContact notifyOfChangedStatusSilently:silentAndDelayed];
	}
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
	aim_userinfo_t		*userinfo;

	if ((gaim_account_is_connected(account)) &&
		(od = account->gc->proto_data) && 
		(userinfo = aim_locate_finduserinfo(od->sess, [[theContact UID] UTF8String]))){
	
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

- (oneway void)updateUserInfo:(AIListContact *)theContact withData:(NSString *)userInfoString
{
	//For AIM contacts, we get profiles by themselves and don't want this userInfo with all its fields, so
	//we override this method to prevent the information from reaching the rest of Adium.
	
	//For ICQ contacts, however, we want to pass this data on as the profile
	const char	firstCharacter = [[theContact UID] characterAtIndex:0];
	
	if(firstCharacter >= '0' && firstCharacter <= '9'){
		[super updateUserInfo:theContact withData:userInfoString];
	}
}

#pragma mark Group Chat

- (BOOL)joinGroupChatNamed:(NSString *)name
{
	
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
    NSCharacterSet		*tagCharStart, *tagEnd, *absoluteTagEnd;
    NSString			*chunkString;
	NSMutableString		*processedString;
	
    tagCharStart = [NSCharacterSet characterSetWithCharactersInString:@"<"];
    tagEnd = [NSCharacterSet characterSetWithCharactersInString:@" >"];
    absoluteTagEnd = [NSCharacterSet characterSetWithCharactersInString:@">"];
	
    scanner = [NSScanner scannerWithString:inString];
	[scanner setCaseSensitive:NO];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
	processedString = [[NSMutableString alloc] init];
	
    //Parse the HTML
    while(![scanner isAtEnd]){
        //Find an HTML IMG tag
        if([scanner scanUpToString:@"<img" intoString:&chunkString]){
            [processedString appendString:chunkString];
        }
		
        //Process the tag
        if([scanner scanCharactersFromSet:tagCharStart intoString:nil]){ //If a tag wasn't found, we don't process.
																		 //            unsigned scanLocation = [scanner scanLocation]; //Remember our location (if this is an invalid tag we'll need to move back)
			
			//Get the tag itself
			if([scanner scanUpToCharactersFromSet:tagEnd intoString:&chunkString]){
				
				if([chunkString caseInsensitiveCompare:@"IMG"] == 0){
					if([scanner scanUpToCharactersFromSet:absoluteTagEnd intoString:&chunkString]){
						
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

#pragma mark Delayed updates

- (void)gotGroupForContact:(AIListContact *)theContact
{
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

- (NSArray *)contactStatusFlags
{
	static NSArray *contactStatusFlagsArray = nil;
	
	if (!contactStatusFlagsArray)
		contactStatusFlagsArray = [[[NSArray arrayWithObjects:@"StatusMessage",@"StatusMessageString",@"TextProfile",@"TextProfileString",nil] arrayByAddingObjectsFromArray:[super contactStatusFlags]] retain];
	
	return contactStatusFlagsArray;
}

/* Setting available message
struct oscar_data *od = gc->proto_data;
aim_srv_setavailmsg(od->sess, text);
*/

//This check is against the attributed string, not the HTML it creates... so it's worthless. :)
/*- (void)setProfile:(NSAttributedString *)profile
{
    if (profile){
        int length = [profile length];
        if (length > 1024){
            [[adium interfaceController] handleErrorMessage:@"Error Setting Profile"
                                            withDescription:[NSString stringWithFormat:@"Your info is too large, and could not be set.\r\rAIM and ICQ limit profiles to 1024 characters (Your current profile is %i characters)",length]];
        }else{
            [super setProfile:profile];
        }
    }else{
        [super setProfile:profile];
    }
}*/

#pragma mark File transfer
- (void)beginSendOfFileTransfer:(ESFileTransfer *)fileTransfer
{
	[super _beginSendOfFileTransfer:fileTransfer];
}

- (GaimXfer *)newOutgoingXferForFileTransfer:(ESFileTransfer *)fileTransfer
{
	if (gaim_account_is_connected(account)){
		char *destsn = (char *)[[[fileTransfer contact] UID] UTF8String];

		return oscar_xfer_new(account->gc,destsn);
	}
	
	return nil;
}

- (void)acceptFileTransferRequest:(ESFileTransfer *)fileTransfer
{
    [super acceptFileTransferRequest:fileTransfer];    
}

- (void)rejectFileReceiveRequest:(ESFileTransfer *)fileTransfer
{
    [super rejectFileReceiveRequest:fileTransfer];    
}


//Only return YES if the user's capabilities include AIM_CAPS_SENDFILE indicating support for file transfer
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

#pragma mark Privacy
-(BOOL)addListObject:(AIListObject *)inObject toPrivacyList:(PRIVACY_TYPE)type
{
    return [super addListObject:inObject toPrivacyList:type];
}
-(BOOL)removeListObject:(AIListObject *)inObject fromPrivacyList:(PRIVACY_TYPE)type
{
    return [super removeListObject:inObject fromPrivacyList:type]; 
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
- (void)preferencesChanged:(NSNotification *)notification
{
	[super preferencesChanged:notification];
	
	NSDictionary	*userInfo = [notification userInfo];
	NSString		*prefGroup = [userInfo objectForKey:@"Group"];
	
    if([prefGroup isEqualToString:PREF_GROUP_NOTES]){
		AIListObject *listObject = [notification object];
		
		//If the notification object is a listContact belonging to this account, update the serverside information
		if (account &&
			[listObject isKindOfClass:[AIListContact class]] && 
			[(AIListContact *)listObject account] == self){
			
			if ([[userInfo objectForKey:@"Key"] isEqualToString:@"Notes"]){
				
				NSString  *comment = [listObject preferenceForKey:@"Notes" 
															group:PREF_GROUP_NOTES
											ignoreInheritedValues:YES];
				
				[[super gaimThread] OSCAREditComment:comment forUID:[listObject UID] onAccount:self];
			}			
		}
	}
}

-(NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to ASCII
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
	
	//NSLog(@"[%s] [%i] [%i - %s]",bytes,length,desiredEncoding,encoding);

	return [[[NSString alloc] initWithBytes:bytes length:length encoding:desiredEncoding] autorelease];
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
	}else if(strcmp(label, "Re-request Authorization") == 0){
		return([NSString stringWithFormat:AILocalizedString(@"Re-request Authorization from %@",nil),[inContact formattedUID]]);
	}
	
	return([super titleForContactMenuLabel:label forContact:inContact]);
}

@end
#pragma mark Coding Notes

/*if (isdigit(b->name[0])) {
char *status;
status = gaim_icq_status((b->uc & 0xffff0000) >> 16);
tmp = ret;
ret = g_strconcat(tmp, _("<b>Status:</b> "), status, "\n", NULL);
g_free(tmp);
g_free(status);
}

if ((bi != NULL) && (bi->ipaddr)) {
    char *tstr =  g_strdup_printf("%hhd.%hhd.%hhd.%hhd",
                                  (bi->ipaddr & 0xff000000) >> 24,
                                  (bi->ipaddr & 0x00ff0000) >> 16,
                                  (bi->ipaddr & 0x0000ff00) >> 8,
                                  (bi->ipaddr & 0x000000ff));
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>IP Address:</b> "), tstr, "\n", NULL);
    g_free(tmp);
    g_free(tstr);
}

if ((userinfo != NULL) && (userinfo->capabilities)) {
    char *caps = caps_string(userinfo->capabilities);
    tmp = ret;
    ret = g_strconcat(tmp, _("<b>Capabilities:</b> "), caps, "\n", NULL);
    g_free(tmp);
}

static void oscar_ask_direct_im(GaimBlistNode *node, gpointer ignored);

*/

#if 0
//**Adium
GaimXfer *oscar_xfer_new(GaimConnection *gc, const char *destsn) {
	OscarData *od = (OscarData *)gc->proto_data;
	GaimXfer *xfer;
	struct aim_oft_info *oft_info;
	
	/* You want to send a file to someone else, you're so generous */
	
	/* Build the file transfer handle */
	xfer = gaim_xfer_new(gaim_connection_get_account(gc), GAIM_XFER_SEND, destsn);
	xfer->local_port = 5190;
	
	/* Create the oscar-specific data */
	oft_info = aim_oft_createinfo(od->sess, NULL, destsn, xfer->local_ip, xfer->local_port, 0, 0, NULL);
	xfer->data = oft_info;
	
	/* Setup our I/O op functions */
	gaim_xfer_set_init_fnc(xfer, oscar_xfer_init);
	gaim_xfer_set_start_fnc(xfer, oscar_xfer_start);
	gaim_xfer_set_end_fnc(xfer, oscar_xfer_end);
	gaim_xfer_set_cancel_send_fnc(xfer, oscar_xfer_cancel_send);
	gaim_xfer_set_cancel_recv_fnc(xfer, oscar_xfer_cancel_recv);
	gaim_xfer_set_ack_fnc(xfer, oscar_xfer_ack);
	
	/* Keep track of this transfer for later */
	od->file_transfers = g_slist_append(od->file_transfers, xfer);
	
	return xfer;
}
#endif

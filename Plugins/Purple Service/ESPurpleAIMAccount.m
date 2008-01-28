//
//  ESPurpleAIMAccount.m
//  Adium
//
//  Created by Evan Schoenberg on 2/23/05.
//  Copyright 2006 The Adium Team. All rights reserved.
//

#import "ESPurpleAIMAccount.h"
#import <AdiumLibpurple/SLPurpleCocoaAdapter.h>
#import <Adium/AIPreferenceControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChat.h>
#import <Adium/AIHTMLDecoder.h>
#import <Adium/AIListContact.h>
#import <Adium/AIService.h>
#import <Adium/AIContentMessage.h>
#import <AIUtilities/AIAttributedStringAdditions.h>
#import <AIUtilities/AIStringAdditions.h>
#import <AIUtilities/AIObjectAdditions.h>

#define MAX_AVAILABLE_MESSAGE_LENGTH	249

@interface ESPurpleAIMAccount (PRIVATE)
- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding;
- (void)setFormattedUID;

- (void)updateInfo:(AIListContact *)theContact;
@end

@implementation ESPurpleAIMAccount

#pragma mark Initialization and setup

- (const char *)protocolPlugin
{
    return "prpl-aim";
}

- (void)initAccount
{
	[super initAccount];

	arrayOfContactsForDelayedUpdates = nil;
	delayedSignonUpdateTimer = nil;
	
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
		
		[[self purpleThread] performSelector:@selector(OSCARSetFormatTo:onAccount:)
								withObject:formattedUID
								withObject:self
								afterDelay:5.0];
	}
}

#pragma mark Account Action Menu Items
- (NSString *)titleForAccountActionMenuLabel:(const char *)label
{
	/* Remove various actions which are either duplicates of superior Adium actions (*grin*)
	 * or are just silly ("Confirm Account" for example). */
	if (strcmp(label, _("Set Available Message...")) == 0) {
		return nil;
	} else if (strcmp(label, _("Format Screen Name...")) == 0) {
		return nil;
	} else if (strcmp(label, _("Confirm Account")) == 0) {
		return nil;
	}

	return [super titleForAccountActionMenuLabel:label];
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

- (NSString *)stringWithBytes:(const char *)bytes length:(int)length encoding:(const char *)encoding
{
	//Default to UTF-8
	NSStringEncoding	desiredEncoding = NSUTF8StringEncoding;
	
	//Only attempt to check encoding if we were passed one
	if (encoding && (encoding[0] != '\0')) {
		NSString	*encodingString = [NSString stringWithUTF8String:encoding];
		NSRange		encodingRange;
		
		encodingRange = (encodingString ? [encodingString rangeOfString:@"charset=\""] : NSMakeRange(NSNotFound, 0));
		if (encodingRange.location != NSNotFound) {
			encodingString = [encodingString substringWithRange:NSMakeRange(NSMaxRange(encodingRange),
																			[encodingString length] - NSMaxRange(encodingRange) - 1)];
			if (encodingString && [encodingString length]) {
				desiredEncoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingString));
				
				if (desiredEncoding == kCFStringEncodingInvalidId) {
					desiredEncoding = NSUTF8StringEncoding;
				}
			}
		}
	}
	
	return [[[NSString alloc] initWithBytes:bytes length:length encoding:desiredEncoding] autorelease];
}

- (void)updateInfo:(AIListContact *)theContact
{
	OscarData			*od;
	aim_userinfo_t		*userinfo;
	
	if (purple_account_is_connected(account) &&
		(od = purple_account_get_connection(account)->proto_data) &&
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

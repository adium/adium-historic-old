/* 
 * Adium is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Adium/AIAccount.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIChatControllerProtocol.h>
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIStatusControllerProtocol.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIListContact.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIUserIcons.h>
#import <Adium/ESFileTransfer.h>
#import <Adium/AIHTMLDecoder.h>

#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIMutableStringAdditions.h>

#include <AvailabilityMacros.h>

#import "ESAddressBookIntegrationPlugin.h"

#define KEY_BASE_WRITING_DIRECTION		@"Base Writing Direction"
#define PREF_GROUP_WRITING_DIRECTION	@"Writing Direction"

#define CONTACT_SIGN_ON_OR_OFF_PERSISTENCE_DELAY 15

@implementation AIListContact

//Init with an account
- (id)initWithUID:(NSString *)inUID account:(AIAccount *)inAccount service:(AIService *)inService
{
    [self initWithUID:inUID service:inService];
	
	account = [inAccount retain];
	
    return self;
}

//Standard init
- (id)initWithUID:(NSString *)inUID service:(AIService *)inService
{
	[super initWithUID:inUID service:inService];

	account = nil;
	remoteGroupName = nil;
	internalUniqueObjectID = nil;
	
	return self;
}

//Dealloc
- (void)dealloc
{
	[account release]; account = nil;
    [remoteGroupName release]; remoteGroupName = nil;
    [internalUniqueObjectID release]; internalUniqueObjectID = nil;
	
    [super dealloc];
}

//The account that owns this contact
- (AIAccount *)account
{
	return account;
}

/*!
 * @brief Set the UID of this contact
 *
 * The UID for an AIListContact generally shouldn't change... if the contact is actually renamed serverside, however,
 * it is useful to change the UID without having to change everything else associated with it.
 */
- (void)setUID:(NSString *)inUID
{
	if (UID != inUID) {
		[UID release]; UID = [inUID retain];
		[internalObjectID release]; internalObjectID = nil;
		[internalUniqueObjectID release]; internalUniqueObjectID = nil;		
	}
}

//An object ID generated by Adium that is completely unique to this contact.  This ID is generated from the service ID, 
//UID, and account UID.  Adium will not allow multiple contacts with the same internalUniqueObjectID to be created.
- (NSString *)internalUniqueObjectID
{
	if (!internalUniqueObjectID) {
		internalUniqueObjectID = [[AIListContact internalUniqueObjectIDForService:[self service]
																		  account:[self account]
																			  UID:[self UID]] retain];
	}
	return internalUniqueObjectID;
}

//Generate a unique object ID for the passed object
+ (NSString *)internalUniqueObjectIDForService:(AIService *)inService account:(AIAccount *)inAccount UID:(NSString *)inUID
{
	return [NSString stringWithFormat:@"%@.%@.%@", [inService serviceClass], [inAccount UID], inUID];
}


//Remote Grouping ------------------------------------------------------------------------------------------------------
#pragma mark Remote Grouping
//Set the desired group for this contact.  Pass nil to indicate this object is no longer listed.
- (void)setRemoteGroupName:(NSString *)inName
{
	if ((!remoteGroupName && inName) || ![inName isEqualToString:remoteGroupName]) {
		if (!remoteGroupName || !inName)
			[AIUserIcons flushCacheForObject:self];

		if (remoteGroupName != inName) {
			[remoteGroupName release];
			remoteGroupName = [inName retain];
		}
		[[adium contactController] listObjectRemoteGroupingChanged:self];
		
		AIListObject	*myContainingObject = [self containingObject];
		if ([myContainingObject isKindOfClass:[AIMetaContact class]]) {
			[(AIMetaContact *)myContainingObject remoteGroupingOfContainedObject:self changedTo:remoteGroupName];
		}
	}
}

//The current desired group of this contact
- (NSString *)remoteGroupName
{
	return remoteGroupName;
}

//An AIListContact normally groups based on its remoteGroupName (if it is not within a metaContact). 
//Restore this grouping.
- (void)restoreGrouping
{
	[[adium contactController] listObjectRemoteGroupingChanged:self];
}

#pragma mark Names
/*!
 * @brief Display name
 *
 * Display name, drawing first from any externally-provided display name, then falling back to 
 * the formatted UID.
 *
 * A listContact attempts to have the same displayName as its containing contact (potentially its metaContact).
 * If it is not in a metaContact, its display name is returned by [super displayName]
 */
- (NSString *)displayName
{
	AIListContact	*parentContact = [self parentContact];
    NSString		*displayName;

	displayName = ((parentContact == self) ?
				   [super displayName] :
				   [parentContact displayName]);

	//If a display name was found, return it; otherwise, return the formattedUID  
    return displayName ? displayName : [self formattedUID];
}

/*!
 * @brief Own display name
 *
 * Returns the display name without trying to account for a metaContact. Exists for use by AIMetaContact to avoid
 * infinite recursion by its displayName calling our displayName calling its displayName and so on.
 */
- (NSString *)ownDisplayName
{
	return [super displayName];
}

/*!
 * @brief This contact's serverside display name, which is generally specificed by the contact remotely
 *
 * @result The serverside display name, or nil if none is set
 */
- (NSString *)serversideDisplayName
{
	return [self valueForProperty:@"Server Display Name"];	
}

- (BOOL)canContainOtherContacts {
    return NO;
}

- (void)setServersideAlias:(NSString *)alias 
		   asStatusMessage:(BOOL)useAsStatusMessage
				  silently:(BOOL)silent
{
	BOOL changes = NO;
	BOOL displayNameChanges = NO;
	
	//This is the server display name.  Set it as such.
	if (![alias isEqualToString:[self valueForProperty:@"Server Display Name"]]) {
		//Set the server display name property as the full display name
		[self setValue:alias
					   forProperty:@"Server Display Name"
					   notify:NotifyLater];
		
		changes = YES;
	}

	NSMutableString *cleanedAlias;
	
	//Remove any newlines, since we won't want them anywhere below
	cleanedAlias = [alias mutableCopy];
	[cleanedAlias convertNewlinesToSlashes];

	//Use it either as the status message or the display name.
	if (useAsStatusMessage) {
		if (![[self stringFromAttributedStringValueForProperty:@"ContactListDisplayName"] isEqualToString:cleanedAlias]) {
			[self setValue:[[[NSAttributedString alloc] initWithString:cleanedAlias] autorelease]
						   forProperty:@"ContactListDisplayName" 
						   notify:NotifyLater];
			
			changes = YES;
		}
		
	} else {
		AIMutableOwnerArray	*displayNameArray = [self displayArrayForKey:@"Display Name"];
		NSString			*oldDisplayName = [displayNameArray objectValue];

		//If the mutableOwnerArray's current value isn't identical to this alias, we should set it
		if (![[displayNameArray objectWithOwner:[self account]] isEqualToString:cleanedAlias]) {
			[displayNameArray setObject:cleanedAlias
							  withOwner:[self account]
						  priorityLevel:Low_Priority];
			
			//If this causes the object value to change, we need to request a manual update of the display name
			if (oldDisplayName != [displayNameArray objectValue]) {
				displayNameChanges = YES;
			}
		}
	}
	
	if (changes) {
		//Apply any changes
		[self notifyOfChangedPropertiesSilently:silent];
	}
	
	if (displayNameChanges) {
		//Request an alias change
		[[adium notificationCenter] postNotificationName:Contact_ApplyDisplayName
												  object:self
												userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
																					 forKey:@"Notify"]];
	}
	
	[cleanedAlias release];
}

/*!
 * @brief The way this object's name should be spoken
 *
 * If not found, the display name is returned.
 */
- (NSString *)phoneticName
{
	AIListContact	*parentContact = [self parentContact];
	NSString		*phoneticName;

	phoneticName = ((parentContact == self) ?
				   [super phoneticName] :
				   [parentContact phoneticName]);
	
	//If a display name was found, return it; otherwise, return the formattedUID
    return phoneticName ? phoneticName : [self displayName];
}

/*!
 * @brief Own phonetic name
 *
 * Returns the phonetic name without trying to account for a metaContact. Exists for use by AIMetaContact to avoid
 * infinite recursion by its phoneticName calling our phoneticName calling its phoneticName and so on.
 */
- (NSString *)ownPhoneticName
{
	return [super phoneticName];
}

#pragma mark Properties

/*!
 * @brief Set online
 */
- (void)setOnline:(BOOL)online notify:(NotifyTiming)notify silently:(BOOL)silent
{
	if (online != [self online]) {
		[self setValue:(online ? [NSNumber numberWithBool:YES] : nil)
					   forProperty:@"Online"
					   notify:notify];
		
		if (!silent) {
			[self setValue:[NSNumber numberWithBool:YES] 
						   forProperty:(online ? @"Signed On" : @"Signed Off")
						   notify:notify];
			[self setValue:nil 
						   forProperty:(online ? @"Signed Off" : @"Signed On")
						   notify:notify];
			[self setValue:nil
						   forProperty:(online ? @"Signed On" : @"Signed Off")
					   afterDelay:CONTACT_SIGN_ON_OR_OFF_PERSISTENCE_DELAY];
		}
		
		if (online) {
			if (notify == NotifyNow) {
				[self notifyOfChangedPropertiesSilently:silent];
			}
			
		} else {
			//Will always notify
			[[self account] removePropetyValuesFromContact:self
												  silently:silent];	
		}
	}
}

/*!
 * @brief Set the sign on date
 */
- (void)setSignonDate:(NSDate *)signonDate notify:(NotifyTiming)notify
{
	[self setValue:signonDate
				   forProperty:@"Signon Date"
				   notify:notify];
}
/*!
 * @brief Date this contact signed on, if available
 */
- (NSDate *)signonDate
{
	return [self valueForProperty:@"Signon Date"];
}

/*!
 * @brief Set the idle state
 *
 * @param isIdle YES if the contact is idle
 * @param idleSinceDate The date this contact went idle. Only relevant if isIdle is YES
 * @param noitfy The NotifyTiming
 */
- (void)setIdle:(BOOL)isIdle sinceDate:(NSDate *)idleSinceDate notify:(NotifyTiming)notify
{
	if (isIdle) {
		if (idleSinceDate) {
			[self setValue:idleSinceDate
						   forProperty:@"IdleSince"
						   notify:NotifyLater];
		} else {
			//No idleSinceDate means we are Idle but don't know how long, so set to -1
			[self setValue:[NSNumber numberWithInt:-1]
						   forProperty:@"Idle"
						   notify:NotifyLater];
		}
	} else {
		[self setValue:nil
					   forProperty:@"IdleSince"
					   notify:NotifyLater];
		[self setValue:nil
					   forProperty:@"Idle"
					   notify:NotifyLater];
	}
	
	/* @"Idle", for a contact with an IdleSince date, will be changing every minute.  @"IsIdle" provides observers a way
	* to perform an action when the contact becomes/comes back from idle, regardless of whether an IdleSince is available,
	* without having to do that action every minute for other contacts.
	*/
	[self setValue:(isIdle ? [NSNumber numberWithBool:YES] : nil)
				   forProperty:@"IsIdle"
				   notify:NotifyLater];
	
	//Apply any changes
	if (notify == NotifyNow) {
		[self notifyOfChangedPropertiesSilently:NO];
	}
}

- (void)setServersideIconData:(NSData *)iconData notify:(NotifyTiming)notify
{
	[AIUserIcons setServersideIconData:iconData forObject:self notify:notify];
}

/*!
 * @brief Set the warning level
 *
 * @param warningLevel The warning level, an integer between 0 and 100
 */
- (void)setWarningLevel:(int)warningLevel notify:(NotifyTiming)notify
{
	if (warningLevel != [self warningLevel]) {
		[self setValue:[NSNumber numberWithInt:warningLevel]
					   forProperty:@"Warning"
					   notify:notify];
	}
}

/*!
 * @brief Warning level
 *
 * @result The warning level, an integer between 0 and 100
 */
- (int)warningLevel
{
	return [self integerValueForProperty:@"Warning"];
}

/*!
 * @brief Set the profile array
 */
- (void)setProfileArray:(NSArray *)array notify:(NotifyTiming)notify
{
	[self setValue:array
	   forProperty:@"ProfileArray"
			notify:notify];
}

/*!
 * @brief The profile array
 */
- (NSArray *)profileArray
{
	return [self valueForProperty:@"ProfileArray"];	
}

/*!
 * @brief Set the profile
 */
- (void)setProfile:(NSAttributedString *)profile notify:(NotifyTiming)notify
{
	[self setValue:profile
				   forProperty:@"TextProfile" 
				   notify:notify];
}

/*!
 * @brief Profile
 */
- (NSAttributedString *)profile
{
	return [self valueForProperty:@"TextProfile"];
}

/*!
 * @brief Is this contact a stranger?
 * 
 * A listContact is a stranger if it has a nil remoteGroupName
 */
- (BOOL)isStranger
{
	return ![self integerValueForProperty:@"NotAStranger"];
}

/*!
 * @brief If this contact intentionally on the contact list?
 */
- (BOOL)isIntentionallyNotAStranger
{
	return ![self isStranger] && [[self account] isContactIntentionallyListed:self];
}

/*!
 * @brief Is this object connected via a mobile device?
 */
- (BOOL)isMobile
{
	return [self integerValueForProperty:@"IsMobile" fromAnyContainedObject:NO];
}

/*!
 * @brief Set if this contact is mobile
 */
- (void)setIsMobile:(BOOL)isMobile notify:(NotifyTiming)notify
{
	[self setValue:(isMobile ? [NSNumber numberWithBool:isMobile] : nil)
				   forProperty:@"IsMobile"
				   notify:notify];
}

/*!
 * @brief Is this contact blocked?
 *
 * @result A boolean indicating if the contact is blocked or not
 */
- (BOOL)isBlocked
{
	return [self integerValueForProperty:KEY_IS_BLOCKED];
}

- (void)setIsBlocked:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists
{
	[self setIsOnPrivacyList:yesOrNo updateList:addToPrivacyLists privacyType:AIPrivacyTypeDeny];
}

- (void)setIsAllowed:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists
{
	[self setIsOnPrivacyList:yesOrNo updateList:addToPrivacyLists privacyType:AIPrivacyTypePermit];
}

/*!
 * @brief Set if this contact is on the privacy list
 */
- (void)setIsOnPrivacyList:(BOOL)yesOrNo updateList:(BOOL)addToPrivacyLists privacyType:(AIPrivacyType)privType
{
	if (addToPrivacyLists) {
		//caller of this method wants to block the contact
		AIAccount	*contactAccount = [self account];
		
		if ([contactAccount conformsToProtocol:@protocol(AIAccount_Privacy)]) {
			BOOL	result = NO;
			NSArray	*privacyList = [(AIAccount <AIAccount_Privacy> *)contactAccount listObjectsOnPrivacyList:privType];
			
			if (yesOrNo == YES) {
				//we want to block the contact
				if (![privacyList containsObject:self]) {
					result = [(AIAccount <AIAccount_Privacy> *)contactAccount addListObject:self toPrivacyList:privType];
				}
			} else {
				//unblock contact
				if ([privacyList containsObject:self]) {
					result = [(AIAccount <AIAccount_Privacy> *)contactAccount removeListObject:self fromPrivacyList:privType];
				}
			}
			
			//update property
			if (result) {
				[self setValue:((privType == AIPrivacyTypeDeny) == yesOrNo) ? [NSNumber numberWithBool:YES] : nil
							   forProperty:KEY_IS_BLOCKED 
							   notify:NotifyNow];
			}
		} else {
			NSLog(@"Privacy is not supported on contacts for the account: %@", contactAccount);
		}
	} else {
		//caller of this method just wants to update the property
		[self setValue:((privType == AIPrivacyTypeDeny) == yesOrNo) ? [NSNumber numberWithBool:YES] : [NSNumber numberWithBool:NO]
					   forProperty:KEY_IS_BLOCKED
					   notify:NotifyNow];
	}
}

#pragma mark Status

/*!
* @brief Determine the status message to be displayed in the contact list
 *
 * Look for a property "ContactListStatusMessage".  Then look for a statusMessage.
 * Failing both those, look for a statusName, which might be something like "DND" or "Free for Chat"
 * and look up the localized description of it.
 */
- (NSAttributedString *)contactListStatusMessage
{
	NSAttributedString	*contactListStatusMessage;
	
	if (!(contactListStatusMessage = [self statusMessage])) {
		contactListStatusMessage = [self valueForProperty:@"ContactListDisplayName"];
	}
	   
	if (!contactListStatusMessage) {
		NSString *statusName;
		
		if ((statusName = [self statusName])) {
			NSString *descriptionOfStatus;
			
			if ((descriptionOfStatus = [[adium statusController] localizedDescriptionForStatusName:statusName
																						statusType:[self statusType]])) {
				contactListStatusMessage = [[[NSAttributedString alloc] initWithString:descriptionOfStatus] autorelease];			
			}
		}
	}
	   
	return contactListStatusMessage;	
}

/*!
 * @brief Are sounds for this contact muted?
 */
- (BOOL)soundsAreMuted
{
	return [[[self account] statusState] mutesSound];
}

#pragma mark Parents
/*!
 * @brief This object's parent AIListGroup
 *
 * @result An AIListGroup which contains this object or the object containing this object, or nil if it is not in an AIListGroup.
 */
- (AIListGroup *)parentGroup
{
	AIListObject<AIContainingObject>	*parentGroup = [[self parentContact] containingObject];

	if (parentGroup && [parentGroup isKindOfClass:[AIListGroup class]]) {
		return (AIListGroup *)parentGroup;
	} else {
		return nil;
	}
}

/*!
 * @brief This object's parent AIListContact
 *
 * The parent AIListContact is the appropriate place to apply preferences specific to this contact so that such
 * preferences are also applied to other AIListContacts in the same meta contact, if necessary.
 *
 * @result Either this contact or some more-encompassing contact which ultimately contains it.
 */
 - (AIListContact *)parentContact
 {
	AIListContact	*parentContact = self;

	while ([[parentContact containingObject] isKindOfClass:[AIListContact class]]) {
		parentContact = (AIListContact *)[parentContact containingObject];
	}

	return parentContact;
 }

- (BOOL)containsObject:(AIListObject*)object
{
    return NO;
}

- (BOOL)containsMultipleContacts
{
    return NO;
}

/*!
 * @brief Can this object be part of a metacontact?
 */
- (BOOL)canJoinMetaContacts
{
	return YES;
}

#pragma mark Equality
/*
- (BOOL)isEqual:(id)anObject
{
	return ([anObject isMemberOfClass:[self class]] &&
			[[(AIListContact *)anObject internalUniqueObjectID] isEqualToString:[self internalUniqueObjectID]]);
}
*/
//AppleScript ----------------------------------------------------------------------------------------------------------
#pragma mark AppleScript

- (id)sendScriptCommand:(NSScriptCommand *)command {
	NSDictionary	*evaluatedArguments = [command evaluatedArguments];
	NSString		*message = [evaluatedArguments objectForKey:@"message"];
	AIAccount		*targetAccount = [evaluatedArguments objectForKey:@"account"];
	NSString		*filePath = [evaluatedArguments objectForKey:@"filePath"];
	
	AIListContact   *targetMessagingContact = nil;
	AIListContact   *targetFileTransferContact = nil;

	if (targetAccount) {
		targetMessagingContact = [[adium contactController] contactOnAccount:targetAccount
															 fromListContact:self];
		targetFileTransferContact = targetMessagingContact;
	}
	
	//Send any message we were told to send
	if (message && [message length]) {
		AIChat			*chat;
		BOOL			autoreply = [[evaluatedArguments objectForKey:@"autoreply"] boolValue];
		
		//Make sure we know where we are sending the message - if we don't have a target yet, find the best contact for
		//sending CONTENT_MESSAGE_TYPE.
		if (!targetMessagingContact) {
			//Get the target contact.  This could be the same contact, an identical contact on another account, 
			//or a subcontact (if we're talking about a metaContact, for example)
			targetMessagingContact = [[adium contactController] preferredContactForContentType:CONTENT_MESSAGE_TYPE
																				forListContact:self];
			targetAccount = [targetMessagingContact account];	
		}
		
		if (targetMessagingContact) {
			chat = [[adium chatController] openChatWithContact:targetMessagingContact
											onPreferredAccount:NO];
			
			//Take the string and turn it into an attributed string (in case we were passed HTML)
			NSAttributedString  *attributedMessage = [AIHTMLDecoder decodeHTML:message];
			AIContentMessage	*messageContent;
			messageContent = [AIContentMessage messageInChat:chat
												  withSource:targetAccount
												 destination:targetMessagingContact
														date:nil
													 message:attributedMessage
												   autoreply:autoreply];
			
			[[adium contentController] sendContentObject:messageContent];
		} else {
			AILogWithSignature(@"No contact available to receive a message to %@", self);
		}
	}
	
	//Send any file we were told to send
	if (filePath && [filePath length]) {
		//Make sure we know where we are sending the file - if we don't have a target yet, find the best contact for
		//sending CONTENT_FILE_TRANSFER_TYPE.
		if (!targetFileTransferContact) {
			//Get the target contact.  This could be the same contact, an identical contact on another account, 
			//or a subcontact (if we're talking about a metaContact, for example)
			targetFileTransferContact = [[adium contactController] preferredContactForContentType:CONTENT_FILE_TRANSFER_TYPE
																				   forListContact:self];
		}
		
		if (targetFileTransferContact) {
			[[adium fileTransferController] sendFile:filePath toListContact:targetFileTransferContact];
		} else {
			AILogWithSignature(@"No contact available to receive files to %@", self);
			NSBeep();
		}
	}
		
	return nil;
}

//Writing Direction ----------------------------------------------------------------------------------------------------------
#pragma mark Writing Direction

- (NSWritingDirection)defaultBaseWritingDirection
{
	static NSWritingDirection defaultBaseWritingDirection;
	static BOOL determinedDefaultBaseWritingDirection = NO;
	
	if (!determinedDefaultBaseWritingDirection) {
		/* Use  the default writing direction of the language of the user's locale (and not the language
		 * of the active localization). By that, we assume most users are mostly talking to their local friends.
		 */
		NSString	*lang = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];		
		defaultBaseWritingDirection = [NSParagraphStyle defaultWritingDirectionForLanguage:lang];
		determinedDefaultBaseWritingDirection = YES;
	}
	
	return defaultBaseWritingDirection;
}

- (NSWritingDirection)baseWritingDirection {
	NSNumber	*dir = [self preferenceForKey:KEY_BASE_WRITING_DIRECTION group:PREF_GROUP_WRITING_DIRECTION];

	return (dir ? [dir intValue] : [self defaultBaseWritingDirection]);
}

- (void)setBaseWritingDirection:(NSWritingDirection)direction {
	[self setPreference:[NSNumber numberWithInt:direction]
				 forKey:KEY_BASE_WRITING_DIRECTION
				  group:PREF_GROUP_WRITING_DIRECTION];
}

#pragma mark Address Book
- (ABPerson *)addressBookPerson
{
#warning fix me by moving ESAddressBookIntegrationPlugin to being a core helper of AIContactController
	return [NSClassFromString(@"ESAddressBookIntegrationPlugin") personForListObject:[self parentContact]];	
}
- (void)setAddressBookPerson:(ABPerson *)inPerson
{
	[[self parentContact] setPreference:[inPerson uniqueId]
								 forKey:KEY_AB_UNIQUE_ID
								  group:PREF_GROUP_ADDRESSBOOK];
}

#pragma mark Applescript

- (NSScriptObjectSpecifier *)objectSpecifier
{
	//get my account
	AIAccount *theAccount = [self account];
	
	NSScriptObjectSpecifier *containerRef = [theAccount objectSpecifier];
	return [[[NSNameSpecifier allocWithZone:[self zone]]
		initWithContainerClassDescription:[containerRef keyClassDescription]
		containerSpecifier:containerRef key:@"contacts" name:[self UID]] autorelease];
}

- (BOOL)scriptingBlocked
{
	return [self isBlocked];
}
- (void)setScriptingBlocked:(BOOL)b
{
	[self setIsBlocked:b updateList:YES];
}

@end

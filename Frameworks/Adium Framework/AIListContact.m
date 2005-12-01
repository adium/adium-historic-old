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

#import "AIAccount.h"
#import "AIContactController.h"
#import "AIChatController.h"
#import "AIContentController.h"
#import "AIStatusController.h"
#import "AIContentMessage.h"
#import "AIListContact.h"
#import "AIMetaContact.h"
#import "AIService.h"
#import "ESFileTransfer.h"
#import "AIHTMLDecoder.h"

#import <AIUtilities/AIMutableOwnerArray.h>
#import <AIUtilities/AIMutableStringAdditions.h>

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

/*
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
		//Autorelease so we don't have to worry about whether (remoteGroupName == inName) or not
		[remoteGroupName autorelease];
		remoteGroupName = [inName retain];
		
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

- (void)setServersideAlias:(NSString *)alias 
		   asStatusMessage:(BOOL)useAsStatusMessage
				  silently:(BOOL)silent
{
	BOOL changes = NO;
	BOOL displayNameChanges = NO;
	
	//This is the server display name.  Set it as such.
	if (![alias isEqualToString:[self statusObjectForKey:@"Server Display Name"]]) {
		//Set the server display name status object as the full display name
		[self setStatusObject:alias
					   forKey:@"Server Display Name"
					   notify:NotifyLater];
		
		changes = YES;
	}

	NSMutableString *cleanedAlias;
	
	//Remove any newlines, since we won't want them anywhere below
	cleanedAlias = [alias mutableCopy];
	[cleanedAlias convertNewlinesToSlashes];

	//Use it either as the status message or the display name.
	if (useAsStatusMessage) {
		if (![[self stringFromAttributedStringStatusObjectForKey:@"ContactListStatusMessage"] isEqualToString:cleanedAlias]) {
			[self setStatusObject:[[[NSAttributedString alloc] initWithString:cleanedAlias] autorelease]
						   forKey:@"ContactListStatusMessage" 
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
		[self notifyOfChangedStatusSilently:silent];
	}
	
	if (displayNameChanges) {
		//Notify of display name changes
		[[adium contactController] listObjectAttributesChanged:self
												  modifiedKeys:[NSSet setWithObject:@"Display Name"]];
		
		//XXX - There must be a cleaner way to do this alias stuff!  This works for now
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

#pragma mark Status objects

/*!
 * @brief Set online
 */
- (void)setOnline:(BOOL)online notify:(NotifyTiming)notify silently:(BOOL)silent
{
	if (online != [self online]) {
		[self setStatusObject:(online ? [NSNumber numberWithBool:YES] : nil)
					   forKey:@"Online"
					   notify:notify];
		
		if (!silent) {
			[self setStatusObject:[NSNumber numberWithBool:YES] 
						   forKey:(online ? @"Signed On" : @"Signed Off")
						   notify:notify];
			[self setStatusObject:nil 
						   forKey:(online ? @"Signed Off" : @"Signed On")
						   notify:notify];
			[self setStatusObject:nil
						   forKey:(online ? @"Signed On" : @"Signed Off")
					   afterDelay:15];
		}
		
		if (online) {
			if (notify == NotifyNow) {
				[self notifyOfChangedStatusSilently:silent];
			}
			
		} else {
			//Will always notify
			[[self account] removeStatusObjectsFromContact:self
												  silently:silent];	
		}
	}
}

/*!
 * @brief Set the sign on date
 */
- (void)setSignonDate:(NSDate *)signonDate notify:(NotifyTiming)notify
{
	[self setStatusObject:signonDate
				   forKey:@"Signon Date"
				   notify:notify];
}
/*!
 * @brief Date this contact signed on, if available
 */
- (NSDate *)signonDate
{
	return [self statusObjectForKey:@"Signon Date"];
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
			[self setStatusObject:idleSinceDate
						   forKey:@"IdleSince"
						   notify:NotifyLater];
		} else {
			//No idleSinceDate means we are Idle but don't know how long, so set to -1
			[self setStatusObject:[NSNumber numberWithInt:-1]
						   forKey:@"Idle"
						   notify:NotifyLater];
		}
	} else {
		[self setStatusObject:nil
					   forKey:@"IdleSince"
					   notify:NotifyLater];
		[self setStatusObject:nil
					   forKey:@"Idle"
					   notify:NotifyLater];
	}
	
	/* @"Idle", for a contact with an IdleSince date, will be changing every minute.  @"IsIdle" provides observers a way
	* to perform an action when the contact becomes/comes back from idle, regardless of whether an IdleSince is available,
	* without having to do that action every minute for other contacts.
	*/
	[self setStatusObject:(isIdle ? [NSNumber numberWithBool:YES] : nil)
				   forKey:@"IsIdle"
				   notify:NotifyLater];
	
	//Apply any changes
	if (notify == NotifyNow) {
		[self notifyOfChangedStatusSilently:NO];
	}
}

- (void)setServersideIconData:(NSData *)iconData notify:(NotifyTiming)notify
{
	//Observers get a single shot at utilizing the user icon data in its raw form
	[self setStatusObject:iconData forKey:@"UserIconData" notify:NotifyLater];
	
	//Set the User Icon as an NSImage
	NSImage *userIcon = [[NSImage alloc] initWithData:iconData];
	[self setStatusObject:userIcon forKey:KEY_USER_ICON notify:NotifyLater];
	[userIcon release];
	
	//Clear the UserIconData after it has been used
	[self setStatusObject:nil
				   forKey:@"UserIconData"
			   afterDelay:1];
	
	//Apply any changes
	if (notify == NotifyNow) {
		[self notifyOfChangedStatusSilently:NO];
	}	
}

/*!
 * @brief Set the warning level
 *
 * @param warningLevel The warning level, an integer between 0 and 100
 */
- (void)setWarningLevel:(int)warningLevel notify:(NotifyTiming)notify
{
	if (warningLevel != [self warningLevel]) {
		[self setStatusObject:[NSNumber numberWithInt:warningLevel]
					   forKey:@"Warning"
					   notify:notify];
	}
}

/*
 * @brief Warning level
 *
 * @result The warning level, an integer between 0 and 100
 */
- (int)warningLevel
{
	return [self integerStatusObjectForKey:@"Warning"];
}

/*
 * @brief Set the profile
 */
- (void)setProfile:(NSAttributedString *)profile notify:(NotifyTiming)notify
{
	[self setStatusObject:profile
				   forKey:@"TextProfile" 
				   notify:notify];
}

/*
 * @brief Profile
 */
- (NSAttributedString *)profile
{
	return [self statusObjectForKey:@"TextProfile"];
}

/*!
 * @brief Is this contact a stranger?
 * 
 * A listContact is a stranger if it has a nil remoteGroupName
 */
- (BOOL)isStranger
{
	return ![self integerStatusObjectForKey:@"NotAStranger"];
}

/*!
 * @brief Is this object connected via a mobile device?
 */
- (BOOL)isMobile
{
	return [self integerStatusObjectForKey:@"IsMobile" fromAnyContainedObject:NO];
}

/*!
 * @brief Set if this contact is mobile
 */
- (void)setIsMobile:(BOOL)isMobile notify:(NotifyTiming)notify
{
	[self setStatusObject:(isMobile ? [NSNumber numberWithBool:isMobile] : nil)
				   forKey:@"IsMobile"
				   notify:notify];
}

#pragma mark Status

/*!
* @brief Determine the status message to be displayed in the contact list
 *
 * Look for a status object "ContactListStatusMessage".  Then look for a statusMessage.
 * Failing both those, look for a statusName, which might be something like "DND" or "Free for Chat"
 * and look up the localized description of it.
 */
- (NSAttributedString *)contactListStatusMessage
{
	NSAttributedString	*contactListStatusMessage;
	
	if (!(contactListStatusMessage = [self statusObjectForKey:@"ContactListStatusMessage"])) {
		contactListStatusMessage = [self statusMessage];
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

/*
 * @brief Return just the status message, not looking as deep as a localized status name
 *
 * This is used by AIMetaContact to be able to sort out what status to display
 */
- (NSAttributedString *)contactListStatusMessageIgnoringStatusName
{
	NSAttributedString	*contactListStatusMessage;
	
	if (!(contactListStatusMessage = [self statusObjectForKey:@"ContactListStatusMessage"])) {
		contactListStatusMessage = [self statusMessage];
	}
	   
	   return contactListStatusMessage;
}

#pragma mark Parents
/*
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

/*
 * @brief This object's parent AIListContact
 *
 * The parent AIListContact is the appropriate place to apply preferences specific to this contact so that such
 * preferences are also applied to other AIListContacts in the same meta contact, if necessary.
 *
 * @result Either this contact, if it is not in a metaContact, or the AIMetaContact which contains it.
 */
 - (AIListContact *)parentContact
 {
	AIListContact	*parentContact = self;

	if (containingObject && [containingObject isKindOfClass:[AIMetaContact class]]) {
		parentContact = (AIMetaContact *)containingObject;		
	}

	return parentContact;
 }
 

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
		
		chat = [[adium chatController] openChatWithContact:targetMessagingContact];
		
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
	}
	
	//Send any file we were told to send
	if (filePath && [filePath length]) {
		//Make sure we know where we are sending the file - if we don't have a target yet, find the best contact for
		//sending FILE_TRANSFER_TYPE.
		if (!targetFileTransferContact) {
			//Get the target contact.  This could be the same contact, an identical contact on another account, 
			//or a subcontact (if we're talking about a metaContact, for example)
			targetFileTransferContact = [[adium contactController] preferredContactForContentType:FILE_TRANSFER_TYPE
																				   forListContact:self];
		}
		
		[[adium fileTransferController] sendFile:filePath toListContact:targetFileTransferContact];
	}
		
	return nil;
}

@end

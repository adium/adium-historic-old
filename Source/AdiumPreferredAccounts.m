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

#import "AdiumPreferredAccounts.h"

#import <Adium/AIAccountControllerProtocol.h>
#import <Adium/AIContactControllerProtocol.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIService.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>
#import <Adium/AIListContact.h>

#define PREF_GROUP_PREFERRED_ACCOUNTS   @"Preferred Accounts"
#define KEY_PREFERRED_SOURCE_ACCOUNT	@"Preferred Account"

@implementation AdiumPreferredAccounts

/*!
 * @brief Init
 */
- (id)init
{
	if ((self = [super init])) {
		lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];		

		//Observe content (for accountForSendingContentToContact)
		[[adium notificationCenter] addObserver:self
									   selector:@selector(didSendContent:)
										   name:CONTENT_MESSAGE_SENT
										 object:nil];		
	}
	
	return self;
}

/*!
 * @brief Close
 */
- (void)dealloc
{
    [[adium notificationCenter] removeObserver:self];
	[lastAccountIDToSendContent release]; lastAccountIDToSendContent = nil;
	
	[super dealloc];
}


//XXX - Why is code calling these with a nil contact?
//XXX - This method is being misused all over the place as a means to pick the inner contact of a meta?
//XXX - Who wants an offline account for sending content, do we absolutely need to do that in the core?
//XXX - Why is the method for determining which account to use so complicated?
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact 
{
	return ([self preferredAccountForSendingContentType:inType toContact:inContact includeOffline:NO]);
}

- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline
{
	AIAccount		*account;

	//If passed a contact, we have a few better ways to determine the account than just using the first
    if (inContact) {
		//If we've messaged this object previously, and the account we used to message it is online, return that account
        NSString *accountID = [inContact preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
													group:PREF_GROUP_PREFERRED_ACCOUNTS];
		if (accountID) {
			if (![accountID isKindOfClass:[NSString class]]) {
				//Old code stored this as an NSNumber; upgrade.
				accountID = ([accountID isKindOfClass:[NSNumber class]] ?
							 [NSString stringWithFormat:@"%i",[(NSNumber *)accountID intValue]] :
							 nil);
				
				[inContact setPreference:accountID
								  forKey:KEY_PREFERRED_SOURCE_ACCOUNT
								   group:PREF_GROUP_PREFERRED_ACCOUNTS];
			}

			
			if ((account = [[adium accountController] accountWithInternalObjectID:accountID])) {
				if ([account availableForSendingContentType:inType toContact:inContact] || includeOffline) {
					return account;
				}
			}
		}
		
		/* We don't have a known previously used account for this contact. */

		//Get the last account used to message someone on this service, and check if the contact is on that account
		NSString		*lastAccountID = [lastAccountIDToSendContent objectForKey:[[inContact service] serviceID]];
		AIAccount		*lastUsedAccount = (lastAccountID ? [[adium accountController] accountWithInternalObjectID:lastAccountID] : nil);
		AIListContact	*possibleContact = [[adium contactController] existingContactWithService:[lastUsedAccount service]
																					   account:lastUsedAccount
																						   UID:[inContact UID]];
		if (possibleContact && ![possibleContact isStranger] &&
			([lastUsedAccount availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
			return lastUsedAccount;
		}

		//Use the current account if and only if the contact is not a stranger on that account.
		if ((account = [inContact account]) &&
			![inContact isStranger] &&
			([account availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
			return account;
		}
		
		//Now check compatible accounts, looking for one that knows about the contact
		NSEnumerator	*enumerator = [[[adium accountController] accountsCompatibleWithService:[inContact service]] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			AIListContact *possibleContact = [[adium contactController] existingContactWithService:[account service]
																						   account:account
																							   UID:[inContact UID]];
			if ((possibleContact && ![possibleContact isStranger]) &&
				([account availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
				//If a contact with this account already exists and isn't a stranger, we've found a good possible choice.
				return account;
			}
		}

		/* Now, just look for any account which could send to this contact.
		 * We no longer care if the contact is not a stranger, as we exchausted all those possibilities.
		 *
		 * First, check to see if the last account used on this service will work.
		 */
		if ([lastUsedAccount availableForSendingContentType:inType toContact:inContact] || includeOffline) {
			return lastUsedAccount;
		}

		//If inObject is an AIListContact return the account the object is on even if the account is offline
		if (includeOffline && (account = [inContact account])) {
			return account;
		}
	}

	AILogWithSignature(@"Could not find a good choice to talk to %@; will return first available account", inContact);

	//If the previous attempts failed, or we weren't passed a contact, use the first appropriate account
	return [self firstAccountAvailableForSendingContentType:inType
												  toContact:inContact
											 includeOffline:includeOffline];
}

//XXX - This seems awfully complex for code that is only run the first time we talk to a contact
//XXX - Why isn't this private?
- (AIAccount *)firstAccountAvailableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
    if (inContact) {
		//First available account in our list of the correct service type
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if ([inContact service] == [account service] &&
				([account availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
				return account;
			}
		}
		
		//First available account in our list of a compatible service type
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if ([[inContact serviceClass] isEqualToString:[account serviceClass]] &&
				([account availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
				return account;
			}
		}
	} else {
		//First available account in our list
		enumerator = [[[adium accountController] accounts] objectEnumerator];
		while ((account = [enumerator nextObject])) {
			if ([account enabled] && 
				([account availableForSendingContentType:inType toContact:inContact] || includeOffline)) {
				return account;
			}
		}
	}
	
	
	//Can't find anything
	return nil;
}

- (void)didSendContent:(NSNotification *)notification
{
	NSDictionary	*userInfo = [notification userInfo];
    AIChat			*chat = [userInfo objectForKey:@"AIChat"];
    AIListContact	*destObject = [chat listObject];
    
    if (chat && destObject) {
        AIContentObject *contentObject = [userInfo objectForKey:@"AIContentObject"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
        
		if (![[destObject preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
									 group:PREF_GROUP_PREFERRED_ACCOUNTS
					ignoreInheritedValues:YES] isEqualToString:[sourceAccount internalObjectID]]) {
			[destObject setPreference:[sourceAccount internalObjectID]
							   forKey:KEY_PREFERRED_SOURCE_ACCOUNT
								group:PREF_GROUP_PREFERRED_ACCOUNTS];
        }

        [lastAccountIDToSendContent setObject:[sourceAccount internalObjectID] forKey:[[destObject service] serviceID]];
    }
}

@end

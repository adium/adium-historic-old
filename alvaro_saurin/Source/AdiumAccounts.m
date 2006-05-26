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

#import "AdiumAccounts.h"
#import "AIAccountController.h"
#import "AIPreferenceController.h"
#import <Adium/AIAccount.h>
#import <Adium/AIService.h>
#import <AIUtilities/AIArrayAdditions.h>
#import <AIUtilities/AIAttributedStringAdditions.h>

//Preference keys
#define TOP_ACCOUNT_ID					@"TopAccountID"   	//Highest account object ID
#define ACCOUNT_LIST					@"Accounts"   		//Array of accounts
#define ACCOUNT_TYPE					@"Type"				//Account type
#define ACCOUNT_SERVICE					@"Service"			//Account service
#define ACCOUNT_UID						@"UID"				//Account UID
#define ACCOUNT_OBJECT_ID				@"ObjectID"   		//Account object ID

@interface AdiumAccounts (PRIVATE)
- (void)_loadAccounts;
- (void)_saveAccounts;
- (NSString *)_generateUniqueInternalObjectID;
- (NSString *)_upgradeServiceID:(NSString *)serviceID forAccountDict:(NSDictionary *)accountDict;
- (void)upgradeAccounts;
@end

@implementation AdiumAccounts

/*!
 * @brief Init
 */
- (id)init {
	if ((self = [super init])) {
		accounts = [[NSMutableArray alloc] init];
		unloadableAccounts = [[NSMutableArray alloc] init];	
	}
	
	return self;
}

/*!
 * @brief Dealloc
 */
- (void)dealloc {
    [accounts release];
	[unloadableAccounts release];

	[super dealloc];
}

/*!
 * @brief Finish Initing
 *
 * Requires:
 * 1) All services have registered
 */
- (void)controllerDidLoad
{
	[self _loadAccounts];
	
	[self upgradeAccounts];
}


//Accounts -------------------------------------------------------------------------------------------------------
#pragma mark Accounts
/*
 * @brief Returns an array of all available accounts
 *
 * @return NSArray of AIAccount instances
 */
- (NSArray *)accounts
{
    return accounts;
}

/*
 * @brief Returns an array of accounts compatible with a service
 *
 * @param service AIService for compatible accounts
 * @param NSArray of AIAccount instances
 */
- (NSArray *)accountsCompatibleWithService:(AIService *)service
{
	NSMutableArray	*matchingAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [accounts objectEnumerator];
	AIAccount		*account;
	
	while ((account = [enumerator nextObject])) {
		if ([account enabled] &&
			[[[account service] serviceClass] isEqualToString:[service serviceClass]]) {
			[matchingAccounts addObject:account];
		}
	}
	
	return matchingAccounts;	
}

- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID
{
    NSEnumerator	*enumerator = [accounts objectEnumerator];
    AIAccount		*account = nil;

	//XXX temporary -- is any code using passing us NSNumbers?
	NSParameterAssert(!objectID || [objectID isKindOfClass:[NSString class]]);

    while (objectID && (account = [enumerator nextObject])) {
        if ([objectID isEqualToString:[account internalObjectID]]) break;
    }
    
    return account;
}


//Editing --------------------------------------------------------------------------------------------------------------
#pragma mark Editing
/*!
 * @brief Create an account
 *
 * The account is not added to Adium's list of accounts, this must be done separately with addAccount:
 * @param service AIService for the account
 * @param inUID NSString userID for the account
 * @return AIAccount instance that was created
 */
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID
{	
	return [service accountWithUID:inUID internalObjectID:[self _generateUniqueInternalObjectID]];
}

/*
 * @brief Add an account
 *
 * @param inAccount AIAccount to add
 */
- (void)addAccount:(AIAccount *)inAccount
{
	[accounts addObject:inAccount];
	[self _saveAccounts];
}

/*
 * @brief Delete an account
 *
 * @param inAccount AIAccount to delete
 */
- (void)deleteAccount:(AIAccount *)inAccount
{
	//Shut down the account in preparation for release
	//XXX - Is this sufficient?  Don't some accounts take a while to disconnect and all? -ai
	[inAccount willBeDeleted];
	[[adium accountController] forgetPasswordForAccount:inAccount];

	//Remove from our array
	[accounts removeObject:inAccount];
	[self _saveAccounts];
}

/*
 * @brief Move an account
 *
 * @param inAccount AIAccount to move
 * @param destIndex Index to place the account
 * @return new index of the account
 */
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex
{
    [accounts moveObject:account toIndex:destIndex];
    [self _saveAccounts];
	return [accounts indexOfObject:account];
}

/*
 * @brief An account's UID changed
 *
 * Save our account array, which stores the account's UID permanently
 */
- (void)accountDidChangeUID:(AIAccount *)account
{
	[self _saveAccounts];
}

/*
 * @brief Generate a unique account InternalObjectID
 *
 * @return NSString unique InternalObjectID
 */
//XXX - This setup leaves the possibility that mangled preferences files would create multiple accounts with the same ID -ai
- (NSString *)_generateUniqueInternalObjectID
{
	int			topAccountID = [[[adium preferenceController] preferenceForKey:TOP_ACCOUNT_ID group:PREF_GROUP_ACCOUNTS] intValue];
	NSString 	*internalObjectID = [NSString stringWithFormat:@"%i",topAccountID];
	
	[[adium preferenceController] setPreference:[NSNumber numberWithInt:topAccountID + 1]
										 forKey:TOP_ACCOUNT_ID
										  group:PREF_GROUP_ACCOUNTS];

	return internalObjectID;
}


//Storage --------------------------------------------------------------------------------------------------------------
#pragma mark Storage
/*
 * @brief Load accounts from disk
 */
- (void)_loadAccounts
{
    NSArray		 *accountList = [[adium preferenceController] preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	NSEnumerator *enumerator;
	NSDictionary *accountDict;

    //Create an instance of every saved account
	enumerator = [accountList objectEnumerator];
	while ((accountDict = [enumerator nextObject])) {
		NSString		*serviceID = [self _upgradeServiceID:[accountDict objectForKey:ACCOUNT_TYPE] forAccountDict:accountDict];
        AIAccount		*newAccount;

		//Fetch the account service, UID, and ID
		AIService	*service = [[adium accountController] serviceWithUniqueID:serviceID];
		NSString	*accountUID = [accountDict objectForKey:ACCOUNT_UID];
		NSString	*internalObjectID = [accountDict objectForKey:ACCOUNT_OBJECT_ID];
		
        //Create the account and add it to our array
        if (service && accountUID && [accountUID length]) {
			if ((newAccount = [service accountWithUID:accountUID internalObjectID:internalObjectID])) {
                [accounts addObject:newAccount];
            } else {
				[unloadableAccounts addObject:accountDict];
			}
        }
    }

	//Broadcast an account list changed notification
    [[adium notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

/*
 * @brief Temporary serviceID upgrade code (v0.63 -> v0.70 for libgaim, v0.70 -> v0.80 for bonjour)
 *
 * @param serviceID NSString service ID (old or new)
 * @param accountDict Dictionary of the saved account
 * @return NSString service ID (new), or nil if unable to upgrade
 */
- (NSString *)_upgradeServiceID:(NSString *)serviceID forAccountDict:(NSDictionary *)accountDict
{
	//Libgaim
	if ([serviceID isEqualToString:@"AIM-LIBGAIM"]) {
		NSString 	*uid = [accountDict objectForKey:ACCOUNT_UID];
		if (uid && [uid length]) {
			const char	firstCharacter = [uid characterAtIndex:0];
			
			if ([uid hasSuffix:@"@mac.com"]) {
				serviceID = @"libgaim-oscar-Mac";
			} else if (firstCharacter >= '0' && firstCharacter <= '9') {
				serviceID = @"libgaim-oscar-ICQ";
			} else {
				serviceID = @"libgaim-oscar-AIM";
			}
		}
	} else if ([serviceID isEqualToString:@"GaduGadu-LIBGAIM"]) {
		serviceID = @"libgaim-Gadu-Gadu";
	} else if ([serviceID isEqualToString:@"Jabber-LIBGAIM"]) {
		serviceID = @"libgaim-Jabber";
	} else if ([serviceID isEqualToString:@"MSN-LIBGAIM"]) {
		serviceID = @"libgaim-MSN";
	} else if ([serviceID isEqualToString:@"Napster-LIBGAIM"]) {
		serviceID = @"libgaim-Napster";
	} else if ([serviceID isEqualToString:@"Novell-LIBGAIM"]) {
		serviceID = @"libgaim-GroupWise";
	} else if ([serviceID isEqualToString:@"Sametime-LIBGAIM"]) {
		serviceID = @"libgaim-Sametime";
	} else if ([serviceID isEqualToString:@"Yahoo-LIBGAIM"]) {
		serviceID = @"libgaim-Yahoo!";
	} else if ([serviceID isEqualToString:@"Yahoo-Japan-LIBGAIM"]) {
		serviceID = @"libgaim-Yahoo!-Japan";
	}
	
	//Bonjour
	if ([serviceID isEqualToString:@"rvous-libezv"]) {
		serviceID = @"bonjour-libezv";
	}

#ifndef JOSCAR_SUPERCEDE_LIBGAIM
#warning turn this off if we switch to joscar
	//"upgrade" joscar accounts to libgaim ones. Inserted so
	//testing joscar doesn't break people's libgaim accounts.
	if ([serviceID isEqualToString:@"joscar-OSCAR-AIM"])
		serviceID = @"libgaim-oscar-AIM";
	else if ([serviceID isEqualToString:@"joscar-OSCAR-ICQ"])
		serviceID = @"libgaim-oscar-ICQ";
	else if ([serviceID isEqualToString:@"joscar-OSCAR-dotMac"])
		serviceID = @"libgaim-oscar-Mac";
#endif
	
#ifdef JOSCAR_SUPERCEDE_LIBGAIM
	if ([serviceID isEqualToString:@"libgaim-oscar-AIM"])
		serviceID = @"joscar-OSCAR-AIM";
	else if ([serviceID isEqualToString:@"libgaim-oscar-ICQ"])
		serviceID = @"joscar-OSCAR-ICQ";
	else if ([serviceID isEqualToString:@"libgaim-oscar-Mac"])
		serviceID = @"joscar-OSCAR-dotMac";
#endif
	
	return serviceID;
}

/*
 * @brief Save accounts to disk
 */
- (void)_saveAccounts
{
	NSMutableArray	*flatAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//Build a flattened array of the accounts
	enumerator = [accounts objectEnumerator];
	while ((account = [enumerator nextObject])) {
		if (![account isTemporary]) {
			NSMutableDictionary		*flatAccount = [NSMutableDictionary dictionary];
			
			[flatAccount setObject:[[account service] serviceCodeUniqueID] forKey:ACCOUNT_TYPE]; 	//Unique plugin ID
			[flatAccount setObject:[[account service] serviceID] forKey:ACCOUNT_SERVICE];	    	//Shared service ID
			[flatAccount setObject:[account UID] forKey:ACCOUNT_UID];		    					//Account UID
			[flatAccount setObject:[account internalObjectID] forKey:ACCOUNT_OBJECT_ID];  			//Account Object ID
			
			[flatAccounts addObject:flatAccount];
		}
	}
	
	//Add any unloadable accounts so they're not lost
	[flatAccounts addObjectsFromArray:unloadableAccounts];

	//Save and broadcast an account list changed notification
	[[adium preferenceController] setPreference:flatAccounts forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	[[adium notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

/*
 * @brief Perform upgrades for a new version
 *
 * 1.0: KEY_ACCOUNT_DISPLAY_NAME and @"TextProfile" cleared if @"" and moved to global if identical on all accounts
 */
- (void)upgradeAccounts
{
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber		*upgradedAccounts = [userDefaults objectForKey:@"Adium:Account Prefs Upgraded for 1.0"];
	
	if (!upgradedAccounts || ![upgradedAccounts boolValue]) {
		[userDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"Adium:Account Prefs Upgraded for 1.0"];
		[userDefaults synchronize];

		AIAccount		*account;
		NSEnumerator	*enumerator, *keyEnumerator;
		NSString		*key;

		//Adium 0.8x would store @"" in preferences which we now want to be able to inherit global values if they don't have a value.
		NSSet	*keysWeNowUseGlobally = [NSSet setWithObjects:KEY_ACCOUNT_DISPLAY_NAME, @"TextProfile", nil];

		keyEnumerator = [keysWeNowUseGlobally objectEnumerator];		
		while ((key = [keyEnumerator nextObject])) {
			NSAttributedString	*firstAttributedString = nil;
			BOOL				allOnThisKeyAreTheSame = YES;

			enumerator = [[self accounts] objectEnumerator];
			while ((account = [enumerator nextObject])) {
				NSAttributedString *attributedString = [[account preferenceForKey:key
																			group:GROUP_ACCOUNT_STATUS
															ignoreInheritedValues:YES] attributedString];
				if (attributedString && ![attributedString length]) {
					[account setPreference:nil
									forKey:key
									 group:GROUP_ACCOUNT_STATUS];
					attributedString = nil;
				}
				
				if (attributedString) {
					if (firstAttributedString) {
						/* If this string is not the same as the first one we found, all are not the same.
						 * Only need to check if thus far they all have been the same
						 */
						if (allOnThisKeyAreTheSame &&
							![[[attributedString string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:
								[[firstAttributedString string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] ) {
							allOnThisKeyAreTheSame = NO;
						}
					} else {
						//Note the first one we find, which will be our reference
						firstAttributedString = attributedString;
					}
				}
			}
			
			if (allOnThisKeyAreTheSame && firstAttributedString) {
				//All strings on this key are the same. Set the preference globally...
				[[adium preferenceController] setPreference:[firstAttributedString dataRepresentation]
													 forKey:key
													  group:GROUP_ACCOUNT_STATUS];
				
				//And remove it from all accounts
				enumerator = [[self accounts] objectEnumerator];
				while ((account = [enumerator nextObject])) {
					[account setPreference:nil
									forKey:key
									 group:GROUP_ACCOUNT_STATUS];
				}
			}
		}
	}
}

@end

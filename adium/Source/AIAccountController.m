/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2003, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
\---------------------------------------------------------------------------------------------------------/
 | This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 | General Public License as published by the Free Software Foundation; either version 2 of the License,
 | or (at your option) any later version.
 |
 | This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 | the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 | Public License for more details.
 |
 | You should have received a copy of the GNU General Public License along with this program; if not,
 | write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 \------------------------------------------------------------------------------------------------------ */

// $Id: AIAccountController.m,v 1.61 2004/03/06 04:43:04 adamiser Exp $

#import "AIAccountController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIPasswordPromptController.h"

//Paths and Filenames
#define PREF_GROUP_PREFERRED_ACCOUNTS   @"Preferred Accounts"
#define ACCOUNT_DEFAULT_PREFS			@"AccountPrefs"

//Preference keys
#define TOP_ACCOUNT_ID					@"TopAccountID"   	//Highest account object ID
#define ACCOUNT_LIST					@"Accounts"   		//Array of accounts
#define ACCOUNT_TYPE					@"Type"				//Account type
#define ACCOUNT_SERVICE					@"Service"			//Account service
#define ACCOUNT_UID						@"UID"				//Account UID
#define ACCOUNT_OBJECT_ID				@"ObjectID"   		//Account object ID

//Other
#define KEY_PREFERRED_SOURCE_ACCOUNT	@"Preferred Account"

@interface AIAccountController (PRIVATE)
- (void)loadAccounts;
- (void)saveAccounts;
- (void)_addMenuItemsToMenu:(NSMenu *)menu withTarget:(id)target forAccounts:(NSArray *)accounts;
- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred;
@end

@implementation AIAccountController

//init
- (void)initController
{
    availableServiceDict = [[NSMutableDictionary alloc] init];
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
    sleepingOnlineAccounts = nil;
    
	//Default account preferences
	[[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
	
    //Monitor system sleep so we can cleanly disconnect / reconnect our accounts
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemWillSleep:)
                                                 name:AISystemWillSleep_Notification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(systemDidWake:)
                                                 name:AISystemDidWake_Notification
                                               object:nil];
}

//init (Called after the other controllers have set themselves up)
- (void)finishIniting
{    
    //Load the user accounts
    [self loadAccounts];
    [self saveAccounts];
    
    //Observe content (for accountForSendingContentToHandle)
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:Content_DidSendContent
                                     object:nil];
    
    //Autoconnect
    [self autoConnectAccounts];
}

//close
- (void)closeController
{
    //Disconnect all accounts
    [self disconnectAllAccounts];
    
    //Remove observers (otherwise, every account added will be a duplicate next time around)
    [[owner notificationCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    //Cleanup
    [accountArray release];
    [availableServiceDict release];
    [lastAccountIDToSendContent release];
}


//Account Storage ------------------------------------------------------------------------------------------------------
#pragma mark Account Storage
//Loads the saved accounts
- (void)loadAccounts
{
	NSEnumerator	*enumerator;
	NSDictionary	*accountDict;
    
	//Close down any existing accounts
	[accountArray release]; accountArray = [[NSMutableArray alloc] init];
		
    //Create an instance of every saved account
	enumerator = [[[owner preferenceController] preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS] objectEnumerator];
	while(accountDict = [enumerator nextObject]){
        AIAccount		*newAccount;
        NSString		*serviceType;
		NSString		*accountUID;
		int				objectID;
		
		//Fetch the account service, UID, and ID
		serviceType = [accountDict objectForKey:ACCOUNT_TYPE];
		accountUID = [accountDict objectForKey:ACCOUNT_UID];
		objectID = [[accountDict objectForKey:ACCOUNT_OBJECT_ID] intValue];
		
        //Create the account and add it to our array
        if(serviceType && [serviceType length] && accountUID && [accountUID length]){
            if(newAccount = [self createAccountOfType:serviceType withUID:accountUID objectID:objectID]){
                [accountArray addObject:newAccount];
            }
        }
    }
	
	//Broadcast an account list changed notification
    [[owner notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

//Save the accounts
- (void)saveAccounts
{
	NSMutableArray	*flatAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//Build a flattened array of the accounts
	enumerator = [accountArray objectEnumerator];
	while(account = [enumerator nextObject]){
		NSMutableDictionary		*flatAccount = [NSMutableDictionary dictionary];
		
		[flatAccount setObject:[[account service] identifier] forKey:ACCOUNT_TYPE]; //Unique plugin ID
		[flatAccount setObject:[account serviceID] forKey:ACCOUNT_SERVICE];	    	//Shared service ID
		[flatAccount setObject:[account UID] forKey:ACCOUNT_UID];		    		//Account UID
		[flatAccount setObject:[account uniqueObjectID] forKey:ACCOUNT_OBJECT_ID];  //Account Object ID
		
		[flatAccounts addObject:flatAccount];
	}
	
	//Save
	[[owner preferenceController] setPreference:flatAccounts forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];

	//Broadcast an account list changed notification
    [[owner notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

//Returns a new account of the specified type (Unique service plugin ID)
- (AIAccount *)createAccountOfType:(NSString *)inType withUID:(NSString *)inUID objectID:(int)inObjectID
{
	id <AIServiceController>    serviceController;
	
	//If no object ID is provided, use the next largest
	if(!inObjectID){
		inObjectID = [[[owner preferenceController] preferenceForKey:TOP_ACCOUNT_ID group:PREF_GROUP_ACCOUNTS] intValue];
		[[owner preferenceController] setPreference:[NSNumber numberWithInt:inObjectID + 1]
											 forKey:TOP_ACCOUNT_ID
											  group:PREF_GROUP_ACCOUNTS];
	}
	
	//Create the account
    if(serviceController = [self serviceControllerWithIdentifier:inType]){
        return([serviceController accountWithUID:inUID objectID:inObjectID]);
    }else{
        return(nil);
    }
}


//Services -------------------------------------------------------------------------------------------------------
#pragma mark Services
//Sort an array of services alphabetically by their description
int _alphabeticalServiceSort(id service1, id service2, void *context)
{
	return([(NSString *)[service1 description] caseInsensitiveCompare:(NSString *)[service2 description]]);
}

//Return the available services.  These are used for account creation.
- (NSArray *)availableServices
{
	return([[availableServiceDict allValues] sortedArrayUsingFunction:_alphabeticalServiceSort context:nil]);
}

//Return the active service types (service types for which there is an account).  These are used for contact creation.
- (NSArray *)activeServiceTypes
{
	NSMutableArray	*serviceArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	
	//Build an array of all currently used services
	while(account = [enumerator nextObject]){
		NSEnumerator		*duplicateEnum = [serviceArray objectEnumerator];
		AIServiceType		*existingService;
		
		//Prevent any service from going in twice
		while(existingService = [duplicateEnum nextObject]){
			if([[existingService identifier] compare:[[[account service] handleServiceType] identifier]] == 0) break;
		}
		if(existingService == nil){
			[serviceArray addObject:[[account service] handleServiceType]];
		}
	}
	
	//Sort
	return([serviceArray sortedArrayUsingFunction:_alphabeticalServiceSort context:nil]);
}

//Returns the specified service controller
- (id <AIServiceController>)serviceControllerWithIdentifier:(NSString *)inType
{
    return([availableServiceDict objectForKey:inType]);
}

//Register service code
- (void)registerService:(id <AIServiceController>)inService
{
    [availableServiceDict setObject:inService forKey:[inService identifier]];
}


//Accounts -------------------------------------------------------------------------------------------------------
#pragma mark Accounts
//Returns all available accounts
- (NSArray *)accountArray
{
    return(accountArray);
}

//Searches the account list for the specified account
- (AIAccount *)accountWithObjectID:(NSString *)inID
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([inID compare:[account uniqueObjectID]] == 0){
            return(account);
        }
    }
    
    return(nil);
}

//Searches the account list for accounts with the specified service ID
- (NSArray *)accountsWithServiceID:(NSString *)serviceID
{
	NSMutableArray	*array = [NSMutableArray array];
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
		if([serviceID compare:[account serviceID]] == 0) [array addObject:account];
    }
    
    return(array);
}

//Returns a new default account
- (AIAccount *)defaultAccount
{
	if([NSApp isOnPantherOrBetter]){
		return([self createAccountOfType:@"AIM-LIBGAIM" withUID:@"" objectID:0]);
	}else{
		return([self createAccountOfType:@"AIM (TOC2)" withUID:@"" objectID:0]);
	}
}


//Account Editing ------------------------------------------------------------------------------------------------------
#pragma mark Account Editing
//Create a new default account
- (AIAccount *)newAccountAtIndex:(int)index
{
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
    
    AIAccount	*newAccount = [self defaultAccount];
    
    [self insertAccount:newAccount atIndex:index];
    
    return(newAccount);
}

//Insert an account
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index
{    
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
    
    //Insert the account
    [accountArray insertObject:inAccount atIndex:index];
    [self saveAccounts];
}

//Delete an account
- (void)deleteAccount:(AIAccount *)inAccount
{
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert([accountArray indexOfObject:inAccount] != NSNotFound);

	[inAccount retain]; //Don't let the account dealloc until we have a chance to notify everyone that it's gone
	[accountArray removeObject:inAccount];
	[self saveAccounts];
	[inAccount release];
}

//Switches the service of the specified account
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService
{
    //Add an account with the new service
	AIAccount	*newAccount = [self createAccountOfType:[inService identifier]
												withUID:[inAccount UID]
											   objectID:[[inAccount uniqueObjectID] intValue]];
    [self insertAccount:newAccount atIndex:[accountArray indexOfObject:inAccount]];
    
    //Delete the old account
    [self deleteAccount:inAccount];
    
    return(newAccount);
}

//Change the UID of an existing account
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID
{
	//Add an account with the new UID
	AIAccount	*newAccount = [self createAccountOfType:[[inAccount service] identifier]
												withUID:inUID
											   objectID:[[inAccount uniqueObjectID] intValue]];
	[self insertAccount:newAccount atIndex:[accountArray indexOfObject:inAccount]];
	
	//Delete the old account
	[self deleteAccount:inAccount];
	
    return(newAccount);
}

//Re-order an account on the list
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex
{
    int sourceIndex = [accountArray indexOfObject:account];
    
    //Remove the account
    [account retain];
    [accountArray removeObject:account];
    
    //Re-insert the account
    if(destIndex > sourceIndex){
        destIndex -= 1;
    }
    [accountArray insertObject:account atIndex:destIndex];
    [account release];
    
    [self saveAccounts];
    
    return(destIndex);
}


//Preferred Source Accounts --------------------------------------------------------------------------------------------
#pragma mark Preferred Source Accounts
//Returns the preferred choice for sending content to the passed list object
//When presenting the user with a list of accounts, this should be the one selected by default
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject
{
	NSString    *accountID;
	AIAccount	*account;

    if(inObject){
		//If we've messaged this object previously, and the account we used to message it is online, return that account
        accountID = [inObject preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT group:PREF_GROUP_PREFERRED_ACCOUNTS];
        if(accountID && (account = [self accountWithObjectID:accountID])){
            if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
                return(account);
            }
        }
		
		//If this is not a meta contact, return the account the object is on
		if(![inObject isKindOfClass:[AIMetaContact class]]){
			if(account = [self accountWithObjectID:[(AIListContact *)inObject accountID]]){
				if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
					return(account);
				}
			}
		}
    }
	
	//Return the last account used to message someone on this service
	NSString	*lastAccountID = [lastAccountIDToSendContent objectForKey:[inObject serviceID]];
	if(lastAccountID && (account = [self accountWithObjectID:lastAccountID])){
		if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
			return(account);
		}
	}
	
	//First available account in our list of the correct service type
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	while(account = [enumerator nextObject]){
		if([[account serviceID] compare:[inObject serviceID]] == 0 &&
		   [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
			return(account);
		}
	}

	//Can't find anything
	return(nil);
}
	
//Returns a menu of all accounts.  Accounts not available for sending content are disabled.
//- Selector called on account selection is selectAccount:
//- The menu item's represented objects are the AIAccounts they represent
- (NSMenu *)menuOfAccountsWithTarget:(id)target
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSMenu			*menu;
	
	//Prepare our menu
	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	
    //Insert a menu item for each available account
    enumerator = [accountArray objectEnumerator];
    while(account = [enumerator nextObject]){
        NSMenuItem	*menuItem;
        
        //Create
        menuItem = [[[NSMenuItem alloc] initWithTitle:[account displayName]
											   target:target
											   action:@selector(selectAccount:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
		
        //Disabled if the account is offline
        if(![[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }
		
        //Add
        [menu addItem:menuItem];
    }
	
	return([menu autorelease]);
}	

//Returns a menu of all accounts available for sending content to a list object
//- Preferred choices are placed at the top of the menu.
//- Selector called on account selection is selectAccount:
//- The menu item's represented objects are the AIAccounts they represent
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType
								   toListObject:(AIListObject *)inObject
									 withTarget:(id)target
{
	NSMenu		*menu;
	NSArray		*topAccounts, *bottomAccounts;

	//Get the list of accounts for each section of our menu
	topAccounts = [self _accountsForSendingContentType:CONTENT_MESSAGE_TYPE
										  toListObject:inObject
											 preferred:YES];
	bottomAccounts = [self _accountsForSendingContentType:CONTENT_MESSAGE_TYPE
											 toListObject:inObject
												preferred:NO];
	
	//Build the menu
	menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];
	if([topAccounts count]) [self _addMenuItemsToMenu:menu withTarget:target forAccounts:topAccounts];
	if([topAccounts count] &&  [bottomAccounts count]) [menu addItem:[NSMenuItem separatorItem]];
	if([bottomAccounts count]) [self _addMenuItemsToMenu:menu withTarget:target forAccounts:bottomAccounts];
	
	return([menu autorelease]);
}

- (void)_addMenuItemsToMenu:(NSMenu *)menu withTarget:(id)target forAccounts:(NSArray *)accounts
{
	NSEnumerator	*enumerator = [accounts objectEnumerator];
	AIAccount		*anAccount;
	
	while(anAccount = [enumerator nextObject]){
		NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:[anAccount displayName]
															target:target
															action:@selector(selectAccount:)
													 keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:anAccount];
		[menu addItem:menuItem];
	}
}

- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred
{
	NSMutableArray	*sourceAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			if([[inObject serviceID] compare:[[[account service] handleServiceType] identifier]] == 0){
				BOOL			knowsObject = NO;
				BOOL			canFindObject = NO;
				AIListContact	*contactForAccount = [[owner contactController] existingContactWithService:[inObject serviceID]
																								accountUID:[account UID]
																									   UID:[inObject UID]];
				
				//Does the account know this object?
				if(contactForAccount){
					knowsObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																							 toListObject:contactForAccount];
				}
				
				//Could the account find this object?
				canFindObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toListObject:nil];
				
				if((inPreferred && knowsObject) || (!inPreferred && !knowsObject && canFindObject)){
					[sourceAccounts addObject:account];
				}
			}
		}
	}
			
	return(sourceAccounts);
}

//Watch outgoing content, remembering the user's choice of source account
- (void)didSendContent:(NSNotification *)notification
{
    AIChat			*chat = [notification object];
    AIListObject	*destObject = [chat listObject];
    
    if(chat && destObject){
        AIContentObject *contentObject = [[notification userInfo] objectForKey:@"Object"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
        
        [destObject setPreference:[sourceAccount uniqueObjectID]
                           forKey:KEY_PREFERRED_SOURCE_ACCOUNT
                            group:PREF_GROUP_PREFERRED_ACCOUNTS];
        
        [lastAccountIDToSendContent setObject:[sourceAccount uniqueObjectID] forKey:[destObject serviceID]];
    }
}


//Connection convenience methods ---------------------------------------------------------------------------------------
#pragma mark Connection Convenience Methods
//Automatically connect to accounts flagged with an auto connect property
- (void)autoConnectAccounts
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
           [[account preferenceForKey:@"AutoConnect" group:GROUP_ACCOUNT_STATUS] boolValue]){
            [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//Connects all the accounts
- (void)connectAllAccounts
{
    NSEnumerator		*enumerator;
    AIAccount			*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//Disconnects all the accounts
- (void)disconnectAllAccounts
{
    NSEnumerator		*enumerator;
    AIAccount			*account;
    
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            [account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}


//Disconnect / Reconnect on sleep --------------------------------------------------------------------------------------
#pragma mark Disconnect/Reconnect On Sleep
//System is sleeping
- (void)systemWillSleep:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //Remove any existing online account array
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = [[NSMutableArray alloc] init];
    
    //Process each account, looking for any that are online
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
           [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            //Remember that this account was online
            [sleepingOnlineAccounts addObject:account];
            
            //Disconnect it
            [account setPreference:[NSNumber numberWithBool:NO] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

//System is waking
- (void)systemDidWake:(NSNotification *)notification
{
    NSEnumerator	*enumerator;
    AIAccount		*account;
    
    //Reconnect all sleeping online accounts
    enumerator = [sleepingOnlineAccounts objectEnumerator];
    while((account = [enumerator nextObject])){
        //Connect it
        [account setPreference:[NSNumber numberWithBool:YES] forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
    }
    
    //Cleanup
    [sleepingOnlineAccounts release]; sleepingOnlineAccounts = nil;
}


//Password Storage -----------------------------------------------------------------------------------------------------
#pragma mark Password Storage
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount{
	return([NSString stringWithFormat:@"%@.%@",[inAccount serviceID],[[inAccount UID] compactedString]]);
}
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount{
	return([NSString stringWithFormat:@"Adium.%@",[self _accountNameForAccount:inAccount]]);
}

//Save an account password
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount
{
    if(inPassword){
        [AIKeychain putPasswordInKeychainForService:[self _passKeyForAccount:inAccount]
                                            account:[self _accountNameForAccount:inAccount] password:inPassword];
    }
}

//Fetches a saved account password (returns nil if no password is saved)
- (NSString *)passwordForAccount:(AIAccount *)inAccount
{
    NSString	*password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForAccount:inAccount]
                                                                  account:[self _accountNameForAccount:inAccount]];
    
    return(password);
}

//Fetches a saved account password (Prompts the user to enter if no password is saved)
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
    NSString	*password;
    
    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForAccount:inAccount]
                                                     account:[self _accountNameForAccount:inAccount]];
    
    if(password && [password length] != 0){
        //Invoke the target right away
        [inTarget performSelector:inSelector withObject:password afterDelay:0.0001];    
    }else{
        //Prompt the user for their password
        [AIPasswordPromptController showPasswordPromptForAccount:inAccount notifyingTarget:inTarget selector:inSelector];
    }
}

//Forget a saved password
- (void)forgetPasswordForAccount:(AIAccount *)inAccount
{
    [AIKeychain removePasswordFromKeychainForService:[self _passKeyForAccount:inAccount]
											 account:[self _accountNameForAccount:inAccount]];
}

@end


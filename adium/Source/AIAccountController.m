/*-------------------------------------------------------------------------------------------------------*\
| Adium, Copyright (C) 2001-2004, Adam Iser  (adamiser@mac.com | http://www.adiumx.com)                   |
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

// $Id: AIAccountController.m,v 1.94 2004/07/22 16:46:26 adamiser Exp $

#import "AIAccountController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "ESAccountPasswordPromptController.h"
#import "ESProxyPasswordPromptController.h"

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
- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline;

- (void)_addAccountMenuItemsForPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;
- (void)_removeAccountMenuItemsForPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;
- (void)_updateMenuItem:(NSMenuItem *)menuItem forAccount:(AIAccount *)account;
- (NSMenuItem *)_menuItemForAccount:(AIAccount *)account fromArray:(NSArray *)accountMenuItemArray;
- (void)rebuildAllAccountMenuItems;

@end

@implementation AIAccountController

//init
- (void)initController
{
    availableServiceDict = [[NSMutableDictionary alloc] init];
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
    sleepingOnlineAccounts = nil;
	accountMenuItemArraysDict = [[NSMutableDictionary alloc] init];
	accountMenuPluginsArray = [[NSMutableArray alloc] init];
	_cachedActiveServiceTypes = nil;

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

//Finish initialization once other controllers have set themselves up
- (void)finishIniting
{   
	//Observe account changes, both list and online/connecting/offline
    [[owner notificationCenter] addObserver:self
								   selector:@selector(accountListChanged:)
									   name:Account_ListChanged
									 object:nil];
    [[owner contactController] registerListObjectObserver:self];
	
    //Load the user accounts
    [self loadAccounts];
    
    //Observe content (for accountForSendingContentToContact)
    [[owner notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:Content_DidSendContent
                                     object:nil];
    //Autoconnect
	if(![NSEvent shiftKey]){
		[self autoConnectAccounts];
	}
	
	//First launch, open the account prefs
	if([accountArray count] == 0){
		[[owner preferenceController] openPreferencesToCategory:AIPref_Accounts];
	}
	
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
	[unloadableAccounts release];
    [availableServiceDict release];
    [lastAccountIDToSendContent release];
	
	[_cachedActiveServiceTypes release]; _cachedActiveServiceTypes = nil;
}


//Account Storage ------------------------------------------------------------------------------------------------------
#pragma mark Account Storage
//Loads the saved accounts
- (void)loadAccounts
{
    NSArray			*accountList;
	NSEnumerator	*enumerator;
	NSDictionary	*accountDict;

	//Close down any existing accounts
	[accountArray release]; accountArray = [[NSMutableArray alloc] init];
	[unloadableAccounts release]; unloadableAccounts = [[NSMutableArray alloc] init];	
	
	accountList = [[owner preferenceController] preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	
    //Create an instance of every saved account
	enumerator = [accountList objectEnumerator];
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
            }else{
				[unloadableAccounts addObject:accountDict];
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
	
	//Add any unloadable accounts so they're not lost
	[flatAccounts addObjectsFromArray:unloadableAccounts];
	
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
        return([serviceController accountWithUID:[[serviceController handleServiceType] filterUID:inUID removeIgnoredCharacters:YES]
										objectID:inObjectID]);
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

//Return the active service types (service types for which there is an account).  These are used for contact creation and determining if
//the service of accounts and contacts should be presented to the user.
- (NSArray *)activeServiceTypes
{
	if(!_cachedActiveServiceTypes){
		NSMutableArray	*serviceArray = [NSMutableArray array];
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		AIAccount		*account;
		
		//Build an array of all currently used services
		while(account = [enumerator nextObject]){
			AIServiceType		*accountServiceType = [[account service] handleServiceType];
			
			//Prevent any service from going in twice
			if (![serviceArray containsObject:accountServiceType]){
				[serviceArray addObject:accountServiceType];
			}
		}
		
		//Sort
		_cachedActiveServiceTypes = [[serviceArray sortedArrayUsingFunction:_alphabeticalServiceSort context:nil] retain];
	}
	
	return(_cachedActiveServiceTypes);
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

//Returns a menu of all services.
//- Selector called on service selection is selectAccount:
//- The menu item's represented objects are the service controllers they represent
- (NSMenu *)menuOfServicesWithTarget:(id)target
{	
    NSEnumerator				*enumerator;
    id <AIServiceController>	service;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems:NO];

    //Insert a menu item for each available service
	enumerator = [[self availableServices] objectEnumerator];
	while((service = [enumerator nextObject])){
        NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:[service description]
														target:target 
														action:@selector(selectServiceType:) 
												 keyEquivalent:@""] autorelease];
        [item setRepresentedObject:service];
		[item setImage:[[service handleServiceType] menuImage]];
        [menu addItem:item];
    }
	
	return([menu autorelease]);
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
        if([inID isEqualToString:[account uniqueObjectID]]){
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
		if([serviceID isEqualToString:[account serviceID]]) [array addObject:account];
    }
    
    return(array);
}

- (AIAccount *)firstAccountWithServiceID:(NSString *)serviceID
{
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
		if([serviceID isEqualToString:[account serviceID]]) break;
    }
    
    return(account);
}

//Returns a new default account
- (AIAccount *)defaultAccount
{
	return([self createAccountOfType:@"AIM-LIBGAIM" withUID:@"" objectID:0]);
}


//Account Editing ------------------------------------------------------------------------------------------------------
#pragma mark Account Editing
//Create a new default account
- (AIAccount *)newAccountAtIndex:(int)index
{
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
    
    AIAccount	*newAccount = [self defaultAccount];
    
	[self insertAccount:newAccount atIndex:index save:YES];
		
    return(newAccount);
}

//Insert an account
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index save:(BOOL)shouldSave
{    
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
    
    //Insert the account
	if ([accountArray count]){
		[accountArray insertObject:inAccount atIndex:index];
	}else{
		[accountArray addObject:inAccount];
	}
	
	if (shouldSave){
		[self saveAccounts];
	}
}

//Delete an account
- (void)deleteAccount:(AIAccount *)inAccount save:(BOOL)shouldSave
{
    NSParameterAssert(inAccount != nil);
    NSParameterAssert(accountArray != nil);
    NSParameterAssert([accountArray indexOfObject:inAccount] != NSNotFound);

	[inAccount retain]; //Don't let the account dealloc until we have a chance to notify everyone that it's gone
	[accountArray removeObject:inAccount];
	if (shouldSave){
		[self saveAccounts];
	}
	[inAccount release];
}

//Switches the service of the specified account
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService
{
    //Add an account with the new service
	AIAccount	*newAccount = [self createAccountOfType:[inService identifier]
												withUID:[inAccount UID]
											   objectID:[[inAccount uniqueObjectID] intValue]];
    [self insertAccount:newAccount atIndex:[accountArray indexOfObject:inAccount] save:NO];
    
    //Delete the old account
    [self deleteAccount:inAccount save:YES];
    
    return(newAccount);
}

//Change the UID of an existing account
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID
{
	AIServiceType	*serviceType = [[inAccount service] handleServiceType];

	//Add an account with the new UID
	AIAccount	*newAccount = [self createAccountOfType:[[inAccount service] identifier]
												withUID:[serviceType filterUID:inUID removeIgnoredCharacters:YES]
											   objectID:[[inAccount uniqueObjectID] intValue]];
	[newAccount setPreference:[serviceType filterUID:inUID removeIgnoredCharacters:NO]
					   forKey:@"FormattedUID"
						group:GROUP_ACCOUNT_STATUS];
	
	int oldAccountIndex = [accountArray indexOfObject:inAccount];
	//The old accout should be in the accountArray, but sanity checking never hurt anyone
	if (oldAccountIndex != NSNotFound) {
		[self insertAccount:newAccount atIndex:oldAccountIndex save:NO];
		
		//Delete the old account
		[self deleteAccount:inAccount save:YES];
	}else{
		[self insertAccount:newAccount atIndex:0 save:YES];
	}
	
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

//The account list changed.
- (void)accountListChanged:(NSNotification *)notification
{
	//Clear our cached active service types
	[_cachedActiveServiceTypes release]; _cachedActiveServiceTypes = nil;

	// Perform a full rebuild rather than trying to figure out what is different.
	[self rebuildAllAccountMenuItems];
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
            if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:inObject]){
                return(account);
            }
        }
		
		//If inObject is an AIListContact return the account the object is on
		if([inObject isKindOfClass:[AIListContact class]]){ 
			if(account = [self accountWithObjectID:[(AIListContact *)inObject accountID]]){
				if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:inObject]){
					return(account);
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
			if([[account serviceID] isEqualToString:[inObject serviceID]] &&
			   [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
				return(account);
			}
		}
	} else {
		//First available account in our list
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		while(account = [enumerator nextObject]){
			if([(AIAccount<AIAccount_Content> *)account availableForSendingContentType:inType toListObject:nil]){
				return(account);
			}
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
	
	BOOL multipleServices = ([[self activeServiceTypes] count] > 1);
	
    //Insert a menu item for each available account
    enumerator = [accountArray objectEnumerator];
    while(account = [enumerator nextObject]){
        NSMenuItem	*menuItem;
        
        //Create
        menuItem = [[[NSMenuItem alloc] initWithTitle:(multipleServices ?
													   [NSString stringWithFormat:@"%@ (%@)",[account formattedUID],[account serviceID]] :
													   [account formattedUID])
											   target:target
											   action:@selector(selectAccount:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
		[menuItem setImage:[account menuImage]];
		
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

//Returns an array containing menu items for all accounts. 
//- Accounts not available for sending content are disabled.
//- Selector called on account selection is selectAccount:
//- The menu item's represented objects are the AIAccounts they represent
- (NSArray *)menuItemsForAccountsWithTarget:(id)target;
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	NSMutableArray  *array;
	
	//Prepare our menu
	array = [[NSMutableArray alloc] init];
	
	BOOL multipleServices = ([[self activeServiceTypes] count] > 1);
	
    //Insert a menu item for each available account
    enumerator = [accountArray objectEnumerator];
    while(account = [enumerator nextObject]){
        NSMenuItem	*menuItem;
        
        //Create
        menuItem = [[[NSMenuItem alloc] initWithTitle:(multipleServices ?
													   [NSString stringWithFormat:@"%@ (%@)",[account formattedUID],[account serviceID]] :
													   [account formattedUID])
											   target:target
											   action:@selector(selectAccount:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
		[menuItem setImage:[account menuImage]];
		
        //Disabled if the account is offline
        if(![[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE toListObject:nil onAccount:account]){
            [menuItem setEnabled:NO];
        }else{
            [menuItem setEnabled:YES];
        }
		
        //Add
        [array addObject:menuItem];
    }
	
	return((NSArray *)[array autorelease]);
}

//Returns a menu of all accounts available for sending content to a list object
//- Preferred choices are placed at the top of the menu.
//- Selector called on account selection is selectAccount:
//- The menu item's represented objects are the AIAccounts they represent
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType
								   toListObject:(AIListObject *)inObject
									 withTarget:(id)target
								 includeOffline:(BOOL)includeOffline
{
	NSMenu		*menu;
	NSArray		*topAccounts, *bottomAccounts;
		
	//Get the list of accounts for each section of our menu
	topAccounts = [self _accountsForSendingContentType:CONTENT_MESSAGE_TYPE
										  toListObject:inObject
											 preferred:YES
										includeOffline:includeOffline];
	bottomAccounts = [self _accountsForSendingContentType:CONTENT_MESSAGE_TYPE
											 toListObject:inObject
												preferred:NO
										   includeOffline:includeOffline];

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
		NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:[anAccount formattedUID]
															target:target
															action:@selector(selectAccount:)
													 keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:anAccount];
		[menuItem setImage:[anAccount menuImage]];
		[menu addItem:menuItem];
	}
}

- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline
{
	NSMutableArray	*sourceAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		if([account conformsToProtocol:@protocol(AIAccount_Content)]){
			if(!inObject && !inPreferred){
				[sourceAccounts addObject:account];

			}else if([[inObject serviceID] isEqualToString:[[[account service] handleServiceType] identifier]]){
				BOOL			knowsObject = NO;
				BOOL			canFindObject = NO;
				AIListContact	*contactForAccount = [[owner contactController] existingContactWithService:[inObject serviceID]
																								 accountID:[account uniqueObjectID]
																									   UID:[inObject UID]];
				
				//Does the account know this object?
				if(contactForAccount){
					knowsObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																							 toListObject:contactForAccount];
				}
				
				//Could the account find this object?
				canFindObject = [(AIAccount<AIAccount_Content> *)account availableForSendingContentType:CONTENT_MESSAGE_TYPE
																						   toListObject:nil];
				
				if((inPreferred && knowsObject) ||						//Online and can see the object
				   (!inPreferred && !knowsObject && canFindObject) ||	//Online and may be able to see the object
				   (!inPreferred && !knowsObject && includeOffline)){	//Offline, but may be able to see the object if online
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
    
	NSString			*ONLINE = @"Online";
	
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:ONLINE] &&
		   [[account preferenceForKey:ONLINE group:GROUP_ACCOUNT_STATUS] boolValue]){
            [account setPreference:nil forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
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
	return([NSString stringWithFormat:@"%@.%@",[inAccount serviceID],[inAccount uniqueObjectID]]);
}
- (NSString *)_passKeyForAccount:(AIAccount *)inAccount{
	return([NSString stringWithFormat:@"Adium.%@",[self _accountNameForAccount:inAccount]]);
}
- (NSString *)_accountNameForProxyServer:(NSString *)proxyServer userName:(NSString *)userName{
	return([NSString stringWithFormat:@"%@.%@",proxyServer,userName]);
}
- (NSString *)_passKeyForProxyServer:(NSString *)proxyServer{
	return([NSString stringWithFormat:@"Adium.%@",proxyServer]);	
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
        [ESAccountPasswordPromptController showPasswordPromptForAccount:inAccount notifyingTarget:inTarget selector:inSelector];
    }
}

//Forget a saved password
- (void)forgetPasswordForAccount:(AIAccount *)inAccount
{
    [AIKeychain removePasswordFromKeychainForService:[self _passKeyForAccount:inAccount]
											 account:[self _accountNameForAccount:inAccount]];
}

- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName
{
	NSString *password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForProxyServer:server]
															   account:[self _accountNameForProxyServer:server 
																							   userName:userName]];
	return password;
}

- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector
{
	NSString	*password;
    
    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForProxyServer:server]
                                                     account:[self _accountNameForProxyServer:server userName:userName]];

    if(password && [password length] != 0){
        //Invoke the target right away
        [inTarget performSelector:inSelector withObject:password afterDelay:0.0001];    
    }else{
        //Prompt the user for their password
        [ESProxyPasswordPromptController showPasswordPromptForProxyServer:server
																 userName:userName
														  notifyingTarget:inTarget
																 selector:inSelector];
    }
}
//Save a proxy server password
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName
{
    if(inPassword){
        [AIKeychain putPasswordInKeychainForService:[self _passKeyForProxyServer:server]
                                            account:[self _accountNameForProxyServer:server 
																			userName:userName] password:inPassword];
    }else{
		[AIKeychain removePasswordFromKeychainForService:[self _passKeyForProxyServer:server]
												 account:[self _accountNameForProxyServer:server userName:userName]];
	}
}

// Account Connection menus -----------------------------------------------
#pragma mark Account Connection menus

#define	ACCOUNT_CONNECT_MENU_TITLE			AILocalizedString(@"Connect:","Connect account prefix")
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedString(@"Disconnect:","Disconnect account prefix")
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedString(@"Cancel Connect:","Connecting an account prefix")
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	AILocalizedString(@"Disconnecting","Disconnecting an account prefix")
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedString(@"Auto-Connect on Launch",nil)

#define ACCOUNT_TITLE_NO_SERVICE	[NSString stringWithFormat:@" %@",([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT)]
#define ACCOUNT_TITLE_WITH_SERVICE  [NSString stringWithFormat:@" %@ (%@)",([[account formattedUID] length] ? [account formattedUID] : NEW_ACCOUNT_DISPLAY_TEXT),[account displayServiceID]]

- (void)registerAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin
{
	[accountMenuItemArraysDict setObject:[NSMutableArray array]
								  forKey:[accountMenuPlugin identifier]];
	[accountMenuPluginsArray addObject:accountMenuPlugin];
	
	[self _addAccountMenuItemsForPlugin:accountMenuPlugin];
}
- (void)unregisterAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin
{
	[self _removeAccountMenuItemsForPlugin:accountMenuPlugin];	
	[accountMenuItemArraysDict removeObjectForKey:[accountMenuPlugin identifier]];
	[accountMenuPluginsArray removeObjectIdenticalTo:accountMenuPlugin];
}

//Togle the connection of the selected account (called by the connect/disconnnect menu item)
//MUST be called by a menu item with an account as its represented object!
- (IBAction)toggleConnection:(id)sender
{
    AIAccount   *account = [sender representedObject];
    BOOL    	online = [[account statusObjectForKey:@"Online"] boolValue];
	BOOL		connecting = [[account statusObjectForKey:@"Connecting"] boolValue];
	
	// !(online || connecting) means:
	//		If neither online nor connecting, YES - initiate a connection
	//		If either currently online or currently in the process of connecting, NO - disconnect
	//
	// Setting the preference is enough to trigger the cascade which will lead to the account taking action
	[account setPreference:[NSNumber numberWithBool:!(online || connecting)] 
					forKey:@"Online"
					 group:GROUP_ACCOUNT_STATUS];
}

//Create a new menu item for each account, updating it immediately to the proper current state.
//Store these menu items in a mutableArray associated with the plugin.
//Then, inform the plugin of the existence of the menu items so it can add them to a menu.
- (void)_addAccountMenuItemsForPlugin:(id<AccountMenuPlugin>)accountMenuPlugin
{
	NSMutableArray  *menuItemArray = [accountMenuItemArraysDict objectForKey:[accountMenuPlugin identifier]];
	
	NSEnumerator	*enumerator;
    AIAccount		*account;
    NSMenuItem		*menuItem;
	
    //Create a menuitem for each account
    enumerator = [[self accountArray] objectEnumerator];
    while((account = [enumerator nextObject])){
		
		//Create the account's menu item (the title will be set by_updateMenuItem:forAccount:
        menuItem = [[[NSMenuItem alloc] initWithTitle:@""
											   target:self
											   action:@selector(toggleConnection:)
										keyEquivalent:@""] autorelease];
        [menuItem setRepresentedObject:account];
        [menuItemArray addObject:menuItem];
        
        [self _updateMenuItem:menuItem forAccount:account];
    }
	
	//Now that we are done creating the menu items, tell the plugin about them
	[accountMenuPlugin addAccountMenuItems:menuItemArray];
}

//Retrieve the menu items for a given plugin.  Tell it we want to remove them, which should trigger
//removal from whatever menu the program is using them in.  Then, remove them from our tracking array.
- (void)_removeAccountMenuItemsForPlugin:(id<AccountMenuPlugin>)accountMenuPlugin
{
	NSMutableArray  *menuItemArray = [accountMenuItemArraysDict objectForKey:[accountMenuPlugin identifier]];

	//Inform the plugin that we are removing the items in the this array 
	[accountMenuPlugin removeAccountMenuItems:menuItemArray];
	
	//Now clear the array
	[menuItemArray removeAllObjects];
}

// Connected / Connecting / Disconnecting / Disconnected update
- (void)_updateMenuItem:(NSMenuItem *)menuItem forAccount:(AIAccount *)account
{
	if(menuItem){
        if([[account supportedPropertyKeys] containsObject:@"Online"]){
            //Update the 'connect / disconnect' menu item
			
			BOOL multipleServices = ([[self activeServiceTypes] count] > 1);
			
			NSString	*accountTitle = (multipleServices ? ACCOUNT_TITLE_WITH_SERVICE : ACCOUNT_TITLE_NO_SERVICE);
			
			[[menuItem menu] setMenuChangedMessagesEnabled:NO];		
			
			if([[account statusObjectForKey:@"Online"] boolValue]){
				[menuItem setImage:[account onlineMenuImage]];
				[menuItem setTitle:[ACCOUNT_DISCONNECT_MENU_TITLE stringByAppendingString:accountTitle]];
				[menuItem setKeyEquivalent:@""];
				[menuItem setEnabled:YES];
			}else if([[account statusObjectForKey:@"Connecting"] boolValue]){
				[menuItem setImage:[account connectingMenuImage]];
				[menuItem setTitle:[ACCOUNT_CONNECTING_MENU_TITLE stringByAppendingString:accountTitle]];
				[menuItem setKeyEquivalent:@"."];
				[menuItem setEnabled:YES];
			}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
				[menuItem setImage:[account connectingMenuImage]];
				[menuItem setTitle:[ACCOUNT_DISCONNECTING_MENU_TITLE stringByAppendingString:accountTitle]];
				[menuItem setKeyEquivalent:@""];
				[menuItem setEnabled:NO];
			}else{
				[menuItem setImage:[account offlineMenuImage]];
				[menuItem setTitle:[ACCOUNT_CONNECT_MENU_TITLE stringByAppendingString:accountTitle]];
				[menuItem setKeyEquivalent:@""];
				[menuItem setEnabled:YES];
			}
			
			[[menuItem menu] setMenuChangedMessagesEnabled:YES];
        }        
		
    }	
}

//Remove all current account menu items for all account menu item plugins, then create a new, current set.
- (void)rebuildAllAccountMenuItems
{
	NSEnumerator			*enumerator = [accountMenuPluginsArray objectEnumerator];
	id<AccountMenuPlugin>   accountMenuPlugin;
	while (accountMenuPlugin = [enumerator nextObject]) {
		[self _removeAccountMenuItemsForPlugin:accountMenuPlugin];
		[self _addAccountMenuItemsForPlugin:accountMenuPlugin];
	}
}

//Account status changed, update our menu
- (NSArray *)updateListObject:(AIListObject *)inObject keys:(NSArray *)inModifiedKeys silent:(BOOL)silent
{
    if([inObject isKindOfClass:[AIAccount class]] && 
		([inModifiedKeys containsObject:@"Online"] ||
		 [inModifiedKeys containsObject:@"Connecting"] ||
		 [inModifiedKeys containsObject:@"Disconnecting"])){
		
		//Enumerate all arrays of menu items (for all plugins)
		NSEnumerator			*enumerator = [accountMenuItemArraysDict objectEnumerator];
		NSArray					*accountMenuItemArray;
		while (accountMenuItemArray = [enumerator nextObject]) {
			//Find the menu item for this account in this array
			NSMenuItem  *menuItem = [self _menuItemForAccount:(AIAccount *)inObject
													fromArray:accountMenuItemArray];
			//Update it
			[self _updateMenuItem:menuItem forAccount:(AIAccount *)inObject];
		}
    }
	
    //We don't change any keys
    return(nil);
}

//Given a target account and an array of menu items, find the menu item for that account
- (NSMenuItem *)_menuItemForAccount:(AIAccount *)account fromArray:(NSArray *)accountMenuItemArray
{
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
    NSMenuItem		*targetMenuItem = nil;
	
	//Find the menu
	enumerator = [accountMenuItemArray objectEnumerator];
	while((menuItem = [enumerator nextObject])){    
		if([menuItem representedObject] == account){
			targetMenuItem = menuItem;
			break;
		}
	}
	
	return targetMenuItem;	
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
	return(YES);
}

@end
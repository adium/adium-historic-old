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

// $Id$

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

- (BOOL)_account:(AIAccount *)account canSendContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline;

@end

@implementation AIAccountController

//init
- (void)initController
{
    availableServiceDict = [[NSMutableDictionary alloc] init];
	availableServiceTypeDict = [[NSMutableDictionary alloc] init];
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
	accountMenuItemArraysDict = [[NSMutableDictionary alloc] init];
	accountMenuPluginsArray = [[NSMutableArray alloc] init];
	_cachedActiveServices = nil;

	//Default account preferences
	[[owner preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
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
    
    //Cleanup
    [accountArray release];
	[unloadableAccounts release];
    [availableServiceDict release];
    [lastAccountIDToSendContent release];
	
	[_cachedActiveServices release]; _cachedActiveServices = nil;
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
		NSString		*serviceID = [accountDict objectForKey:ACCOUNT_TYPE];
        AIAccount		*newAccount;
        AIService		*service;
		NSString		*accountUID;
		int				accountNumber;
		
		//TEMPORARY UPGRADE CODE  0.63 -> 0.70 (Account format changed)
		//####################################
		if([serviceID isEqualToString:@"AIM-LIBGAIM"]){
			NSString 	*uid = [accountDict objectForKey:ACCOUNT_UID];
			if(uid && [uid length]){
				const char	firstCharacter = [uid characterAtIndex:0];
				
				if([uid hasSuffix:@"@mac.com"]){
					serviceID = @"libgaim-oscar-Mac";
				}else if(firstCharacter >= '0' && firstCharacter <= '9'){
					serviceID = @"libgaim-oscar-ICQ";
				}else{
					serviceID = @"libgaim-oscar-AIM";
				}
			}
		}else if([serviceID isEqualToString:@"GaduGadu-LIBGAIM"]){
			serviceID = @"libgaim-Gadu-Gadu";
		}else if([serviceID isEqualToString:@"Jabber-LIBGAIM"]){
			serviceID = @"libgaim-Jabber";
		}else if([serviceID isEqualToString:@"MSN-LIBGAIM"]){
			serviceID = @"libgaim-MSN";
		}else if([serviceID isEqualToString:@"Napster-LIBGAIM"]){
			serviceID = @"libgaim-Napster";
		}else if([serviceID isEqualToString:@"Novell-LIBGAIM"]){
			serviceID = @"libgaim-GroupWise";
		}else if([serviceID isEqualToString:@"Sametime-LIBGAIM"]){
			serviceID = @"libgaim-Sametime";
		}else if([serviceID isEqualToString:@"Yahoo-LIBGAIM"]){
			serviceID = @"libgaim-Yahoo!";
		}else if([serviceID isEqualToString:@"Yahoo-Japan-LIBGAIM"]){
			serviceID = @"libgaim-Yahoo!-Japan";
		}
		//####################################
		
		//Fetch the account service, UID, and ID
		service = [self serviceWithUniqueID:serviceID];
		accountUID = [accountDict objectForKey:ACCOUNT_UID];
		accountNumber = [[accountDict objectForKey:ACCOUNT_OBJECT_ID] intValue];
		
        //Create the account and add it to our array
        if(service && accountUID && [accountUID length]){
			if(newAccount = [self createAccountWithService:service UID:accountUID accountNumber:accountNumber]){
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
		
		[flatAccount setObject:[[account service] serviceCodeUniqueID] forKey:ACCOUNT_TYPE]; 	//Unique plugin ID
		[flatAccount setObject:[[account service] serviceID] forKey:ACCOUNT_SERVICE];	    	//Shared service ID
		[flatAccount setObject:[account UID] forKey:ACCOUNT_UID];		    					//Account UID
		[flatAccount setObject:[account internalObjectID] forKey:ACCOUNT_OBJECT_ID];  			//Account Object ID
		
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
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID accountNumber:(int)inAccountNumber
{	
	//Filter the UID
	inUID = [service filterUID:inUID removeIgnoredCharacters:YES];
	
	//If no object ID is provided, use the next largest
	if(!inAccountNumber){
		inAccountNumber = [[[owner preferenceController] preferenceForKey:TOP_ACCOUNT_ID group:PREF_GROUP_ACCOUNTS] intValue];
		[[owner preferenceController] setPreference:[NSNumber numberWithInt:inAccountNumber + 1]
											 forKey:TOP_ACCOUNT_ID
											  group:PREF_GROUP_ACCOUNTS];
	}
	
	//Create the account
	return([service accountWithUID:inUID accountNumber:inAccountNumber]);
}


//Services -------------------------------------------------------------------------------------------------------
#pragma mark Services
//Sort an array of services alphabetically by their description
int _alphabeticalServiceSort(id service1, id service2, void *context)
{
	return([(NSString *)[service1 longDescription] caseInsensitiveCompare:(NSString *)[service2 longDescription]]);
}

//Return the available services.  These are used for account creation.
- (NSArray *)availableServices
{
	return([[availableServiceDict allValues] sortedArrayUsingFunction:_alphabeticalServiceSort context:nil]);
}

//Return the active services (services for which there is an account).  These are used for contact creation and determining if
//the service of accounts and contacts should be presented to the user.
//Simultaneously determine if any active service can 
- (NSArray *)activeServices
{
	if(!_cachedActiveServices){
		NSMutableArray	*serviceArray = [NSMutableArray array];
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		AIAccount		*account;

		//Build an array of all currently used services
		while(account = [enumerator nextObject]){
			NSEnumerator	*serviceEnumerator;
			AIService		*accountService;
			
			//Add all services that are of the same class as the user's account (So, all compatible services)
			serviceEnumerator = [[self servicesWithServiceClass:[[account service] serviceClass]] objectEnumerator];
			while(accountService = [serviceEnumerator nextObject]){
				//Prevent any service from going in twice
				if(![serviceArray containsObject:accountService]){
					[serviceArray addObject:accountService];
				}

			}
		}
		
		//Sort
		_cachedActiveServices = [[serviceArray sortedArrayUsingFunction:_alphabeticalServiceSort context:nil] retain];
	}
	
	return(_cachedActiveServices);
}

//Returns the specified service controller
- (AIService *)serviceWithUniqueID:(NSString *)identifier
{
    return([availableServiceDict objectForKey:identifier]);
}

//Return the first service with the specified serviceID
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID
{
	NSEnumerator	*enumerator = [availableServiceDict objectEnumerator];
	AIService		*service;
	
	while(service = [enumerator nextObject]){
		if([[service serviceID] isEqualToString:serviceID]) break;
	}
	
	return(service);
}

- (NSArray *)servicesWithServiceClass:(NSString *)serviceClass
{
	NSEnumerator	*enumerator = [availableServiceDict objectEnumerator];
	AIService		*service;
	NSMutableArray	*servicesArray = [NSMutableArray array];
		
	while(service = [enumerator nextObject]){
		if([[service serviceClass] isEqualToString:serviceClass]) [servicesArray addObject:service];
	}
	
	return(servicesArray);
}

//Register service code
- (void)registerService:(AIService *)inService
{
	NSLog(@"Registering %@ (%@ ; %@)",inService,[inService serviceCodeUniqueID],[inService serviceID]);
    [availableServiceDict setObject:inService forKey:[inService serviceCodeUniqueID]];
	
	[availableServiceTypeDict setObject:inService forKey:[inService serviceID]];
}

//Returns a menu of all services.
//- Selector called on service selection is selectAccount:
//- The menu item's represented objects are the service controllers they represent
- (NSMenu *)menuOfServicesWithTarget:(id)target activeServicesOnly:(BOOL)activeServicesOnly longDescription:(BOOL)longDescription
{	
	AIServiceImportance	importance;
	unsigned			numberOfItems = 0;
	NSArray				*serviceArray;
	
	//Prepare our menu
	NSMenu *menu = [[NSMenu alloc] init];

	serviceArray = (activeServicesOnly ? [self activeServices] : [self availableServices]);
	
	//Divide our menu into sections.  This helps separate less importance services from the others (sorry guys!)
	for(importance = AIServicePrimary; importance <= AIServiceUnsupported; importance++){
		NSEnumerator	*enumerator;
		AIService		*service;
		unsigned		currentNumberOfItems;
		BOOL			addedDivider = NO;
		
		//Divider
		currentNumberOfItems = [menu numberOfItems];
		if (currentNumberOfItems > numberOfItems){
			[menu addItem:[NSMenuItem separatorItem]];
			numberOfItems = currentNumberOfItems + 1;
			addedDivider = YES;
		}

		//Insert a menu item for each service of this importance
		enumerator = [serviceArray objectEnumerator];
		while((service = [enumerator nextObject])){
			if([service serviceImportance] == importance){
				NSMenuItem	*item = [[[NSMenuItem alloc] initWithTitle:(longDescription ?
																		[service longDescription] :
																		[service shortDescription])
																target:target 
																action:@selector(selectServiceType:) 
														 keyEquivalent:@""] autorelease];
				[item setRepresentedObject:service];
				[item setImage:[AIServiceIcons serviceIconForService:service
																type:AIServiceIconSmall
														   direction:AIIconNormal]];
				[menu addItem:item];
			}
		}
		
		//If we added a divider but didn't add any items, remove it
		currentNumberOfItems = [menu numberOfItems];
		if (addedDivider && (currentNumberOfItems <= numberOfItems) && (currentNumberOfItems > 0)){
			[menu removeItemAtIndex:(currentNumberOfItems-1)];
		}
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
- (AIAccount *)accountWithAccountNumber:(int)accountNumber
{
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
        if([account accountNumber] == accountNumber) break;
    }
    
    return(account);
}

//Searches the account list for accounts with the specified service ID
- (NSArray *)accountsWithService:(AIService *)service
{
	NSMutableArray	*array = [NSMutableArray array];
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
		if([account service] == service) [array addObject:account];
    }
    
    return(array);
}

//Searches the account list for accounts with the specified service's serviceClass
//This could use other methods but that would require alloc'ing significantly more NSArrays, so we consolidate
//for efficiency.
- (NSArray *)accountsWithServiceClassOfService:(AIService *)service
{
	return([self accountsWithServiceClass:[service serviceClass]]);
}

- (NSArray *)accountsWithServiceClass:(NSString *)serviceClass
{
	NSMutableArray	*accountsArray = [NSMutableArray array];
	NSEnumerator	*enumerator = [availableServiceDict objectEnumerator];
    AIService		*aService;
	
	//Enumerate all available services
	while(aService = [enumerator nextObject]){
		//Find matching serviceClasses
		if([[aService serviceClass] isEqualToString:serviceClass]){
			
			//Find matching accounts
			NSEnumerator	*enumerator = [accountArray objectEnumerator];
			AIAccount		*account;
			
			while((account = [enumerator nextObject])){
				if ([account service] == aService){
					[accountsArray addObject:account];
				}
			}
		}
	}
	
	return(accountsArray);
}


- (AIAccount *)firstAccountWithService:(AIService *)service
{
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account;
    
    while((account = [enumerator nextObject])){
		if([account service] == service) break;
    }
    
    return(account);
}

//Returns a new default account
- (AIAccount *)defaultAccount
{
	return([self createAccountWithService:[self serviceWithUniqueID:@"libgaim-oscar-AIM"] UID:@"" accountNumber:0]);
}

- (BOOL)anOnlineAccountCanCreateGroupChats
{
	NSEnumerator	*enumerator;
	AIAccount		*account;
	BOOL			anOnlineAccountCanCreateGroupChats;
	
	anOnlineAccountCanCreateGroupChats = NO;
	
    enumerator = [accountArray objectEnumerator];
    while(account = [enumerator nextObject]){	
		if ([account online] && [[account service] canCreateGroupChats]){
			anOnlineAccountCanCreateGroupChats = YES;
			break;
		}
	}
	
	return(anOnlineAccountCanCreateGroupChats);
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
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(AIService *)inService
{
    //Add an account with the new service
	AIAccount	*newAccount = [self createAccountWithService:inService
														 UID:[inAccount UID]
											   accountNumber:[inAccount accountNumber]];
    [self insertAccount:newAccount atIndex:[accountArray indexOfObject:inAccount] save:NO];
    
    //Delete the old account
    [self deleteAccount:inAccount save:YES];
    
    return(newAccount);
}

//Change the UID of an existing account
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID
{
	//Add an account with the new UID
	AIAccount	*newAccount = [self createAccountWithService:[inAccount service]
														 UID:inUID
											   accountNumber:[inAccount accountNumber]];
	[newAccount setPreference:[[inAccount service] filterUID:inUID removeIgnoredCharacters:NO]
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
	[_cachedActiveServices release]; _cachedActiveServices = nil;

	// Perform a full rebuild rather than trying to figure out what is different.
	[self rebuildAllAccountMenuItems];
}

//Preferred Source Accounts --------------------------------------------------------------------------------------------
#pragma mark Preferred Source Accounts
//Returns the preferred choice for sending content to the passed list object
//When presenting the user with a list of accounts, this should be the one selected by default
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact 
{
	return ([self preferredAccountForSendingContentType:inType toContact:inContact includeOffline:NO]);
}

- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline
{
	AIAccount	*account;
	
    if(inContact){
		NSEnumerator	*enumerator;
		
		//If we've messaged this object previously, and the account we used to message it is online, return that account
        int accountID = [[inContact preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
											   group:PREF_GROUP_PREFERRED_ACCOUNTS] intValue];
        if(accountID && (account = [self accountWithAccountNumber:accountID])){
            if([account availableForSendingContentType:inType toContact:inContact]){
                return(account);
            }
        }
		
		//If inObject is an AIListContact return the account the object is on
		if(account = [inContact account]){
			if([account availableForSendingContentType:inType toContact:inContact]){
				return(account);
			}
		}
		
		//Return the last account used to message someone on this service
		NSString	*lastAccountID = [lastAccountIDToSendContent objectForKey:[[inContact service] serviceID]];
		if(lastAccountID && (account = [self accountWithAccountNumber:[lastAccountID intValue]])){
			if([account availableForSendingContentType:inType toContact:nil] || includeOffline){
				return(account);
			}
		}
		
		if (includeOffline){
			//If inObject is an AIListContact return the account the object is on even if the account is offline
			if(account = [inContact account]){
				return(account);
			}
		}
		
		//First available account in our list of the correct service type
		enumerator = [accountArray objectEnumerator];
		while(account = [enumerator nextObject]){
			if([inContact service] == [account service] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
		
		//First available account in our list of a compatible service type
		enumerator = [accountArray objectEnumerator];
		while(account = [enumerator nextObject]){
			if([[inContact serviceClass] isEqualToString:[account serviceClass]] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
		
		
	}else{
		//First available account in our list
		NSEnumerator	*enumerator = [accountArray objectEnumerator];
		while(account = [enumerator nextObject]){
			if([account availableForSendingContentType:inType toContact:nil]){
				return(account);
			}
		}
	}
	
	//Can't find anything
	return(nil);
}

//Returns a menu of all accounts returned by menuItemsForAccountsWithTarget
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline
{
	return ([self menuOfAccountsWithTarget:target includeOffline:includeOffline onlyIfCreatingGroupChatIsSupported:NO]);
}

//Returns a menu of all accounts (optionally, which can create a group chat) returned by menuItemsForAccountsWithTarget
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline onlyIfCreatingGroupChatIsSupported:(BOOL)groupChatCreator
{
	NSMenu			*menu = [[NSMenu alloc] init];
	NSEnumerator	*enumerator;
	NSMenuItem		*menuItem;
	
	enumerator = [[self menuItemsForAccountsWithTarget:target includeOffline:includeOffline] objectEnumerator];
	while(menuItem = [enumerator nextObject]){
		if (!groupChatCreator || [[[menuItem representedObject] service] canCreateGroupChats]){
			[menu addItem:menuItem];
		}
	}
	
	return([menu autorelease]);
}

//Returns an array containing menu items for all accounts. 
//- Accounts not available for sending content are disabled.
//- Selector called on account selection is selectAccount:
//- The menu item's represented objects are the AIAccounts they represent
- (NSArray *)menuItemsForAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline
{
	NSMutableArray  *menuItems = [[NSMutableArray alloc] init];
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//We don't show service types unless the user is using multiple services
	BOOL 	multipleServices = ([[self activeServices] count] > 1);
	
    //Insert a menu item for each available account
    enumerator = [accountArray objectEnumerator];
    while(account = [enumerator nextObject]){
		BOOL available = [[owner contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE
																		 toContact:nil 
																		 onAccount:account];
		
		if(available || includeOffline){
			NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:(multipleServices ?
																		[NSString stringWithFormat:@"%@ (%@)", [account formattedUID], [[account service] shortDescription]] :
																		[account formattedUID])
																target:target
																action:@selector(selectAccount:)
														 keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:account];
			[menuItem setImage:[AIServiceIcons serviceIconForObject:account
															   type:AIServiceIconSmall
														  direction:AIIconNormal]];
			[menuItem setEnabled:available];
			
			[menuItems addObject:menuItem];
		}
    }
	
	return([menuItems autorelease]);
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
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		NSMenuItem	*menuItem = [[[NSMenuItem alloc] initWithTitle:[account formattedUID]
															target:target
															action:@selector(selectAccount:)
													 keyEquivalent:@""] autorelease];
		[menuItem setRepresentedObject:account];
		[menuItem setImage:[AIServiceIcons serviceIconForObject:account
														   type:AIServiceIconSmall
													  direction:AIIconNormal]];
		[menu addItem:menuItem];
	}
}

- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline
{
	NSMutableArray	*sourceAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[owner accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while(account = [enumerator nextObject]){
		if((!inObject && !inPreferred) || 
		   ([self _account:account canSendContentType:inType toListObject:inObject preferred:inPreferred includeOffline:includeOffline])){
			
			[sourceAccounts addObject:account];
		}
	}
	
	return(sourceAccounts);
}

- (BOOL)_account:(AIAccount *)account canSendContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline
{
	BOOL			canSend = NO;
	
	if ([inObject isKindOfClass:[AIMetaContact class]]){		
		NSEnumerator	*enumerator = [[(AIMetaContact *)inObject listContacts] objectEnumerator];
		AIListObject	*containedObject;
		
		//canSend is YES if any of the contained contacts of the meta contact return YES
		while (containedObject = [enumerator nextObject]){
			if ([self _account:account canSendContentType:inType toListObject:containedObject preferred:inPreferred includeOffline:includeOffline]){
				
				canSend = YES;
				break;
			}
		}

	}else{
		if ([[inObject serviceClass] isEqualToString:[account serviceClass]]){
			BOOL			knowsObject = NO;
			BOOL			canFindObject = NO;
			AIListContact	*contactForAccount = [[owner contactController] existingContactWithService:[inObject service]
																							   account:account
																								   UID:[inObject UID]];
			
			//Does the account know this object?
			if(contactForAccount){
				knowsObject = [account availableForSendingContentType:CONTENT_MESSAGE_TYPE
															toContact:contactForAccount];
			}
			
			//Could the account find this object?
			canFindObject = [account availableForSendingContentType:CONTENT_MESSAGE_TYPE toContact:nil];
			
			if((inPreferred && knowsObject) ||						//Online and can see the object
			   (!inPreferred && !knowsObject && canFindObject) ||	//Online and may be able to see the object
			   (!inPreferred && !knowsObject && includeOffline)){	//Offline, but may be able to see the object if online
				canSend = YES;
			}
		}
	}
	
	return(canSend);
}

//Watch outgoing content, remembering the user's choice of source account
- (void)didSendContent:(NSNotification *)notification
{
    AIChat			*chat = [notification object];
    AIListObject	*destObject = [chat listObject];
    
    if(chat && destObject){
        AIContentObject *contentObject = [[notification userInfo] objectForKey:@"Object"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
        
        [destObject setPreference:[NSNumber numberWithInt:[sourceAccount accountNumber]]
                           forKey:KEY_PREFERRED_SOURCE_ACCOUNT
                            group:PREF_GROUP_PREFERRED_ACCOUNTS];
        
        [lastAccountIDToSendContent setObject:[sourceAccount internalObjectID] forKey:[[destObject service] serviceID]];
    }
}


//Connection convenience methods ---------------------------------------------------------------------------------------
#pragma mark Connection Convenience Methods
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

- (BOOL)oneOrMoreConnectedAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;
    
	NSString			*ONLINE = @"Online";
	
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account preferenceForKey:ONLINE group:GROUP_ACCOUNT_STATUS] boolValue]){
			return YES;
        }
    }	
	
	return NO;
}

//Password Storage -----------------------------------------------------------------------------------------------------
#pragma mark Password Storage
- (NSString *)_accountNameForAccount:(AIAccount *)inAccount{
	return([NSString stringWithFormat:@"%@.%@",[[inAccount service] serviceID],[inAccount internalObjectID]]);
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
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
    NSString	*password;
    
    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForAccount:inAccount]
                                                     account:[self _accountNameForAccount:inAccount]];
    
    if(password && [password length] != 0){
        //Invoke the target right away
        [inTarget performSelector:inSelector withObject:password withObject:inContext afterDelay:0.0001];
    }else{
        //Prompt the user for their password
        [ESAccountPasswordPromptController showPasswordPromptForAccount:inAccount
														notifyingTarget:inTarget
															   selector:inSelector
																context:inContext];
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

- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext
{
	NSString	*password;
    
    //check the keychain for this password
    password = [AIKeychain getPasswordFromKeychainForService:[self _passKeyForProxyServer:server]
                                                     account:[self _accountNameForProxyServer:server userName:userName]];

    if(password && [password length] != 0){
        //Invoke the target right away
        [inTarget performSelector:inSelector withObject:password withObject:inContext afterDelay:0.0001];    
    }else{
        //Prompt the user for their password
        [ESProxyPasswordPromptController showPasswordPromptForProxyServer:server
																 userName:userName
														  notifyingTarget:inTarget
																 selector:inSelector
																  context:inContext];
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

#define MENU_IMAGE_FRACTION_ONLINE  		1.00
#define MENU_IMAGE_FRACTION_CONNECTING  	0.60
#define MENU_IMAGE_FRACTION_OFFLINE  		0.30

#define	ACCOUNT_CONNECT_MENU_TITLE			AILocalizedString(@"Connect: %@","Connect account prefix")
#define	ACCOUNT_DISCONNECT_MENU_TITLE		AILocalizedString(@"Disconnect: %@","Disconnect account prefix")
#define	ACCOUNT_CONNECTING_MENU_TITLE		AILocalizedString(@"Cancel: %@","Connecting an account prefix")
#define	ACCOUNT_DISCONNECTING_MENU_TITLE	AILocalizedString(@"Cancel: %@","Disconnecting an account prefix")
#define	ACCOUNT_AUTO_CONNECT_MENU_TITLE		AILocalizedString(@"Auto-Connect on Launch",nil)

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
		
		if([[account supportedPropertyKeys] containsObject:@"Online"]){
			//Create the account's menu item (the title will be set by_updateMenuItem:forAccount:
			menuItem = [[[NSMenuItem alloc] initWithTitle:@""
												   target:self
												   action:@selector(toggleConnection:)
											keyEquivalent:@""] autorelease];
			[menuItem setRepresentedObject:account];
			[menuItemArray addObject:menuItem];
			
			[self _updateMenuItem:menuItem forAccount:account];
		}
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
		NSString	*accountTitle = [account formattedUID];
		NSImage		*serviceImage;
		float		fraction;
		NSString	*titleFormat;
		
		//Default to <New Account> if a name is not available
		if(!accountTitle || ![accountTitle length]) accountTitle = NEW_ACCOUNT_DISPLAY_TEXT;
		
		//Dim image depending on connectivity
		serviceImage = [AIServiceIcons serviceIconForObject:account
													   type:AIServiceIconSmall
												  direction:AIIconNormal];
		if([[account statusObjectForKey:@"Online"] boolValue]){
			fraction = MENU_IMAGE_FRACTION_ONLINE;
			titleFormat = ACCOUNT_DISCONNECT_MENU_TITLE;
		}else if([[account statusObjectForKey:@"Connecting"] boolValue]){
			fraction = MENU_IMAGE_FRACTION_CONNECTING;
			titleFormat = ACCOUNT_CONNECTING_MENU_TITLE;
			
		}else if([[account statusObjectForKey:@"Disconnecting"] boolValue]){
			fraction = MENU_IMAGE_FRACTION_CONNECTING;
			titleFormat = ACCOUNT_DISCONNECTING_MENU_TITLE;
		}else{
			fraction = MENU_IMAGE_FRACTION_OFFLINE;
			titleFormat = ACCOUNT_CONNECT_MENU_TITLE;
		}

		//Update the menu item
		[[menuItem menu] setMenuChangedMessagesEnabled:NO];
		[menuItem setTitle:[[NSString stringWithFormat:titleFormat,accountTitle] stringByAppendingFormat:@" (%@)",[[account service] shortDescription]]];
		[menuItem setImage:[serviceImage imageByFadingToFraction:fraction]];
		[menuItem setEnabled:(![[account statusObjectForKey:@"Connecting"] boolValue] &&
							  ![[account statusObjectForKey:@"Disconnecting"] boolValue])];
		[[menuItem menu] setMenuChangedMessagesEnabled:YES];

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

@implementation AIAccountController (AIAccountControllerObjectSpecifier)
- (NSScriptObjectSpecifier *) objectSpecifier {
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	NSScriptObjectSpecifier *container = [[NSApplication sharedApplication] objectSpecifier];
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"accountController"] autorelease];
}
@end
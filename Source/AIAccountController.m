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

// $Id$

#import "AIAccountController.h"
#import "AIContactController.h"
#import "AIContentController.h"
#import "AILoginController.h"
#import "AIPreferenceController.h"
#import "AIStatusController.h"
#import <AIUtilities/AIDictionaryAdditions.h>
#import <AIUtilities/AIMenuAdditions.h>
#import <AIUtilities/CBObjectAdditions.h>
#import <AIUtilities/ESImageAdditions.h>
#import <Adium/AIAccount.h>
#import <Adium/AIChat.h>
#import <Adium/AIContentMessage.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListContact.h>
#import <Adium/AIListObject.h>
#import <Adium/AIMetaContact.h>
#import <Adium/AIService.h>
#import <Adium/AIServiceIcons.h>
#import <Adium/AIStatusIcons.h>
#import "AdiumServices.h"
#import "AdiumPasswords.h"

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
- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline;
- (BOOL)_account:(AIAccount *)account canSendContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline;
- (void)_upgradePasswords;
- (void)_addMenuItemsToMenu:(NSMenu *)menu withTarget:(id)target forAccounts:(NSArray *)accounts;
@end

@implementation AIAccountController

- (void)awakeFromNib
{
	adiumServices = [[AdiumServices alloc] init];
	adiumPasswords = [[AdiumPasswords alloc] init];
}

//Services
#pragma mark Services
- (void)registerService:(AIService *)inService{
	[adiumServices registerService:inService];
}
- (NSArray *)services{
	return [adiumServices services];
}
- (NSArray *)activeServices{
	return [adiumServices activeServices];
}
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID{
	return [adiumServices serviceWithUniqueID:uniqueID];
}
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID{
	return [adiumServices firstServiceWithServiceID:serviceID];
}

//Passwords
#pragma mark Accounts
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount{
	[adiumPasswords setPassword:inPassword forAccount:inAccount];
}
- (void)forgetPasswordForAccount:(AIAccount *)inAccount{
	[adiumPasswords forgetPasswordForAccount:inAccount];
}
- (NSString *)passwordForAccount:(AIAccount *)inAccount{
	return [adiumPasswords passwordForAccount:inAccount];
}
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext{
	[adiumPasswords passwordForAccount:inAccount notifyingTarget:inTarget selector:inSelector context:inContext];
}
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName{
	[adiumPasswords setPassword:inPassword forProxyServer:server userName:userName];
}
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName{
	return [adiumPasswords passwordForProxyServer:server userName:userName];
}
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext{
	[adiumPasswords passwordForProxyServer:server userName:userName notifyingTarget:inTarget selector:inSelector context:inContext];
}



				





//init
- (void)initController
{
    accountArray = nil;
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
	
	//Default account preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
}

//Finish initialization once other controllers have set themselves up
- (void)finishIniting
{   
    //Load the user accounts
    [self loadAccounts];
    
    //Observe content (for accountForSendingContentToContact)
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];

	/* Temporary upgrade code! */
	NSUserDefaults	*userDefaults = [NSUserDefaults standardUserDefaults];
	NSNumber	*didPasswordUpgrade = [userDefaults objectForKey:@"Adium:Did Password Upgrade"];
	if(!didPasswordUpgrade || ![didPasswordUpgrade boolValue]){
		[userDefaults setObject:[NSNumber numberWithBool:YES]
						 forKey:@"Adium:Did Password Upgrade"];
		[userDefaults synchronize];

		if([accountArray count]){
			[self _upgradePasswords];
		}
	}
}

//close
- (void)closeController
{
    //Disconnect all accounts
    [self disconnectAllAccounts];
    
    //Remove observers (otherwise, every account added will be a duplicate next time around)
    [[adium notificationCenter] removeObserver:self];
}

- (void)dealloc
{
	//Cleanup
    [accountArray release];
	[unloadableAccounts release];
    [lastAccountIDToSendContent release];
	
	[super dealloc];
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
	
	accountList = [[adium preferenceController] preferenceForKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	
    //Create an instance of every saved account
	enumerator = [accountList objectEnumerator];
	while((accountDict = [enumerator nextObject])){
		NSString		*serviceID = [accountDict objectForKey:ACCOUNT_TYPE];
        AIAccount		*newAccount;
        AIService		*service;
		NSString		*accountUID;
		NSString		*internalObjectID;
		
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

		//XXX: Temporary Rendezvous -> Bonjour code
		if([serviceID isEqualToString:@"rvous-libezv"]){
			serviceID = @"bonjour-libezv";
		}
		
		//Fetch the account service, UID, and ID
		service = [[adium accountController] serviceWithUniqueID:serviceID];
		accountUID = [accountDict objectForKey:ACCOUNT_UID];
		internalObjectID = [accountDict objectForKey:ACCOUNT_OBJECT_ID];
		
        //Create the account and add it to our array
        if(service && accountUID && [accountUID length]){
			if((newAccount = [self createAccountWithService:service UID:accountUID internalObjectID:internalObjectID])){
                [accountArray addObject:newAccount];
            }else{
				[unloadableAccounts addObject:accountDict];
			}
        }
    }
	
	//Broadcast an account list changed notification
    [[adium notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

//Save the accounts
- (void)saveAccounts
{
	NSMutableArray	*flatAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator;
	AIAccount		*account;
	
	//Build a flattened array of the accounts
	enumerator = [accountArray objectEnumerator];
	while((account = [enumerator nextObject])){
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
	[[adium preferenceController] setPreference:flatAccounts forKey:ACCOUNT_LIST group:PREF_GROUP_ACCOUNTS];
	
	//Broadcast an account list changed notification
	[[adium notificationCenter] postNotificationName:Account_ListChanged object:nil userInfo:nil];
}

//Returns a new account of the specified type (Unique service plugin ID)
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID internalObjectID:(NSString *)internalObjectID
{	
	//Filter the UID
	inUID = [service filterUID:inUID removeIgnoredCharacters:YES];
	
	//If no object ID is provided, use the next largest integer
	if(!internalObjectID){
		int	topAccountID = [[[adium preferenceController] preferenceForKey:TOP_ACCOUNT_ID group:PREF_GROUP_ACCOUNTS] intValue];
		internalObjectID = [NSString stringWithFormat:@"%i",topAccountID];
		[[adium preferenceController] setPreference:[NSNumber numberWithInt:topAccountID + 1]
											 forKey:TOP_ACCOUNT_ID
											  group:PREF_GROUP_ACCOUNTS];
	}
	
	//Create the account
	return([service accountWithUID:inUID internalObjectID:internalObjectID]);
}



//Accounts -------------------------------------------------------------------------------------------------------
#pragma mark Accounts
//Returns all available accounts
- (NSArray *)accountArray
{
    return(accountArray);
}

//Searches the account list for the specified account
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID
{
    NSEnumerator	*enumerator = [accountArray objectEnumerator];
    AIAccount		*account = nil;
	
	//XXX - Temporary Upgrade code for account internalObjectIDs stored as NSNumbers 0.7x -> 0.8 -ai
	if(![objectID isKindOfClass:[NSString class]]){
		if([objectID isKindOfClass:[NSNumber class]]){
			objectID = [NSString stringWithFormat:@"%i",[(NSNumber *)objectID intValue]];
		}else{
			objectID = nil; //Unrecognizable, ignore
		}
	}
    
    while(objectID && (account = [enumerator nextObject])){
        if([objectID isEqualToString:[account internalObjectID]]) break;
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
	NSMutableArray	*matchingAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	
	while((account = [enumerator nextObject])){
		if([[[account service] serviceClass] isEqualToString:serviceClass]){
			[matchingAccounts addObject:account];
		}
	}
	
	return(matchingAccounts);
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

- (BOOL)anOnlineAccountCanCreateGroupChats
{
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	
    while((account = [enumerator nextObject])){	
		if([account online] && [[account service] canCreateGroupChats]) return(YES);
	}
	
	return(NO);
}

- (BOOL)anOnlineAccountCanEditContacts
{
	NSEnumerator	*enumerator = [accountArray objectEnumerator];
	AIAccount		*account;
	
    while((account = [enumerator nextObject])){	
		if([account contactListEditable]) return(YES);
	}
	
	return(NO);
}


//Account Editing ------------------------------------------------------------------------------------------------------
#pragma mark Account Editing
- (AIAccount *)newAccountAtIndex:(int)index forService:(AIService *)service
{
	if(index == -1) index = [accountArray count];

    NSParameterAssert(accountArray != nil);
    NSParameterAssert(index >= 0 && index <= [accountArray count]);
	NSParameterAssert(service != nil);
	
	AIAccount *newAccount;
	
		newAccount = [self createAccountWithService:service	UID:@"" internalObjectID:nil];
	
	[self insertAccount:newAccount atIndex:index save:YES];
	
    return(newAccount);
}

//Insert an account
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index save:(BOOL)shouldSave
{    
	if(index == -1) index = [accountArray count];

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

	//Don't let the account dealloc until we have a chance to notify everyone that it's gone
	[inAccount retain]; 

	//Let the account take any action it wants before being deleted, such as disconnecting
	[inAccount willBeDeleted];
	
	//Remove from our array
	[accountArray removeObject:inAccount];
	
	//Clean up the keychain -- forget the stored password
	[self forgetPasswordForAccount:inAccount];
	
	//Save if appropriate
	if (shouldSave){
		[self saveAccounts];
	}
	
	//Cleanup
	[inAccount release];
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
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact 
{
	return ([self preferredAccountForSendingContentType:inType toContact:inContact includeOffline:NO]);
}

- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline
{
	AIAccount		*account;
	
	//If passed a contact, we have a few better ways to determine the account than just using the first
    if(inContact){
		//If we've messaged this object previously, and the account we used to message it is online, return that account
        NSString *accountID = [inContact preferenceForKey:KEY_PREFERRED_SOURCE_ACCOUNT
													group:PREF_GROUP_PREFERRED_ACCOUNTS];
        if(accountID && (account = [self accountWithInternalObjectID:accountID])){
            if([account availableForSendingContentType:inType toContact:inContact]){
                return(account);
            }
        }
		
		//If inObject is an AIListContact return the account the object is on
		if((account = [inContact account])){
			if([account availableForSendingContentType:inType toContact:inContact]){
				return(account);
			}
		}
		
		//Return the last account used to message someone on this service
		NSString	*lastAccountID = [lastAccountIDToSendContent objectForKey:[[inContact service] serviceID]];
		if(lastAccountID && (account = [self accountWithInternalObjectID:lastAccountID])){
			if([account availableForSendingContentType:inType toContact:nil] || includeOffline){
				return(account);
			}
		}
		
		if (includeOffline){
			//If inObject is an AIListContact return the account the object is on even if the account is offline
			if((account = [inContact account])){
				return(account);
			}
		}
	}
	
	//If the previous attempts failed, or we weren't passed a contact, use the first appropraite account
	return([self firstAccountAvailableForSendingContentType:inType
												  toContact:inContact
											 includeOffline:includeOffline]);
}

- (AIAccount *)firstAccountAvailableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline
{
	AIAccount		*account;
	NSEnumerator	*enumerator;
	
    if(inContact){
		//First available account in our list of the correct service type
		enumerator = [accountArray objectEnumerator];
		while((account = [enumerator nextObject])){
			if([inContact service] == [account service] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
		
		//First available account in our list of a compatible service type
		enumerator = [accountArray objectEnumerator];
		while((account = [enumerator nextObject])){
			if([[inContact serviceClass] isEqualToString:[account serviceClass]] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
	}else{
		//First available account in our list
		enumerator = [accountArray objectEnumerator];
		while((account = [enumerator nextObject])){
			if([account availableForSendingContentType:inType toContact:nil] || includeOffline){
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
	while((menuItem = [enumerator nextObject])){
		if (!groupChatCreator || [[[menuItem representedObject] service] canCreateGroupChats]){
			[menu addItem:menuItem];
		}
	}

	if(!target) [menu setAutoenablesItems:NO];

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
	BOOL 	multipleServices = ([[[adium accountController] activeServices] count] > 1);
	
    //Insert a menu item for each available account
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
		BOOL available = [[adium contentController] availableForSendingContentType:CONTENT_MESSAGE_TYPE
																		 toContact:nil 
																		 onAccount:account];
		
		if(available || includeOffline){
			NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:(multipleServices ?
																								  [NSString stringWithFormat:@"%@ (%@)", [account formattedUID], [[account service] shortDescription]] :
																								  [account formattedUID])
																						  target:target
																						  action:@selector(selectAccount:)
																				   keyEquivalent:@""];
			[menuItem setRepresentedObject:account];
			[menuItem setImage:[AIServiceIcons serviceIconForObject:account
															   type:AIServiceIconSmall
														  direction:AIIconNormal]];
			[menuItem setEnabled:available];
			
			[menuItems addObject:menuItem];
			[menuItem release];
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
	
	while((account = [enumerator nextObject])){
		NSMenuItem	*menuItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:[account formattedUID]
																					 target:target
																					 action:@selector(selectAccount:)
																			  keyEquivalent:@""];
		[menuItem setRepresentedObject:account];
		[menuItem setImage:[AIServiceIcons serviceIconForObject:account
														   type:AIServiceIconSmall
													  direction:AIIconNormal]];
		[menu addItem:menuItem];
		[menuItem release];
	}
}

- (NSArray *)_accountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject preferred:(BOOL)inPreferred includeOffline:(BOOL)includeOffline
{
	NSMutableArray	*sourceAccounts = [NSMutableArray array];
	NSEnumerator	*enumerator = [[[adium accountController] accountArray] objectEnumerator];
	AIAccount		*account;
	
	while((account = [enumerator nextObject])){
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
		while ((containedObject = [enumerator nextObject])){
			if ([self _account:account canSendContentType:inType toListObject:containedObject preferred:inPreferred includeOffline:includeOffline]){
				
				canSend = YES;
				break;
			}
		}

	}else{
		if ([[inObject serviceClass] isEqualToString:[account serviceClass]]){
			BOOL			knowsObject = NO;
			BOOL			canFindObject = NO;
			AIListContact	*contactForAccount = [[adium contactController] existingContactWithService:[inObject service]
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
	NSDictionary	*userInfo = [notification userInfo];
    AIChat			*chat = [userInfo objectForKey:@"AIChat"];
    AIListObject	*destObject = [chat listObject];
    
    if(chat && destObject){
        AIContentObject *contentObject = [userInfo objectForKey:@"AIContentObject"];
        AIAccount		*sourceAccount = (AIAccount *)[contentObject source];
        
        [destObject setPreference:[sourceAccount internalObjectID]
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

    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
		   [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            [account setPreference:nil forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

- (BOOL)oneOrMoreConnectedAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;

    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([account online]){
			return YES;
        }
    }	
	
	return NO;
}

- (BOOL)oneOrMoreConnectedOrConnectingAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;
	
    enumerator = [accountArray objectEnumerator];
    while((account = [enumerator nextObject])){
        if([account online] || [account integerStatusObjectForKey:@"Connecting"]){
			return YES;
        }
    }	

	return NO;	
}

@end

@implementation AIAccountController (AIAccountControllerObjectSpecifier)
- (NSScriptObjectSpecifier *) objectSpecifier {
	id classDescription = [NSClassDescription classDescriptionForClass:[NSApplication class]];
	NSScriptObjectSpecifier *container = [[NSApplication sharedApplication] objectSpecifier];
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription:classDescription containerSpecifier:container key:@"accountController"] autorelease];
}
@end

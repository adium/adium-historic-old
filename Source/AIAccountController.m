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
#import "AdiumAccounts.h"

//Paths and Filenames
#define PREF_GROUP_PREFERRED_ACCOUNTS   @"Preferred Accounts"
#define ACCOUNT_DEFAULT_PREFS			@"AccountPrefs"


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

//init
- (void)initController
{
	adiumServices = [[AdiumServices alloc] init];
	adiumPasswords = [[AdiumPasswords alloc] init];
	adiumAccounts = [[AdiumAccounts alloc] init];
	

	
    lastAccountIDToSendContent = [[NSMutableDictionary alloc] init];
	
	//Default account preferences
	[[adium preferenceController] registerDefaults:[NSDictionary dictionaryNamed:ACCOUNT_DEFAULT_PREFS forClass:[self class]]
										  forGroup:PREF_GROUP_ACCOUNTS];
	
}

//Finish initialization once other controllers have set themselves up
- (void)finishIniting
{   
	//Finish prepping the accounts
	[adiumAccounts finishIniting];
	
	//Temporary upgrade code
	[adiumPasswords upgradePasswords];


	
	
	
    //Observe content (for accountForSendingContentToContact)
    [[adium notificationCenter] addObserver:self
                                   selector:@selector(didSendContent:)
                                       name:CONTENT_MESSAGE_SENT
                                     object:nil];
	
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
    [lastAccountIDToSendContent release];
	
	[super dealloc];
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
#pragma mark Passwords
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

//Accounts
#pragma mark Accounts
- (NSArray *)accounts {
	return [adiumAccounts accounts];
}
- (NSArray *)accountsCompatibleWithService:(AIService *)service {
	return [adiumAccounts accountsCompatibleWithService:service];
}
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID {
	return [adiumAccounts accountWithInternalObjectID:objectID];
}
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID {
	return [adiumAccounts createAccountWithService:service UID:inUID];
}
- (void)addAccount:(AIAccount *)inAccount {
	[adiumAccounts addAccount:inAccount];
}
- (void)deleteAccount:(AIAccount *)inAccount {
	[adiumAccounts deleteAccount:inAccount];
}
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex {
	return [adiumAccounts moveAccount:account toIndex:destIndex];
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
		enumerator = [[self accounts] objectEnumerator];
		while((account = [enumerator nextObject])){
			if([inContact service] == [account service] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
		
		//First available account in our list of a compatible service type
		enumerator = [[self accounts] objectEnumerator];
		while((account = [enumerator nextObject])){
			if([[inContact serviceClass] isEqualToString:[account serviceClass]] &&
			   ([account availableForSendingContentType:inType toContact:nil] || includeOffline)){
				return(account);
			}
		}
	}else{
		//First available account in our list
		enumerator = [[self accounts] objectEnumerator];
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
    enumerator = [[self accounts] objectEnumerator];
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
	NSEnumerator	*enumerator = [[[adium accountController] accounts] objectEnumerator];
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
    
    enumerator = [[self accounts] objectEnumerator];
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

    enumerator = [[self accounts] objectEnumerator];
    while((account = [enumerator nextObject])){
        if([[account supportedPropertyKeys] containsObject:@"Online"] &&
		   [[account preferenceForKey:@"Online" group:GROUP_ACCOUNT_STATUS] boolValue]){
            [account setPreference:nil forKey:@"Online" group:GROUP_ACCOUNT_STATUS];
        }
    }
}

- (BOOL)anOnlineAccountCanCreateGroupChats
{
	NSEnumerator	*enumerator = [[self accounts] objectEnumerator];
	AIAccount		*account;
	
    while((account = [enumerator nextObject])){	
		if([account online] && [[account service] canCreateGroupChats]) return(YES);
	}
	
	return(NO);
}

- (BOOL)anOnlineAccountCanEditContacts
{
	NSEnumerator	*enumerator = [[self accounts] objectEnumerator];
	AIAccount		*account;
	
    while((account = [enumerator nextObject])){	
		if([account contactListEditable]) return(YES);
	}
	
	return(NO);
}

- (BOOL)oneOrMoreConnectedAccounts
{
	NSEnumerator		*enumerator;
    AIAccount			*account;

    enumerator = [[self accounts] objectEnumerator];
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
	
    enumerator = [[self accounts] objectEnumerator];
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

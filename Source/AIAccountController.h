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

/**
 * $Revision: 1.32 $
 * $Date$
 * $Author$
 **/

#define Account_ListChanged 					@"Account_ListChanged"
#define Adium_RequestSetManualIdleTime			@"Adium_RequestSetManualIdleTime"

//Connecting is faded by 40%
#define CONNECTING_MENU_IMAGE_FRACTION  0.60

//Offline is faded by 70%
#define OFFLINE_MENU_IMAGE_FRACTION		0.30

@protocol AIListObjectObserver;

@class AIAdium, AIAccount, AIListObject, AIAccountViewController, DCJoinChatViewController;

@protocol AccountMenuPlugin <NSObject>
- (NSString *)identifier;
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;
@end

@interface AIAccountController : NSObject<AIListObjectObserver>{
    IBOutlet	AIAdium		*owner;	
	
    NSMutableArray			*accountArray;				//Array of active accounts
    NSMutableDictionary		*availableServiceDict;		//Dictionary of available services
	NSMutableDictionary		*availableServiceTypeDict;  //Dictionary of one of each available service types by serviceID
    NSMutableDictionary		*lastAccountIDToSendContent;//Last account to send content
    NSMutableDictionary		*accountStatusDict;			//Account status
	
	NSMutableArray			*unloadableAccounts;
	
	NSMutableArray			*accountMenuPluginsArray;
	NSMutableDictionary		*accountMenuItemArraysDict;
	
	NSArray					*_cachedActiveServices;
}

//Services
- (NSArray *)availableServices;
- (NSArray *)activeServices;
- (AIService *)serviceWithUniqueID:(NSString *)identifier;
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID;
- (NSArray *)servicesWithServiceClass:(NSString *)serviceClass;
- (void)registerService:(AIService *)inService;
- (NSMenu *)menuOfServicesWithTarget:(id)target;

//Accounts
- (NSArray *)accountArray;
- (AIAccount *)accountWithAccountNumber:(int)accountNumber;
- (NSArray *)accountsWithService:(AIService *)service;
- (AIAccount *)defaultAccount;
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID accountNumber:(int)inAccountNumber;
- (NSArray *)accountsWithServiceClassOfService:(AIService *)service;
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType
								   toListObject:(AIListObject *)inObject
									 withTarget:(id)target
								 includeOffline:(BOOL)includeOffline;
//Account Editing
- (AIAccount *)newAccountAtIndex:(int)index;
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index save:(BOOL)shouldSave;
- (void)deleteAccount:(AIAccount *)inAccount save:(BOOL)shouldSave;
- (AIAccount *)switchAccount:(AIAccount *)inAccount toService:(id <AIServiceController>)inService;
- (AIAccount *)changeUIDOfAccount:(AIAccount *)inAccount to:(NSString *)inUID;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;

//AccountMenuPlugin
- (void)registerAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;
- (void)unregisterAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;

//Preferred Source Accounts 
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline onlyIfCreatingGroupChatIsSupported:(BOOL)groupChatCreator;
- (NSArray *)menuItemsForAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject withTarget:(id)target includeOffline:(BOOL)includeOffline;

//Connection convenience methods
- (void)connectAllAccounts;
- (void)disconnectAllAccounts;
- (BOOL)oneOrMoreConnectedAccounts;

//Password Storage
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;

- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName;
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName;
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector;

//Private
- (void)initController;
- (void)closeController;
- (void)finishIniting;

@end

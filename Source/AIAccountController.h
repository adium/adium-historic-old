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

/**
 * $Revision: 1.32 $
 * $Date$
 * $Author$
 **/

#define Account_ListChanged 					@"Account_ListChanged"
#define Adium_RequestSetManualIdleTime			@"Adium_RequestSetManualIdleTime"

#define ACCOUNTS_TITLE AILocalizedString(@"Accounts",nil)

//Connecting is faded by 40%
#define CONNECTING_MENU_IMAGE_FRACTION  0.60

//Offline is faded by 70%
#define OFFLINE_MENU_IMAGE_FRACTION		0.30

//Proxy
#define KEY_ACCOUNT_PROXY_ENABLED		@"Proxy Enabled"
#define KEY_ACCOUNT_PROXY_TYPE			@"Proxy Type"
#define KEY_ACCOUNT_PROXY_HOST			@"Proxy Host"
#define KEY_ACCOUNT_PROXY_PORT			@"Proxy Port"
#define KEY_ACCOUNT_PROXY_USERNAME		@"Proxy Username"
#define KEY_ACCOUNT_PROXY_PASSWORD		@"Proxy Password"

//Proxy types
typedef enum
{
	Adium_Proxy_HTTP,
	Adium_Proxy_SOCKS4,
	Adium_Proxy_SOCKS5,
	Adium_Proxy_Default_HTTP,
	Adium_Proxy_Default_SOCKS4,
	Adium_Proxy_Default_SOCKS5
} AdiumProxyType;

@protocol AIListObjectObserver, StateMenuPlugin;

@class AIAdium, AIAccount, AIListObject, AIAccountViewController, AIService, AIListContact, 
		AdiumServices, AdiumPasswords;

@protocol AccountMenuPlugin <NSObject>
- (void)addAccountMenuItems:(NSArray *)menuItemArray;
- (void)removeAccountMenuItems:(NSArray *)menuItemArray;
- (BOOL)showStatusSubmenu;
@end

@interface AIAccountController : NSObject<AIListObjectObserver, StateMenuPlugin>{
    IBOutlet	AIAdium		*adium;	
	
    NSMutableArray			*accountArray;				//Array of active accounts
    NSMutableDictionary		*lastAccountIDToSendContent;//Last account to send content
    NSMutableDictionary		*accountStatusDict;			//Account status
	
	NSMutableArray			*unloadableAccounts;
	
	NSMutableDictionary		*accountMenuPluginsDict;
	NSMutableDictionary		*accountMenuItemArraysDict;
	
	NSArray					*_cachedActiveServices;

	AdiumServices			*adiumServices;
	AdiumPasswords			*adiumPasswords;
}

//Services
- (void)registerService:(AIService *)inService;
- (NSArray *)services;
- (NSArray *)activeServices;
- (AIService *)serviceWithUniqueID:(NSString *)uniqueID;
- (AIService *)firstServiceWithServiceID:(NSString *)serviceID;

//Passwords
- (void)setPassword:(NSString *)inPassword forAccount:(AIAccount *)inAccount;
- (void)forgetPasswordForAccount:(AIAccount *)inAccount;
- (NSString *)passwordForAccount:(AIAccount *)inAccount;
- (void)passwordForAccount:(AIAccount *)inAccount notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;
- (void)setPassword:(NSString *)inPassword forProxyServer:(NSString *)server userName:(NSString *)userName;
- (NSString *)passwordForProxyServer:(NSString *)server userName:(NSString *)userName;
- (void)passwordForProxyServer:(NSString *)server userName:(NSString *)userName notifyingTarget:(id)inTarget selector:(SEL)inSelector context:(id)inContext;

					
			


//Accounts
- (NSArray *)accountArray;
- (void)saveAccounts;
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID;
- (NSArray *)accountsWithService:(AIService *)service;
- (NSArray *)accountsWithServiceClass:(NSString *)serviceClass;
- (AIAccount *)firstAccountWithService:(AIService *)service;
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID internalObjectID:(NSString *)internalObjectID;
- (NSArray *)accountsWithServiceClassOfService:(AIService *)service;
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType
								   toListObject:(AIListObject *)inObject
									 withTarget:(id)target
								 includeOffline:(BOOL)includeOffline;
- (BOOL)anOnlineAccountCanCreateGroupChats;
- (BOOL)anOnlineAccountCanEditContacts;

//Account Editing
- (AIAccount *)newAccountAtIndex:(int)index forService:(AIService *)service;
- (void)insertAccount:(AIAccount *)inAccount atIndex:(int)index save:(BOOL)shouldSave;
- (void)deleteAccount:(AIAccount *)inAccount save:(BOOL)shouldSave;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;

//AccountMenuPlugin
- (void)registerAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;
- (void)unregisterAccountMenuPlugin:(id<AccountMenuPlugin>)accountMenuPlugin;

//Preferred Source Accounts 
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline;
- (AIAccount *)firstAccountAvailableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline onlyIfCreatingGroupChatIsSupported:(BOOL)groupChatCreator;
- (NSArray *)menuItemsForAccountsWithTarget:(id)target includeOffline:(BOOL)includeOffline;
- (NSMenu *)menuOfAccountsForSendingContentType:(NSString *)inType toListObject:(AIListObject *)inObject withTarget:(id)target includeOffline:(BOOL)includeOffline;

//Connection convenience methods
- (void)connectAllAccounts;
- (void)disconnectAllAccounts;
- (BOOL)oneOrMoreConnectedAccounts;
- (BOOL)oneOrMoreConnectedOrConnectingAccounts;

//Private
- (void)initController;
- (void)closeController;
- (void)finishIniting;

@end

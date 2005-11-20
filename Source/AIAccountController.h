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

#import <Adium/AIObject.h>

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

@protocol AIController, AIListObjectObserver, StateMenuPlugin;

@class AIAdium, AIAccount, AIListObject, AIAccountViewController, AIService, AIListContact, 
		AdiumServices, AdiumPasswords, AdiumAccounts, AdiumPreferredAccounts;

@interface AIAccountController : AIObject <AIController> {
	AdiumServices			*adiumServices;
	AdiumPasswords			*adiumPasswords;
	AdiumAccounts			*adiumAccounts;
	AdiumPreferredAccounts	*adiumPreferredAccounts;
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
- (NSArray *)accounts;
- (NSArray *)accountsCompatibleWithService:(AIService *)service;
- (AIAccount *)accountWithInternalObjectID:(NSString *)objectID;
- (AIAccount *)createAccountWithService:(AIService *)service UID:(NSString *)inUID;
- (void)addAccount:(AIAccount *)inAccount;
- (void)deleteAccount:(AIAccount *)inAccount;
- (int)moveAccount:(AIAccount *)account toIndex:(int)destIndex;
- (void)accountDidChangeUID:(AIAccount *)inAccount;

//Preferred Accounts
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact;
- (AIAccount *)preferredAccountForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline;
- (AIAccount *)firstAccountAvailableForSendingContentType:(NSString *)inType toContact:(AIListContact *)inContact includeOffline:(BOOL)includeOffline;

//Connection convenience methods
- (void)disconnectAllAccounts;
- (BOOL)oneOrMoreConnectedAccounts;
- (BOOL)oneOrMoreConnectedOrConnectingAccounts;

@end
